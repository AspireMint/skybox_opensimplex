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
