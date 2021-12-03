extends Spatial

onready var Noise = get_node("/root/Noise")
var minmax_value: Vector2

enum Mode {
	VIEW_SKYBOX,
	GENERATE_SKYBOX,
}

export(Mode) var mode = Mode.VIEW_SKYBOX

#texture width and height in pixels
export var size: int = 500
# warning-ignore:integer_division
onready var halfsize: int = size/2
onready var sphere_radius: int = size

enum Projection {
	CUBE,
	SPHERE
}
export(Projection) var projection = Projection.SPHERE

export var textures_directory: String = "textures"
# Minetest: order: Y+ (top), Y- (bottom), X- (west), X+ (east), Z+ (north), Z- (south)
export(Array, String) var textures : Array = [
	"top.png",
	"bottom.png",
	"west.png",
	"east.png",
	"north.png",
	"south.png"
]

enum FixedSide {
	X,
	Y,
	Z
}

var tiles = [
	[FixedSide.Y, size, false, false, false],
	[FixedSide.Y, 0, false, true, false],
	[FixedSide.Z, size, false, true, false],
	[FixedSide.Z, 0, true, true, false],
	[FixedSide.X, size, true, true, true],
	[FixedSide.X, 0, true, false, true]
]

func _ready():
	if mode == Mode.GENERATE_SKYBOX:
		_preflight()
		_create_skybox()
		_print_mt_table()
		get_tree().quit()
	else:
		_scale_sprites()

func _preflight():
	var params: Noise.PreflightParams
	if projection == Projection.SPHERE:
		var dimension = Vector3(2*sphere_radius, 2*sphere_radius, 2*sphere_radius)
		var origin = Vector3(-sphere_radius, -sphere_radius, -sphere_radius)
		params = Noise.PreflightParams.new(dimension, origin)
	elif projection == Projection.CUBE:
		var dimension = Vector3(size, size, size)
		params = Noise.PreflightParams.new(dimension)
	minmax_value = Noise.round_preflight(Noise.preflight_3d(params))

func _create_skybox() -> void:
	for i in range(tiles.size()):
		tile(tiles[i][0], tiles[i][1], tiles[i][2], tiles[i][3], tiles[i][4], i)

################################################################################


func tile(fixed_side: int, level: int, flip_i: bool, flip_j: bool, rotate: bool, texture_index: int) -> void:
	var get_value: FuncRef = _get_value_fn(fixed_side)
	var img = _create_image()
	img.lock()
	for i in range(size):
		for j in range(size):
			var value = get_value.call_func(level, i, j)
			var color = _get_color(value)
			if flip_i:
				i = size-i-1
			if flip_j:
				j = size-j-1
			if rotate:
				img.set_pixel(j, i, color)
			else:
				img.set_pixel(i, j, color)
	img.unlock()
	_save_img(img, textures[texture_index])

func _get_value_fn(fixed_side: int) -> FuncRef:
	if fixed_side == FixedSide.X:
		return funcref(self, "_get_value_fixed_x")
	if fixed_side == FixedSide.Y:
		return funcref(self, "_get_value_fixed_y")
	return funcref(self, "_get_value_fixed_z")

func _get_value_fixed_x(x: int, y: int, z: int) -> float:
	return _get_value(x, y, z)

func _get_value_fixed_y(y: int, x: int, z: int) -> float:
	return _get_value(x, y, z)

func _get_value_fixed_z(z: int, x: int, y: int) -> float:
	return _get_value(x, y, z)


################################################################################

func _create_image() -> Image:
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGB8)
	return img

################################################################################

func _get_value(x: int, y: int, z: int) -> float:
	if projection == Projection.SPHERE:
		return _get_value_from_sphere(x, y, z)
	elif projection == Projection.CUBE:
		return _get_value_from_cube_but_looks_bad(x, y, z)
	assert(false)
	return 0.0

func _get_value_from_cube_but_looks_bad(x: int, y: int, z: int) -> float:
	var value = Noise.get_noise_3d(x, y, z)
	return _process_value(value)

func _get_value_from_sphere(x: int, y: int, z: int) -> float:
	var vector = Vector3(x-halfsize, y-halfsize, z-halfsize)
	vector = vector.normalized() * sphere_radius
	var value = Noise.get_noise_3d(vector.x, vector.y, vector.z)
	return _process_value(value)

func _process_value(value: float) -> float:
	return (value-0.5)*1.5 #whatever :D

################################################################################

func _get_color(value: float) -> Color:
	return _greyscale(value)
	#return _some_colors(value)

func _greyscale(value: float) -> Color:
	var rgb = range_lerp(value, -1, 1, 0, 1)
	return Color(rgb, rgb, rgb)

var colors = [
	[255, 0, 0],
	[0, 255, 0],
	[0, 0, 255],
	[255, 255, 0],
	[255, 0, 255],
	[0, 255, 255],
	[255, 255, 255],
]
func _some_colors(value: float) -> Color:
	var rgb = range_lerp(value, minmax_value.x, minmax_value.y, 0, 1)
# warning-ignore:narrowing_conversion
	var index: int = range_lerp(value, minmax_value.x, minmax_value.y, 0, colors.size())
	var r = range_lerp(colors[index][0] * rgb, 0, 255, 0, 1)
	var g = range_lerp(colors[index][1] * rgb, 0, 255, 0, 1)
	var b = range_lerp(colors[index][2] * rgb, 0, 255, 0, 1)
	return Color(r, g, b)

func _save_img(img: Image, file_name: String) -> void:
	var full_path = _get_texture_path(file_name)
	var error = img.save_png(full_path)
	if error:
		print("ERROR:", "Could not save "+full_path)

func _get_texture_path(file_name: String) -> String:
	return "res://" + textures_directory + "/" + file_name

func _scale_sprites() -> void:
# warning-ignore:integer_division
	var scale = (500 / size) * Vector3(2,2,2)
	$Top.scale = scale
	$Bottom.scale = scale
	$West.scale = scale
	$East.scale = scale
	$North.scale = scale
	$South.scale = scale

func _print_mt_table() -> void:
	var t = "local skybox = {"
	for i in range(textures.size()):
		t += '"'+textures[i]+'"'
		if i != textures.size()-1:
			t += ', '
	t += "}"
	print(t)
