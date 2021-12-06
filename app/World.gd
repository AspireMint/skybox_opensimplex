extends Spatial

func _ready():
	_pause(false)

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel"):
		_switch_mode()

func _switch_mode() -> void:
	_pause(Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED)

func _pause(paused: bool) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)
	$HUD.set_visible(paused)
	$Camera.show_axes(paused)

func can_move() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
