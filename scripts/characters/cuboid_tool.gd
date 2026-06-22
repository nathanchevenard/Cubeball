@tool
extends Node
class_name CuboidTool

@export var cuboid : Cuboid
@export var cube_mesh : MeshInstance3D
@export var color : Color:
	set(value):
		color = value
		if cube_mesh != null:
			(cube_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color = value


func _ready() -> void:
	cuboid.color_changed.connect(_on_color_changed)


func _on_color_changed(new_color : Color):
	color = new_color
