extends Node
class_name EnvironmentManager

@export var environement_scene : PackedScene


func _ready() -> void:
	var environment : Node3D = environement_scene.instantiate()
	add_child(environment)
