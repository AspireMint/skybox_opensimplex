extends Spatial

export var _mouse_sensitivity: float = 0.5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		switch_mode()
	
	if can_move():
		aim(event)


func switch_mode() -> void:
	var current_mouse_mode = Input.get_mouse_mode()
	var mode: int
	
	if current_mouse_mode == Input.MOUSE_MODE_VISIBLE:
		mode = Input.MOUSE_MODE_CAPTURED
	elif current_mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mode = Input.MOUSE_MODE_VISIBLE
	
	Input.set_mouse_mode(mode)


func can_move() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED


func aim(event) -> void:
	var mouse_motion = event as InputEventMouseMotion
	if mouse_motion:
		$Camera.rotation_degrees.y -= mouse_motion.relative.x * _mouse_sensitivity
		var current_tilt = $Camera.rotation_degrees.x
		current_tilt -= mouse_motion.relative.y * _mouse_sensitivity
		$Camera.rotation_degrees.x = clamp(current_tilt, -90, 90)
