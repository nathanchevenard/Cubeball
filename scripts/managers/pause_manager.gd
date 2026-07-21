extends Node
class_name PauseManager

var is_paused : bool = false


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause_game"):
		if is_paused == false:
			is_paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			is_paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
