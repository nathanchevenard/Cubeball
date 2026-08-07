extends Node3D
class_name LevelEnvironment

@export var ball_field_ground_material : Material
@export var cuboid_field_ground_material : Material


func _init() -> void:
	SignalsManager.level.level_initialized.connect(_on_level_initialized)


func _on_level_initialized(level : Level):
	if ball_field_ground_material != null:
		var ball_ground : MeshInstance3D = level.ground.get_child(0) as MeshInstance3D
		ball_ground.set_surface_override_material(0, ball_field_ground_material)
	
	if cuboid_field_ground_material != null:
		var cuboid_ground : MeshInstance3D = level.ground_cuboid_field.get_child(0).get_child(1) as MeshInstance3D
		cuboid_ground.set_surface_override_material(0, cuboid_field_ground_material)
