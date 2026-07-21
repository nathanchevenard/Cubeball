extends Node3D
class_name Level


@export var cuboid_field_wall_height : float = 10
@export var cuboid_field_margin : Vector3 = Vector3(3, 0, 3)
@export var border_wall_width : float = 0.1
@export var penatly_area_width : float = 1.5

@export var ground_ball_field_scene : PackedScene
@export var wall_ball_field_scene : PackedScene
@export var line_border_ball_field_scene : PackedScene
@export var ball_field_area_scene : PackedScene
@export var ground_cuboid_field_scene : PackedScene
@export var wall_cuboid_field_scene : PackedScene
@export var goal_scene : PackedScene
@export var ball_scene : PackedScene
@export var obstacle_scene : PackedScene

var goal_list : Array[Goal]
var ball_list : Array[Ball]
var obstacle_list : Array[Obstacle]
var wall_list : Array[Wall]
var ground : Node3D
var ball_field_border_list : Array[Node3D]
var ground_cuboid_field : Node3D
var ball_field_area : Node3D

var game_mode : GameMode


func _init() -> void:
	SignalsManager.game.game_mode_set.connect(_on_game_mode_set)
	SignalsManager.game.game_reset.connect(_on_game_reset)
	SignalsManager.game.start_next_point.connect(_on_game_reset)
	SignalsManager.level.level_spawn_node_at_random_pos.connect(_on_spawn_node_at_random_pos)


func _on_game_mode_set(new_game_mode : GameMode) -> void:
	build_level(new_game_mode)


# Tears down any previously built arena (ground/walls/goals/balls/obstacles) and rebuilds
# it from `new_game_mode`. Called both the first time the level is set up and every time
# Python pushes a new episode config with a (possibly different) ball_field/goal size or ball
# count, since goal geometry (CSG reparented into the containing wall, see spawn_goal)
# cannot safely be resized in place.
func build_level(new_game_mode : GameMode) -> void:
	destroy_level()

	game_mode = new_game_mode
	var size_x : float = game_mode.level_size.x
	var size_y : float = game_mode.level_size.y
	var size_z : float = game_mode.level_size.z
	var goal_scale : Vector3 = game_mode.goal_size
	var ball_number : int = game_mode.ball_number
	var obstacle_number : int = game_mode.obstacle_number

	# Spawn Ground
	ground = ground_ball_field_scene.instantiate()
	add_child(ground)
	ground.scale = Vector3(size_x, 1, size_z)
	ball_field_area = ball_field_area_scene.instantiate()
	add_child(ball_field_area)
	ball_field_area.scale = game_mode.level_size

	# Spawn Walls
	var wall1 : Wall = spawn_wall(wall_ball_field_scene, Vector3(0, 0, size_z / 2), Vector3(0, -PI / 2, 0), Vector3(1, size_y, size_x))
	var wall2 : Wall = spawn_wall(wall_ball_field_scene, Vector3(0, 0, -size_z / 2), Vector3(0, PI / 2, 0), Vector3(1, size_y, size_x))
	spawn_wall(wall_ball_field_scene, Vector3(size_x / 2, 0, 0), Vector3(0, 0, 0), Vector3(1, size_y, size_z))
	spawn_wall(wall_ball_field_scene, Vector3(-size_x / 2, 0, 0), Vector3(0, PI, 0), Vector3(1, size_y, size_z))

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
	for i in obstacle_number:
		spawn_obstacle()

	spawn_ball_field_border_walls()
	spawn_cuboid_field()

	SignalsManager.level.emit_level_initialized(self)


func destroy_level() -> void:
	for cuboid in EntityManager.instance.cuboid_list:
		cuboid.destroy()
	
	if ground != null:
		ground.call_deferred("queue_free")
		ground = null

	for wall in wall_list:
		wall.call_deferred("queue_free")
	wall_list.clear()

	for goal in goal_list:
		goal.call_deferred("queue_free")
	goal_list.clear()

	for ball in ball_list:
		ball.destroy()
	ball_list.clear()

	for obstacle in obstacle_list:
		obstacle.destroy()
	obstacle_list.clear()

	if ground_cuboid_field != null:
		ground_cuboid_field.call_deferred("queue_free")
		ground_cuboid_field = null

	for ball_field_border in ball_field_border_list:
		ball_field_border.call_deferred("queue_free")
	ball_field_border_list.clear()

	if ball_field_area != null:
		ball_field_area.call_deferred("queue_free")


func spawn_wall(scene : PackedScene, spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3) -> Wall:
	var wall : Wall = scene.instantiate() as Wall
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
	for csg_box in goal.wall_csg_box_list:
		csg_box.reparent(parent_wall.csg_combiner)
		parent_wall.csg_combiner.move_child(csg_box, 0)
	parent_wall.collision_shape.shape = parent_wall.csg_box.bake_collision_shape()

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


