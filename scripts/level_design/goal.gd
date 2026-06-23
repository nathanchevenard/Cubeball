extends Area3D
class_name Goal

@export var team : Team
@export var wall_scene : PackedScene
@export var wall_override_material : StandardMaterial3D
@export var wall_width : float = 1
@export var csg_box : CSGBox3D


func initialize(spawn_scale):
	scale = spawn_scale
	# Floor Wall
	var floor_wall : Wall = spawn_wall(Vector3(0, 0, 0), Vector3(PI, 0, 0), Vector3(spawn_scale.x, wall_width, spawn_scale.z) / scale)
	floor_wall.add_to_group("ground")
	# Ceiling Wall
	spawn_wall(Vector3(0, spawn_scale.y, 0) / scale, Vector3(0, 0, 0), Vector3(spawn_scale.x, wall_width, spawn_scale.z) / scale)
	# Back Wall
	spawn_wall(Vector3(spawn_scale.x, 0, 0) / scale, Vector3(0, 0, 0), Vector3(wall_width, spawn_scale.y, spawn_scale.z) / scale)
	# Left Wall
	spawn_wall(Vector3(0, 0, -spawn_scale.z / 2 - wall_width / 2) / scale, Vector3(0, 0, 0), Vector3(spawn_scale.x, spawn_scale.y, wall_width) / scale)
	# Right Wall
	spawn_wall(Vector3(0, 0, spawn_scale.z / 2 + wall_width / 2) / scale, Vector3(0, 0, 0), Vector3(spawn_scale.x, spawn_scale.y, wall_width) / scale)


func spawn_wall(spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3) -> Wall:
	var wall : Wall = wall_scene.instantiate() as Wall
	add_child(wall)
	wall.position = spawn_position
	wall.rotation = spawn_rotation
	wall.scale = spawn_scale
	
	if wall_override_material != null:
		wall.csg_box.material = wall_override_material
	
	return wall


func score_goal():
	SignalsManager.goal.emit_goal_scored(team)


func _on_body_entered(body: Node3D) -> void:
	if body is Ball:
		score_goal()
