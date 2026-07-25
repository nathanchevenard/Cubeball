extends CameraState
class_name ThirdPersonCameraState

@export var behind_camera_state : CameraState
@export var focus_camera_state : CameraState
@export var free_camera_state : CameraState

@export var mouse_sensitivity: float = 0.05
@export var min_pitch: float = -89.9
@export var max_pitch: float = 50
@export var min_yaw: float = 0
@export var max_yaw: float = 360


func _init() -> void:
	SignalsManager.control.cuboid_control_mode_human_set.connect(_on_cuboid_control_mode_human_set)


func apply_input(event : InputEvent):
	super(event)
	
	set_third_person_camera_rotation(event)
	
	if Input.is_action_just_pressed("toggle_camera_mode_free"):
		camera_manager.set_camera_state(free_camera_state)
	
	if Input.is_action_just_pressed("trigger_camera_mode_focus"):
		camera_manager.set_camera_state(focus_camera_state)
	
	if Input.is_action_just_released("trigger_camera_mode_third_person"):
		camera_manager.set_camera_state(behind_camera_state)


func enter_state(old_camera_state : CameraState):
	super(old_camera_state)
	
	if old_camera_state is FocusCameraState || old_camera_state is BehindCameraState:
		var camera_rotation = old_camera_state.phantom_camera.global_rotation
		phantom_camera.set_third_person_rotation(camera_rotation)


func exit_state():
	super()


func process(delta : float):
	super(delta)


func set_third_person_camera_rotation(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		camera_rotation_degrees = phantom_camera.get_third_person_rotation_degrees()

		# Change the X rotation
		camera_rotation_degrees.x -= event.relative.y * mouse_sensitivity

		# Clamp the rotation in the X axis so it go over or under the target
		camera_rotation_degrees.x = clampf(camera_rotation_degrees.x, min_pitch, max_pitch)

		# Change the Y rotation value
		camera_rotation_degrees.y -= event.relative.x * mouse_sensitivity

		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		camera_rotation_degrees.y = wrapf(camera_rotation_degrees.y, min_yaw, max_yaw)

		# Change the SpringArm3D node's rotation and rotate around its target
		phantom_camera.set_third_person_rotation_degrees(camera_rotation_degrees)


func _on_cuboid_control_mode_human_set(cuboid : Cuboid):
	phantom_camera.follow_target = cuboid