func spawn_ball_field_border_walls():
	var size_x : float = game_mode.level_size.x
	var size_y : float = game_mode.level_size.y
	var size_z : float = game_mode.level_size.z
	
	var wall_spawn_height : float = -border_wall_width / 2
	
	# Border ball_field walls
	spawn_wall(line_border_ball_field_scene, Vector3(0, wall_spawn_height, size_z / 2), Vector3(0, -PI / 2, 0), Vector3(border_wall_width, border_wall_width, size_x + 2 * border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(0, wall_spawn_height, -size_z / 2), Vector3(0, PI / 2, 0), Vector3(border_wall_width, border_wall_width, size_x + 2 * border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(size_x / 2, wall_spawn_height, 0), Vector3(0, 0, 0), Vector3(border_wall_width, border_wall_width, size_z + 2 * border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(-size_x / 2, wall_spawn_height, 0), Vector3(0, PI, 0), Vector3(border_wall_width, border_wall_width, size_z + 2 * border_wall_width))
	
	# Middle ball_field wall
	spawn_wall(line_border_ball_field_scene, Vector3(0, wall_spawn_height, 0), Vector3(0, -PI / 2, 0), Vector3(border_wall_width, border_wall_width, size_x + 2 * border_wall_width))
	
	# Middle dot
	var middle_dot : CSGCylinder3D = CSGCylinder3D.new()
	middle_dot.height = border_wall_width
	middle_dot.radius = 0.4
	middle_dot.sides = 32
	add_child(middle_dot)
	ball_field_border_list.append(middle_dot) 
	
	# Middle ring
	spawn_border_middle_ring()
	
	# Penalty zones
	# Left goal zone
	spawn_wall(line_border_ball_field_scene, Vector3(-game_mode.goal_size.z / 2 - border_wall_width / 2, wall_spawn_height, goal_list[0].global_position.z + penatly_area_width), Vector3.ZERO, Vector3(game_mode.goal_size.z + border_wall_width, border_wall_width, border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(-game_mode.goal_size.z / 2, wall_spawn_height, goal_list[0].global_position.z + penatly_area_width), Vector3(0, PI / 2, 0), Vector3(penatly_area_width + border_wall_width, border_wall_width, border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(game_mode.goal_size.z / 2, wall_spawn_height, goal_list[0].global_position.z + penatly_area_width), Vector3(0, PI / 2, 0), Vector3(penatly_area_width + border_wall_width, border_wall_width, border_wall_width))
	# Right goal zone
	spawn_wall(line_border_ball_field_scene, Vector3(-game_mode.goal_size.z / 2 - border_wall_width / 2, wall_spawn_height, goal_list[1].global_position.z - penatly_area_width), Vector3.ZERO, Vector3(game_mode.goal_size.z + border_wall_width, border_wall_width, border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(-game_mode.goal_size.z / 2, wall_spawn_height, goal_list[1].global_position.z + border_wall_width), Vector3(0, PI / 2, 0), Vector3(penatly_area_width + border_wall_width, border_wall_width, border_wall_width))
	spawn_wall(line_border_ball_field_scene, Vector3(game_mode.goal_size.z / 2, wall_spawn_height, goal_list[1].global_position.z + border_wall_width), Vector3(0, PI / 2, 0), Vector3(penatly_area_width + border_wall_width, border_wall_width, border_wall_width))


func spawn_border_middle_ring():
	var middle_ring_outer : CSGCylinder3D = CSGCylinder3D.new()
	middle_ring_outer.height = border_wall_width
	middle_ring_outer.radius = 1.8
	middle_ring_outer.sides = 32
	add_child(middle_ring_outer)
	ball_field_border_list.append(middle_ring_outer)
	var middle_ring_inner : CSGCylinder3D = CSGCylinder3D.new()
	middle_ring_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	middle_ring_inner.height = border_wall_width
	middle_ring_inner.radius = 1.7
	middle_ring_inner.sides = 32
	middle_ring_outer.add_child(middle_ring_inner)
	ball_field_border_list.append(middle_ring_inner)


func spawn_cuboid_field():
	var size_x : float = game_mode.level_size.x
	var size_y : float = game_mode.level_size.y
	var size_z : float = game_mode.level_size.z
	
	# Room ground
	ground_cuboid_field = ground_cuboid_field_scene.instantiate()
	add_child(ground_cuboid_field)
	ground_cuboid_field.scale = Vector3(size_x + cuboid_field_margin.x, 1, size_z + cuboid_field_margin.z)
	ground_cuboid_field.global_position.y -= 0.01
	
	# Room walls
	spawn_wall(wall_cuboid_field_scene, Vector3(0, 0, (size_z + cuboid_field_margin.z) / 2), Vector3(0, -PI / 2, 0), Vector3(1, cuboid_field_wall_height, size_x + cuboid_field_margin.x))
	spawn_wall(wall_cuboid_field_scene, Vector3(0, 0, -(size_z + cuboid_field_margin.z) / 2), Vector3(0, PI / 2, 0), Vector3(1, cuboid_field_wall_height, size_x + cuboid_field_margin.x))
	spawn_wall(wall_cuboid_field_scene, Vector3((size_x + cuboid_field_margin.x) / 2, 0, 0), Vector3(0, 0, 0), Vector3(1, cuboid_field_wall_height, size_z + cuboid_field_margin.z))
	spawn_wall(wall_cuboid_field_scene, Vector3(-(size_x + cuboid_field_margin.x) / 2, 0, 0), Vector3(0, PI, 0), Vector3(1, cuboid_field_wall_height, size_z + cuboid_field_margin.z))


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
