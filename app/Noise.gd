extends Node

var noise := OpenSimplexNoise.new()
var minmax := Vector2(-1, 1)

func set_params(_seed: int, _octaves: int, _period: float) -> void:
	noise.seed = 42
	noise.octaves = _octaves
	noise.period = _period

func get_noise_3d(x: float, y: float, z: float) -> float:
	return noise.get_noise_3d(x, y, z)

func preflight_3d(params: PreflightParams) -> void:
	var origin = params.origin
	var dimension = params.dimension
	var precision = params.precision
	
	if precision < 1:
		var arr = [dimension.x, dimension.y, dimension.z]
		arr.sort()
		if arr[2] < 10:
			precision = 1
		else:
			precision = ceil(arr[1]/10)
	
	minmax = Vector2(1.0, -1.0)
	for x in range(dimension.x / precision):
		for y in range(dimension.y / precision):
			for z in range(dimension.y / precision):
				var shift_x = (x*precision)+origin.x
				var shift_y = (y*precision)+origin.y
				var shift_z = (z*precision)+origin.z
				var value = noise.get_noise_3d(shift_x, shift_y, shift_z)
				if value < minmax.x:
					minmax.x = value
				if value > minmax.y:
					minmax.y = value
	assert(minmax.x < minmax.y)

func round_preflight() -> void:
	minmax.x = floor(minmax.x*10)/10
	minmax.y = ceil(minmax.y*10)/10

################################################################################

class PreflightParams extends Object:
	var dimension: Vector3
	var origin: Vector3
	var precision: int
	
	func _init(_dimension: Vector3, _origin: Vector3 = Vector3(0,0,0), _precision: int = 0):
		dimension = _dimension
		origin = _origin
		precision = _precision
