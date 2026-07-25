extends CameraState
class_name BehindCameraState

@export var focus_camera_state : CameraState
@export var third_person_camera_state : CameraState
@export var free_camera_state : CameraState


func _init() -> void:
	SignalsManager.control.cuboid_control_mode_human_set.connect(_on_cuboid_control_mode_human_set)


func apply_input(event : InputEvent):
	if Input.is_action_just_pressed("toggle_camera_mode_free"):
		camera_manager.set_camera_state(free_camera_state)
	
	if Input.is_action_just_pressed("trigger_camera_mode_focus"):
		camera_manager.set_camera_state(focus_camera_state)
		
	if Input.is_action_just_pressed("trigger_camera_mode_third_person"):
		camera_manager.set_camera_state(third_person_camera_state)


func enter_state(old_camera_state : CameraState):
	super(old_camera_state)


func exit_state():
	super()


func _on_cuboid_control_mode_human_set(cuboid : Cuboid):
	phantom_camera = cuboid.behind_phantom_camera
