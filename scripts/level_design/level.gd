extends Node3D
class_name Level


@export var ground_scene : PackedScene
@export var wall_scene : PackedScene
@export var goal_scene : PackedScene
@export var ball_scene : PackedScene
@export var obstacle_scene : PackedScene

var goal_list : Array[Goal]
var ball_list : Array[Ball]
var obstacle_list : Array[Obstacle]
var wall_list : Array[Wall]
var ground : Node3D

var game_mode : GameMode


func _init() -> void:
	SignalsManager.game.game_mode_set.connect(_on_game_mode_set)
	SignalsManager.game.game_reset.connect(_on_game_reset)
	SignalsManager.game.start_next_point.connect(_on_game_reset)
	SignalsManager.level.level_spawn_node_at_random_pos.connect(_on_spawn_node_at_random_pos)


func _on_game_mode_set(new_game_mode : GameMode) -> void:
	rebuild(new_game_mode)


# Tears down any previously built arena (ground/walls/goals/balls/obstacles) and rebuilds
# it from `new_game_mode`. Called both the first time the level is set up and every time
# Python pushes a new episode config with a (possibly different) field/goal size or ball
# count, since goal geometry (CSG reparented into the containing wall, see spawn_goal)
# cannot safely be resized in place.
func rebuild(new_game_mode : GameMode) -> void:
	_teardown()

	game_mode = new_game_mode
	var size_x : float = game_mode.level_size.x
	var size_y : float = game_mode.level_size.y
	var size_z : float = game_mode.level_size.z
	var goal_scale : Vector3 = game_mode.goal_size
	var ball_number : int = game_mode.ball_number
	var obstacle_number_min : int = game_mode.obstacle_number_min
	var obstacle_number_max : int = game_mode.obstacle_number_max

	# Spawn Ground
	ground = ground_scene.instantiate()
	add_child(ground)
	ground.scale = Vector3(size_x, 1, size_z)

	# Spawn Walls
	var wall1 : Wall = spawn_wall(Vector3(0, 0, size_z / 2), Vector3(0, -PI / 2, 0), Vector3(1, size_y, size_x))
	var wall2 : Wall = spawn_wall(Vector3(0, 0, -size_z / 2), Vector3(0, PI / 2, 0), Vector3(1, size_y, size_x))
	spawn_wall(Vector3(size_x / 2, 0, 0), Vector3(0, 0, 0), Vector3(1, size_y, size_z))
	spawn_wall(Vector3(-size_x / 2, 0, 0), Vector3(0, PI, 0), Vector3(1, size_y, size_z))

	# Spawn Goals
	goal_list.append(spawn_goal(Vector3(0, 0, -size_z / 2), Vector3(0, PI / 2, 0), goal_scale, wall2))
	goal_list.append(spawn_goal(Vector3(0, 0, size_z / 2), Vector3(0, -PI / 2, 0), goal_scale, wall1))

	# Spawn Ball
	for i in range(0, ball_number):
		var ball : Ball = ball_scene.instantiate() as Ball
		ball.level = self
		add_child(ball)
		_on_spawn_node_at_random_pos(ball)
		ball.global_position.y = 1
		ball_list.append(ball)

	# Spawn Obstacles
	var obstacle_random_number : int = randi_range(obstacle_number_min, obstacle_number_max)
	for i in obstacle_random_number:
		spawn_obstacle()

	SignalsManager.level.emit_level_initialized(self)


func _teardown() -> void:
	if ground != null:
		ground.queue_free()
		ground = null

	for wall in wall_list:
		wall.queue_free()
	wall_list.clear()

	for goal in goal_list:
		goal.queue_free()
	goal_list.clear()

	for ball in ball_list:
		ball.destroy()
	ball_list.clear()

	for obstacle in obstacle_list:
		obstacle.destroy()
	obstacle_list.clear()


func spawn_wall(spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3) -> Wall:
	var wall : Wall = wall_scene.instantiate() as Wall
	add_child(wall)
	wall.global_position = spawn_position
	wall.global_rotation = spawn_rotation
	wall.scale = spawn_scale
	wall_list.append(wall)

	return wall


func spawn_goal(spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3, parent_wall : Wall) -> Goal:
	var goal : Goal = goal_scene.instantiate() as Goal
	add_child(goal)
	goal.global_position = spawn_position
	goal.global_rotation = spawn_rotation
	goal.initialize(spawn_scale)

	goal.csg_box.reparent(parent_wall.csg_combiner)
	parent_wall.collision_shape.shape = parent_wall.csg_combiner.bake_collision_shape()
	for csg_box in goal.wall_csg_box_list:
		csg_box.reparent(parent_wall.csg_combiner)
		parent_wall.csg_combiner.move_child(csg_box, 1)

	return goal


func _on_spawn_node_at_random_pos(node : Node3D):
	var size_x : float = game_mode.level_size.x
	var size_z : float = game_mode.level_size.z
	var offset_x : float = node.scale.x / 2
	var offset_z : float = node.scale.z / 2
	var random_x : float = randf_range(-size_x / 2 + offset_x, size_x / 2 - offset_x)
	var random_z : float = randf_range(-size_z / 2 + offset_z, size_z / 2 - offset_z)
	node.global_position = Vector3(random_x, 0, random_z)
	node.global_rotation = Vector3(0, randf_range(0, 2 * PI), 0)


func spawn_obstacle():
	var obstacle : Obstacle = obstacle_scene.instantiate() as Obstacle
	obstacle.level = self
	add_child(obstacle)
	_on_spawn_node_at_random_pos(obstacle)
	obstacle_list.append(obstacle)


func _on_game_reset():
	reset_level()


func reset_level():
	for ball in ball_list:
		_on_spawn_node_at_random_pos(ball)
		ball.reset()

	for obstacle in obstacle_list:
		_on_spawn_node_at_random_pos(obstacle)
		obstacle.reset()

	SignalsManager.level.emit_level_reset(self)
