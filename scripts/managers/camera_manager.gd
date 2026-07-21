extends Node
class_name CameraManager

@export var free_phantom_camera : PhantomCamera3D
@export var focus_phantom_camera : PhantomCamera3D

@export var focus_offset : Vector3

static var instance : CameraManager

var current_camera : PhantomCamera3D
var current_follow_target : Node3D


func _init() -> void:
	instance = self


func _ready() -> void:
	enable_camera(free_phantom_camera)


func _process(delta: float) -> void:
	if current_camera == focus_phantom_camera:
		var direction : Vector3 = (current_follow_target.global_position - current_camera.look_at_target.global_position).normalized()
		direction.y = 1
		current_camera.global_position = current_follow_target.global_position + direction * focus_offset


func enable_camera(camera : PhantomCamera3D, follow_target : Node3D = null):
	if current_camera != null:
		current_camera.priority = 0
	
	camera.priority = 1
	current_camera = camera
	current_follow_target = follow_target
