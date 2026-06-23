extends Node3D
class_name Level

@export var size_x : float
@export var size_z : float
@export var size_y : float

@export var goal_scale : Vector3 = Vector3.ONE

@export var ground_scene : PackedScene
@export var wall_scene : PackedScene
@export var goal_scene : PackedScene

@export var obstacle_scene : PackedScene
@export var obstacle_number_min : int
@export var obstacle_number_max : int


func _init() -> void:
	SignalsManager.level.level_spawn_node_at_random_pos.connect(_on_spawn_node_at_random_pos)


func _ready() -> void:
	# Spawn Ground
	var ground : Node3D = ground_scene.instantiate()
	add_child(ground)
	ground.scale = Vector3(size_x, 1, size_z)
	
	# Spawn Walls
	var wall1 : Wall = spawn_wall(Vector3(0, 0, size_z / 2), Vector3(0, -PI / 2, 0), Vector3(1, size_y, size_x))
	var wall2 : Wall = spawn_wall(Vector3(0, 0, -size_z / 2), Vector3(0, PI / 2, 0), Vector3(1, size_y, size_x))
	spawn_wall(Vector3(size_x / 2, 0, 0), Vector3(0, 0, 0), Vector3(1, size_y, size_z))
	spawn_wall(Vector3(-size_x / 2, 0, 0), Vector3(0, PI, 0), Vector3(1, size_y, size_z))
	
	# Spawn Goals
	var goal1 : Goal = spawn_goal(Vector3(0, 0, size_z / 2), Vector3(0, -PI / 2, 0), goal_scale)
	goal1.csg_box.reparent(wall1.csg_combiner)
	wall1.collision_shape.shape = wall1.csg_combiner.bake_collision_shape()
	
	var goal2 : Goal = spawn_goal(Vector3(0, 0, -size_z / 2), Vector3(0, PI / 2, 0), goal_scale)
	goal2.csg_box.reparent(wall2.csg_combiner)
	wall2.collision_shape.shape = wall2.csg_combiner.bake_collision_shape()
	
	var obstacle_random_number : int = randi_range(obstacle_number_min, obstacle_number_max)
	for i in obstacle_random_number:
		spawn_obstacle()
	
	SignalsManager.level.emit_level_initialized(self)


func spawn_wall(spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3) -> Wall:
	var wall : Wall = wall_scene.instantiate() as Wall
	add_child(wall)
	wall.global_position = spawn_position
	wall.global_rotation = spawn_rotation
	wall.scale = spawn_scale
	
	return wall


func spawn_goal(spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3) -> Goal:
	var goal : Goal = goal_scene.instantiate() as Goal
	add_child(goal)
	goal.global_position = spawn_position
	goal.global_rotation = spawn_rotation
	goal.initialize(spawn_scale)
	
	return goal


func _on_spawn_node_at_random_pos(node : Node3D):
	var offset_x : float = node.scale.x / 2
	var offset_z : float = node.scale.z / 2
	var random_x : float = randf_range(-size_x / 2 + offset_x, size_x / 2 - offset_x)
	var random_z : float = randf_range(-size_z / 2 + offset_z, size_z / 2 - offset_z)
	node.global_position = Vector3(random_x, 0, random_z)


func spawn_obstacle():
	var obstacle : Obstacle = obstacle_scene.instantiate() as Obstacle
	add_child(obstacle)
	_on_spawn_node_at_random_pos(obstacle)
