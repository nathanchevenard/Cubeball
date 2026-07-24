extends Node
class_name CameraManager

enum CameraMode {
	BEHIND,
	FOCUS,
	THIRD_PERSON,
	FREE,
}

@export_group("Focus Camera")
@export var focus_phantom_camera : PhantomCamera3D
@export var focus_offset : Vector3

@export_group("Third Person Camera")
@export var third_person_phantom_camera : PhantomCamera3D
@export var mouse_sensitivity: float = 0.05
@export var min_pitch: float = -89.9
@export var max_pitch: float = 50
@export var min_yaw: float = 0
@export var max_yaw: float = 360

@export_group("Free Camera")
@export var free_phantom_camera : PhantomCamera3D

static var instance : CameraManager

var current_camera : PhantomCamera3D
var followed_cuboid : Cuboid
var camera_mode : CameraMode


func _init() -> void:
	instance = self
	SignalsManager.control.cuboid_control_mode_human_set.connect(_on_cuboid_control_mode_human_set)


func _ready() -> void:
	set_camera_mode(CameraMode.FREE)


func _process(delta: float) -> void:
	if followed_cuboid != null && focus_phantom_camera.look_at_target != null:
		var direction : Vector3 = (followed_cuboid.global_position - focus_phantom_camera.look_at_target.global_position).normalized()
		direction.y = 1
		focus_phantom_camera.global_position = followed_cuboid.global_position + direction * focus_offset


func _unhandled_input(event: InputEvent) -> void:
	if camera_mode == CameraMode.THIRD_PERSON:
		set_third_person_camera_rotation(event)
	
	if camera_mode != CameraMode.FREE:
		if Input.is_action_just_pressed("trigger_camera_mode_focus"):
			set_camera_mode(CameraMode.FOCUS)
		elif Input.is_action_just_released("trigger_camera_mode_focus"):
			if Input.is_action_pressed("trigger_camera_mode_third_person"):
				set_camera_mode(CameraMode.THIRD_PERSON)
			else:
				set_camera_mode(CameraMode.BEHIND)
		if Input.is_action_just_pressed("trigger_camera_mode_third_person") && followed_cuboid != null:
			if camera_mode == CameraMode.BEHIND:
				var camera_rotation = followed_cuboid.behind_phantom_camera.global_rotation
				third_person_phantom_camera.set_third_person_rotation(camera_rotation)
			elif camera_mode == CameraMode.FOCUS:
				var camera_rotation = focus_phantom_camera.rotation
				third_person_phantom_camera.set_third_person_rotation(camera_rotation)
			set_camera_mode(CameraMode.THIRD_PERSON)
		elif Input.is_action_just_released("trigger_camera_mode_third_person"):
			if Input.is_action_pressed("trigger_camera_mode_focus"):
				set_camera_mode(CameraMode.FOCUS)
			else:
				set_camera_mode(CameraMode.BEHIND)
	
	if Input.is_action_just_pressed("toggle_camera_mode_free"):
		if camera_mode != CameraMode.FREE:
			set_camera_mode(CameraMode.FREE)
		else:
			set_camera_mode(CameraMode.BEHIND)


func set_camera_mode(new_camera_mode : CameraMode):
	if camera_mode == CameraMode.FREE:
		set_cuboid_camera(followed_cuboid)
	
	camera_mode = new_camera_mode
	
	match camera_mode:
		CameraMode.BEHIND:
			enable_camera(followed_cuboid.behind_phantom_camera)
		CameraMode.FOCUS:
			enable_camera(focus_phantom_camera)
		CameraMode.THIRD_PERSON:
			enable_camera(third_person_phantom_camera)
		CameraMode.FREE:
			enable_camera(free_phantom_camera)


func enable_camera(camera : PhantomCamera3D):
	if current_camera != null:
		current_camera.priority = 0
	
	camera.priority = 1
	current_camera = camera


func set_third_person_camera_rotation(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var camera_rotation_degrees: Vector3

		# Assigns the current 3D rotation of the SpringArm3D node - so it starts off where it is in the editor
		camera_rotation_degrees = third_person_phantom_camera.get_third_person_rotation_degrees()

		# Change the X rotation
		camera_rotation_degrees.x -= event.relative.y * mouse_sensitivity

		# Clamp the rotation in the X axis so it go over or under the target
		camera_rotation_degrees.x = clampf(camera_rotation_degrees.x, min_pitch, max_pitch)

		# Change the Y rotation value
		camera_rotation_degrees.y -= event.relative.x * mouse_sensitivity

		# Sets the rotation to fully loop around its target, but witout going below or exceeding 0 and 360 degrees respectively
		camera_rotation_degrees.y = wrapf(camera_rotation_degrees.y, min_yaw, max_yaw)

		# Change the SpringArm3D node's rotation and rotate around its target
		third_person_phantom_camera.set_third_person_rotation_degrees(camera_rotation_degrees)


func set_cuboid_camera(cuboid : Cuboid):
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	third_person_phantom_camera.follow_target = cuboid
	focus_phantom_camera.follow_target = cuboid
	focus_phantom_camera.look_at_target = EntityManager.instance.ball_list[0]
	followed_cuboid = cuboid


func _on_cuboid_control_mode_human_set(cuboid : Cuboid):
	followed_cuboid = cuboid
