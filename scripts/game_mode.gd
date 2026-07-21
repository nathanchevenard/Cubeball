extends Resource
class_name GameMode

@export var team_list : Array[GameModeTeam]
@export var max_duration_seconds : float = 30
@export var max_goal : int = 1
@export var level_size : Vector3 = Vector3.ONE
@export var goal_size : Vector3 = Vector3.ONE
@export var ball_number : int = 1
@export var obstacle_number : int = 0


func _init(data : Dictionary = {}) -> void:
	if data.has("max_duration_seconds"):
		max_duration_seconds = float(data["max_duration_seconds"])
	if data.has("max_goal"):
		max_goal = int(data["max_goal"])
	if data.has("ball_number"):
		ball_number = int(data["ball_number"])
	if data.has("obstacle_number"):
		obstacle_number = int(data["obstacle_number"])
	if data.has("level_size"):
		level_size = Utilities.list_to_vector3(data["level_size"])
	if data.has("goal_size"):
		goal_size = Utilities.list_to_vector3(data["goal_size"])
	
	if data.has("team_list"):
		# JSON always parses to an untyped Array (even for an array of objects), so this
		# can't be typed Array[Dictionary] directly — GDScript rejects that assignment.
		var new_team_list : Array = data["team_list"]
		for team_data in new_team_list:
			var game_mode_team : GameModeTeam = GameModeTeam.new()
			var new_team : Team = Team.new()
			if team_data.has("name"):
				new_team.name = team_data["name"]
			if team_data.has("color"):
				new_team.color = Utilities.list_to_color(team_data["color"])
			game_mode_team.team = new_team
			if team_data.has("players_number"):
				game_mode_team.players_number = int(team_data["players_number"])

			team_list.append(game_mode_team)
