extends Node
class_name CameraManager

enum CameraMode {
	BEHIND,
	FOCUS,
	FREE,
}

@export var free_phantom_camera : PhantomCamera3D
@export var focus_phantom_camera : PhantomCamera3D
@export var focus_offset : Vector3

@export_group("Free Camera")
@export var mouse_sensitivity: float = 0.05
@export var min_pitch: float = -89.9
@export var max_pitch: float = 50
@export var min_yaw: float = 0
@export var max_yaw: float = 360

static var instance : CameraManager

var current_camera : PhantomCamera3D
var player_cuboid : Cuboid
var camera_mode : CameraMode


func _init() -> void:
	instance = self


func _ready() -> void:
	set_camera_mode(CameraMode.BEHIND)


func _process(delta: float) -> void:
	var direction : Vector3 = (player_cuboid.global_position - focus_phantom_camera.look_at_target.global_position).normalized()
	direction.y = 1
	focus_phantom_camera.global_position = player_cuboid.global_position + direction * focus_offset


func _unhandled_input(event: InputEvent) -> void:
	if player_cuboid != null && player_cuboid.input_mode == Cuboid.InputMode.HUMAN\
	&& DebugManager.instance.camera_on_cuboid == true:
		if free_phantom_camera.follow_mode == PhantomCamera3D.FollowMode.THIRD_PERSON:
			set_free_camera_rotation(event)
	
	if Input.is_action_just_pressed("trigger_camera_mode_focus"):
		set_camera_mode(CameraMode.FOCUS)
	elif Input.is_action_just_released("trigger_camera_mode_focus"):
		if Input.is_action_pressed("trigger_camera_mode_free"):
			set_camera_mode(CameraMode.FREE)
		else:
			set_camera_mode(CameraMode.BEHIND)
	if Input.is_action_just_pressed("trigger_camera_mode_free") && player_cuboid != null:
		if camera_mode == CameraMode.BEHIND:
			var camera_rotation = player_cuboid.behind_phantom_camera.global_rotation
			free_phantom_camera.set_third_person_rotation(camera_rotation)
		elif camera_mode == CameraMode.FOCUS:
			var camera_rotation = focus_phantom_camera.rotation
			free_phantom_camera.set_third_person_rotation(camera_rotation)
		set_camera_mode(CameraMode.FREE)
	elif Input.is_action_just_released("trigger_camera_mode_free"):
		if Input.is_action_pressed("trigger_camera_mode_focus"):
			set_camera_mode(CameraMode.FOCUS)
		else:
			set_camera_mode(CameraMode.BEHIND)


func set_camera_mode(new_camera_mode : CameraMode):
	camera_mode = new_camera_mode
	
	match camera_mode:
		CameraMode.BEHIND:
			enable_camera(player_cuboid.behind_phantom_camera)
		CameraMode.FOCUS:
			enable_camera(focus_phantom_camera)
		CameraMode.FREE:
			enable_camera(free_phantom_camera)


func enable_camera(camera : PhantomCamera3D):
	if current_camera != null:
		current_camera.priority = 0
	
	camera.priority = 1
	current_camera = camera


func set_free_camera_rotation(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		camera_rotation_degrees = free_phantom_camera.get_third_person_rotation_degrees()

		# Change the X rotation
		camera_rotation_degrees.x -= event.relative.y * mouse_sensitivity

		# Clamp the rotation in the X axis so it go over or under the target
		camera_rotation_degrees.x = clampf(camera_rotation_degrees.x, min_pitch, max_pitch)

		# Change the Y rotation value
		camera_rotation_degrees.y -= event.relative.x * mouse_sensitivity

		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		camera_rotation_degrees.y = wrapf(camera_rotation_degrees.y, min_yaw, max_yaw)

		# Change the SpringArm3D node's rotation and rotate around its target
		free_phantom_camera.set_third_person_rotation_degrees(camera_rotation_degrees)
