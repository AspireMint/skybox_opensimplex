extends Node

export var _seed: int = 42
export var _octaves = 10
export var _period = 200

var noise: OpenSimplexNoise

func _ready():
	noise = OpenSimplexNoise.new()
	noise.seed = _seed
	noise.octaves = _octaves
	noise.period = _period

func get_noise_3d(x: float, y: float, z: float) -> float:
	return noise.get_noise_3d(x, y, z)

class PreflightParams extends Object:
	var dimension: Vector3
	var origin: Vector3
	var precision: int
	
	func _init(dimension: Vector3, origin: Vector3 = Vector3(0,0,0), precision: int = 0):
		self.dimension = dimension
		self.origin = origin
		self.precision = precision

func preflight_3d(params: PreflightParams) -> Vector2:
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
	
	var minmax = Vector2(1.0, -1.0)
	for x in range(dimension.x / precision):
		for y in range(dimension.y / precision):
			for z in range(dimension.y / precision):
				var value = noise.get_noise_3d(x*precision, y*precision, z*precision)
				if value < minmax.x:
					minmax.x = value
				if value > minmax.y:
					minmax.y = value
	assert(minmax.x < minmax.y)
	return minmax

func round_preflight(minmax: Vector2) -> Vector2:
	minmax.x = floor(minmax.x*10)/10
	minmax.y = ceil(minmax.y*10)/10
	return minmax
