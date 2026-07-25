extends Node
class_name CameraManager

@export var camera : Camera3D
@export var initial_camera_state : CameraState

var current_camera_state : CameraState

static var instance : CameraManager


func _init() -> void:
	instance = self
	
	SignalsManager.settings.cameras_disable.connect(_on_camera_disabled)


func _ready() -> void:
	set_camera_state(initial_camera_state)


func set_camera_state(camera_state : CameraState):
	if current_camera_state != null:
		current_camera_state.exit_state()
	
	var old_camera_state = current_camera_state
	current_camera_state = camera_state
	
	camera_state.enter_state(old_camera_state)


func _process(delta: float) -> void:
	if current_camera_state != null:
		current_camera_state.process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_camera_state != null:
		current_camera_state.apply_input(event)


func _on_camera_disabled():
	call_deferred("queue_free")
