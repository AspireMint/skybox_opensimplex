extends Camera

export var _mouse_sensitivity: float = 0.5

func _input(event):
	if get_parent().can_move():
		_aim(event)
		_update_axes()

func _aim(event) -> void:
	var mouse_motion = event as InputEventMouseMotion
	if mouse_motion:
		rotation_degrees.y -= mouse_motion.relative.x * _mouse_sensitivity
		var current_tilt = rotation_degrees.x
		current_tilt -= mouse_motion.relative.y * _mouse_sensitivity
		rotation_degrees.x = clamp(current_tilt, -90, 90)

func _update_axes() -> void:
	var pos: Vector3 = $Axes.global_transform.origin
	$Axes.look_at_from_position(pos, pos+Vector3.FORWARD, Vector3.UP)

func show_axes(visible: bool) -> void:
	$Axes.visible = visible
