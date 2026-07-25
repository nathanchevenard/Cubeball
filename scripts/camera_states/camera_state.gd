extends Node
class_name CameraState

@export var camera_manager : CameraManager
@export var phantom_camera : PhantomCamera3D


func apply_input(event : InputEvent):
	pass


func enter_state(old_camera_state : CameraState):
	phantom_camera.priority = 1


func exit_state():
	phantom_camera.priority = 0


func process(delta : float):
	pass
