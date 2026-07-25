extends CameraState
class_name FreeCameraState

@export var behind_camera_state : CameraState


func apply_input(event : InputEvent):
	super(event)
	
	if Input.is_action_just_pressed("toggle_camera_mode_free"):
		camera_manager.set_camera_state(behind_camera_state)


func enter_state(old_camera_state : CameraState):
	super(old_camera_state)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func exit_state():
	super()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
