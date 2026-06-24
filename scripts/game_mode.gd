extends Resource
class_name GameMode

@export var team_list : Array[GameModeTeam]
@export var max_duration_seconds : float
@export var max_goal : int = 1
@export var level_size : Vector3 = Vector3.ONE
@export var goal_size : Vector3 = Vector3.ONE
@export var ball_number : int = 1
@export var obstacle_number_min : int = 5
@export var obstacle_number_max : int = 10
