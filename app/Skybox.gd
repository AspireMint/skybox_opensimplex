extends Spatial

onready var Noise = get_node("/root/Noise")
var minmax_value: Vector2

export var skip_generating: bool = false
export var live_preview: bool = true

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

func _ready():
	if not skip_generating:
		_preflight()
		_create_skybox()
		_print_mt_table()
	
	if not live_preview:
		get_tree().quit()
		
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
	top()
	bottom()
	west()
	east()
	north()
	south()

################################################################################

func top() -> void:
	var img = _create_image()
	img.lock()
	for x in range(size):
		for z in range(size):
			var value = _get_value(x, size, z)
			var color = _get_color(value)
			img.set_pixel(x, z, color)
	img.unlock()
	_save_img(img, textures[0])


func bottom() -> void:
	var img = _create_image()
	img.lock()
	for x in range(size):
		for z in range(size):
			var value = _get_value(x, 0, z)
			var color = _get_color(value)
			img.set_pixel(x, size-z-1, color)
	img.unlock()
	_save_img(img, textures[1])


func west() -> void:
	var img = _create_image()
	img.lock()
	for x in range(size):
		for y in range(size):
			var value = _get_value(x, y, size)
			var color = _get_color(value)
			img.set_pixel(x, size-y-1, color)
	img.unlock()
	_save_img(img, textures[2])


func east() -> void:
	var img = _create_image()
	img.lock()
	for x in range(size):
		for y in range(size):
			var value = _get_value(x, y, 0)
			var color = _get_color(value)
			img.set_pixel(size-x-1, size-y-1, color)
	img.unlock()
	_save_img(img, textures[3])


func north() -> void:
	var img = _create_image()
	img.lock()
	for y in range(size):
		for z in range(size):
			var value = _get_value(size, y, z)
			var color = _get_color(value)
			img.set_pixel(size-z-1, size-y-1, color)
	img.unlock()
	_save_img(img, textures[4])


func south() -> void:
	var img = _create_image()
	img.lock()
	for y in range(size):
		for z in range(size):
			var value = _get_value(0, y, z)
			var color = _get_color(value)
			img.set_pixel(z, size-y-1, color)
	img.unlock()
	_save_img(img, textures[5])

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
