extends CameraState
class_name FocusCameraState

@export var behind_camera_state : CameraState
@export var third_person_camera_state : CameraState
@export var free_camera_state : CameraState

@export var focus_offset : Vector3

var followed_cuboid : Cuboid
var closest_ball : Ball


func _init() -> void:
	SignalsManager.control.cuboid_control_mode_human_set.connect(_on_cuboid_control_mode_human_set)


func apply_input(event : InputEvent):
	super(event)
	
	if Input.is_action_just_pressed("toggle_camera_mode_free"):
		camera_manager.set_camera_state(free_camera_state)
	
	if Input.is_action_just_pressed("trigger_camera_mode_third_person"):
		camera_manager.set_camera_state(third_person_camera_state)
	
	if Input.is_action_just_released("trigger_camera_mode_focus"):
		camera_manager.set_camera_state(behind_camera_state)


func enter_state(old_camera_state : CameraState):
	super(old_camera_state)


func exit_state():
	super()


func _process(delta: float) -> void:
	if followed_cuboid == null:
		return
	get_closest_ball()
	update_camera_position()


func process(delta : float):
	super(delta)


func get_closest_ball():
	var minimum_distance : float = INF
	for ball in EntityManager.instance.ball_list:
		var distance : float = ball.global_position.distance_to(followed_cuboid.global_position)
		if distance < minimum_distance:
			closest_ball = ball
			minimum_distance = distance
	
	phantom_camera.look_at_target = closest_ball


func update_camera_position():
	if followed_cuboid == null || phantom_camera.look_at_target == null:
		return
	
	var direction : Vector3 = (followed_cuboid.global_position - phantom_camera.look_at_target.global_position).normalized()
	direction.y = 1
	phantom_camera.global_position = followed_cuboid.global_position + direction * focus_offset


func _on_cuboid_control_mode_human_set(cuboid : Cuboid):
	followed_cuboid = cuboid
