@tool
extends Node

@export var cube_mesh : MeshInstance3D
@export var color : Color:
	set(value):
		color = value
		if cube_mesh != null:
			(cube_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color = value
