extends Spatial

enum Mode {
	GENERATE_SKYBOX,
	VIEW_SKYBOX
}

export(Mode) var mode = Mode.GENERATE_SKYBOX

enum Projection {
	CUBE,
	SPHERE
}
export(Projection) var projection = Projection.SPHERE

#texture width and height in pixels
export var size: int = 500
onready var halfsize: int = float(size)/2
onready var sphere_radius: int = size

export(bool) var random_seed = false
export var _seed: int = 42
export var _octaves: int = 3
export var _period: float = 400

export(bool) var use_preflight = false

enum ColorTheme {
	GREYSCALE,
	BLACKISH,
	ALPHA_CHANNEL,
	REDDISH,
	RAINBOW,
	SPACE_HEAT_MAP,
	SPACE
}
export(ColorTheme) var color_theme = ColorTheme.BLACKISH
onready var theme_fn: FuncRef = _get_theme_fn()

const textures_directory: String = "textures"
# Minetest: order: Y+ (top), Y- (bottom), X- (west), X+ (east), Z+ (north), Z- (south)
export(Array, String) var textures : Array = [
	"top.png",
	"bottom.png",
	"west.png",
	"east.png",
	"north.png",
	"south.png"
]

export(bool) var draw_grid = false
export(bool) var grid_to_image = false
const grid_filename = "grid.png"

enum GridStyle {
	LINES,
	DOTS
}
export(GridStyle) var grid_style = GridStyle.LINES

export(int) var grid_columns = 10
export(Color) var grid_color = Color.white

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
	randomize()
	
	if mode == Mode.GENERATE_SKYBOX:
		_update_noise_params()
		if use_preflight:
			_preflight()
		_create_skybox()
		if draw_grid and !grid_to_image:
			_create_grid_image()
		_print_mt_table()
		get_tree().quit()
	else:
		_scale_sprites()

func _update_noise_params() -> void:
	if random_seed:
		_seed = randi()
	Noise.set_params(_seed, _octaves, _period)

func _preflight():
	print("[started] Preflight. Please wait.")
	var params: Noise.PreflightParams
	if projection == Projection.SPHERE:
		var dimension = Vector3(2*sphere_radius, 2*sphere_radius, 2*sphere_radius)
		var origin = Vector3(-sphere_radius, -sphere_radius, -sphere_radius)
		params = Noise.PreflightParams.new(dimension, origin)
	elif projection == Projection.CUBE:
		var dimension = Vector3(size, size, size)
		params = Noise.PreflightParams.new(dimension)
	Noise.preflight_3d(params)
	Noise.round_preflight()
	print("[finished] Preflight")

func _get_theme_fn() -> FuncRef:
	var fn_name: String
	match color_theme:
		ColorTheme.GREYSCALE:
			fn_name = "_greyscale"
		ColorTheme.BLACKISH:
			fn_name = "_blackish"
		ColorTheme.ALPHA_CHANNEL:
			fn_name = "_alpha_channel"
		ColorTheme.RAINBOW:
			fn_name = "_rainbow_colors"
		ColorTheme.REDDISH:
			fn_name = "_reddish"
		ColorTheme.SPACE_HEAT_MAP:
			fn_name = "_heat_map"
		ColorTheme.SPACE:
			fn_name = "_space"
		_:
			fn_name = "_greyscale" #default
	return funcref(self, fn_name)

func _create_skybox() -> void:
	print("[started] Generating of skybox. Please wait.")
	for i in range(tiles.size()):
		print("  ", textures[i], " is being processed")
		tile(tiles[i][0], tiles[i][1], tiles[i][2], tiles[i][3], tiles[i][4], i)
	print("[finished] Generating of skybox")

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
	if draw_grid and grid_to_image:
		_draw_grid_to_image(img)
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

func _create_grid_image() -> void:
	print("[started] Grid generation. Please wait.")
	print("  ", grid_filename, " is being processed")
	var img = _create_image()
	img.fill(Color.transparent)
	img.lock()
	_draw_grid_to_image(img)
	img.unlock()
	_save_img(img, grid_filename)
	print("[finished] Grid generation.")

func _create_image() -> Image:
	var img = Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	return img

func _draw_grid_to_image(img: Image) -> void:
	var spacing = int(size/grid_columns)
	if spacing < 1:
		assert(false)
	
	if grid_style == GridStyle.LINES:
		for i in range(size):
			img.set_pixel(i, size-1, grid_color)
			var steps = 1 if i%spacing == 0 else spacing
			for j in range(0, size-1, steps):
				img.set_pixel(i, j, grid_color)
				img.set_pixel(size-1, j, grid_color)
	elif grid_style == GridStyle.DOTS:
		for i in range(0, size, spacing):
			img.set_pixel(i, size-1, grid_color)
			for j in range(0, size, spacing):
				img.set_pixel(i, j, grid_color)
				img.set_pixel(size-1, j, grid_color)

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
	value = clamp(value, Noise.minmax.x, Noise.minmax.y)
	value = range_lerp(value, Noise.minmax.x, Noise.minmax.y, -1, 1)
	return value

func _get_color(value: float) -> Color:
	return theme_fn.call_func(value)

################################################################################

func _greyscale(value: float) -> Color:
	return ColorUtil.from_value(range_lerp(value, -1, 1, 0, 1))

func _blackish(value: float) -> Color:
	var treshold = 0
	if value < treshold:
		value = 0
	else:
		value = range_lerp(value, treshold, 1, 0, 1)
	return ColorUtil.from_value(value)

func _alpha_channel(value: float) -> Color:
	var threshold = 0
	if value < threshold:
		value = 0
	else:
		value = range_lerp(value, threshold, 1, 0, 1)
	return ColorUtil.by_alpha(1-value)

func _reddish(value: float) -> Color:
	var color = ColorUtil.from_value(range_lerp(value, -1, 1, 0, 1))
	return ColorUtil.mask_color(color, Color.red)

func _rainbow_colors(value: float) -> Color:
	return ColorUtil.from_value(range_lerp(value, -1, 1, 0, 1), ColorSet.RAINBOW)

func _heat_map(value: float) -> Color:
	return ColorUtil.from_value(range_lerp(value, -1, 1, 0, 1), ColorSet.HEAT)

func _space(value: float) -> Color:
	var threshold = 0.3
	if value < threshold:
		value = 0
	else:
		value = range_lerp(value, threshold, 1, 0, 1)
	return ColorUtil.from_value(value, ColorSet.SPACE)

################################################################################

func _save_img(img: Image, file_name: String) -> void:
	var full_path = _get_texture_path(file_name)
	var error = img.save_png(full_path)
	if error:
		print("[ERROR] Could not save "+full_path)

func _get_texture_path(file_name: String) -> String:
	return "res://" + textures_directory + "/" + file_name

func _scale_sprites() -> void:
	var scale = (float(500) / size) * Vector3(2,2,2)
	$Top.scale = scale
	$Bottom.scale = scale
	$West.scale = scale
	$East.scale = scale
	$North.scale = scale
	$South.scale = scale

func _print_mt_table() -> void:
	var delimiter = "-"
	var d = ""
# warning-ignore:unused_variable
	for n in range(80):
		d += delimiter
	print(d)
	var t = "local skybox = {"
	for i in range(textures.size()):
		t += '"'+textures[i]+'"'
		if i != textures.size()-1:
			t += ', '
	t += "}"
	print(t)
