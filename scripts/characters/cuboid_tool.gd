@tool
extends Node
class_name CuboidTool

@export var cuboid : Cuboid
@export var cube_mesh : MeshInstance3D
@export var eye_mesh : MeshInstance3D
@export var eye2_mesh : MeshInstance3D
@export var color : Color:
	set(value):
		color = value
		var material := _get_instance_material()
		if material != null:
			material.albedo_color = value

# cube_mesh/eye_mesh/eye2_mesh all shared a single `resource_local_to_scene` material in the
# editor so every spawned Cuboid would get one duplicate covering body + eyes together. Godot
# duplicates that resource as part of PackedScene.instantiate(), which races the RenderingServer
# when many Cuboids are instantiated back-to-back (see TeamsManager._spawn_team_cuboids during
# discover_spaces) — surfacing as spurious "Parameter material is null" engine errors. Duplicating
# explicitly here instead, once per Cuboid instance, avoids that race.
var _instance_material : StandardMaterial3D


func _ready() -> void:
	cuboid.color_changed.connect(_on_color_changed)


func _on_color_changed(new_color : Color):
	color = new_color


func _get_instance_material() -> StandardMaterial3D:
	if _instance_material == null:
		if cube_mesh == null:
			return null

		var base_material := cube_mesh.get_surface_override_material(0) as StandardMaterial3D
		if base_material == null:
			return null

		_instance_material = base_material.duplicate()
		for mesh in [cube_mesh, eye_mesh, eye2_mesh]:
			if mesh != null:
				mesh.set_surface_override_material(0, _instance_material)

	return _instance_material
