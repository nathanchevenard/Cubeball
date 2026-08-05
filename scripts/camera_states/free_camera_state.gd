extends CameraState
class_name FreeCameraState

@export var behind_camera_state : CameraState

@export var camera_move_speed : float = 0.05
@export var mouse_sensitivity: float = 0.05
@export var min_pitch: float = -89.9
@export var max_pitch: float = 50
@export var min_yaw: float = 0
@export var max_yaw: float = 360
@export var zoom_value : float = 0.5

var camera : Camera3D


func apply_input(event : InputEvent):
	super(event)
	
	if Input.is_action_just_pressed("toggle_camera_mode_free"):
		camera_manager.set_camera_state(behind_camera_state)


func enter_state(old_camera_state : CameraState):
	super(old_camera_state)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera = CameraManager.instance.camera


func exit_state():
	super()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func process(delta : float):
	super(delta)
	
	if Input.is_action_pressed("camera_mode_free_forward"):
		var direction : Vector3 = -camera.transform.basis.z
		direction.y = 0
		phantom_camera.global_position += direction.normalized() * camera_move_speed * delta
	if Input.is_action_pressed("camera_mode_free_back"):
		var direction : Vector3 = camera.transform.basis.z
		direction.y = 0
		phantom_camera.global_position += direction.normalized() * camera_move_speed * delta
	if Input.is_action_pressed("camera_mode_free_left"):
		phantom_camera.global_position += -camera.transform.basis.x * camera_move_speed * delta
	if Input.is_action_pressed("camera_mode_free_right"):
		phantom_camera.global_position += camera.transform.basis.x * camera_move_speed * delta
	if Input.is_action_pressed("camera_mode_free_up"):
		phantom_camera.global_position.y += camera_move_speed / 100.0
	if Input.is_action_pressed("camera_mode_free_down"):
		phantom_camera.global_position.y += -camera_move_speed / 100.0
	if Input.is_action_just_pressed("camera_mode_free_zoom_in"):
		phantom_camera.global_position += -camera.transform.basis.z * zoom_value * delta
	if Input.is_action_just_pressed("camera_mode_free_zoom_out"):
		phantom_camera.global_position += camera.transform.basis.z * zoom_value * delta


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("camera_mode_free_rotate"):
		rotate_camera(event)


func rotate_camera(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var phantom_camera_rotation_degrees: Vector3
		phantom_camera_rotation_degrees = phantom_camera.rotation_degrees
		
		phantom_camera_rotation_degrees.x -= event.relative.y * mouse_sensitivity
		phantom_camera_rotation_degrees.x = clampf(phantom_camera_rotation_degrees.x, min_pitch, max_pitch)
		
		phantom_camera_rotation_degrees.y -= event.relative.x * mouse_sensitivity
		phantom_camera_rotation_degrees.y = wrapf(phantom_camera_rotation_degrees.y, min_yaw, max_yaw)
		
		phantom_camera.rotation_degrees = phantom_camera_rotation_degrees
