extends Node
class_name TeamsManager

@export var cuboid_scene : PackedScene

var team_list : Array[Team]


func _init() -> void:
	SignalsManager.level.level_initialized.connect(_on_level_initialized)
	SignalsManager.level.level_reset.connect(_on_level_resetted)
	SignalsManager.game.game_reset.connect(_on_game_reset)


func _on_level_initialized(level : Level):
	if team_list.is_empty():
		_initialize_teams(level)

	_assign_goals_to_teams(level)
	_spawn_team_cuboids(level)

	SignalsManager.team.emit_all_teams_initialized()


# Teams themselves (score, color, ...) persist for the whole process — only the cuboid
# roster under each team is rebuilt every episode (see _spawn_roster).
func _initialize_teams(level : Level) -> void:
	for game_mode_team in level.game_mode.team_list:
		var team : Team = game_mode_team.team
		team_list.append(team)
		team.initialize()


# Goals are torn down and rebuilt by Level every match (see Level.rebuild), so the
# team <-> goal association has to be redone every time.
func _assign_goals_to_teams(level : Level) -> void:
	for i in range(mini(team_list.size(), level.goal_list.size())):
		var team : Team = team_list[i]
		var goal : Goal = level.goal_list[i]
		goal.team = team
		if goal.wall_override_material != null:
			goal.wall_override_material.albedo_color = team.color


# Destroys the previous episode's cuboids (a no-op the first time, team.cuboid_list is
# still empty) and spawns exactly this episode's roster. Matches level.game_mode.team_list
# to team_list by index rather than by the GameModeTeam's `team` resource reference, since
# GameMode.duplicate(true) deep-copies a fresh Team resource every episode (see
# GameModeManager.apply_overrides) — that fresh copy's cuboid_list is always empty, only
# the original team_list entries are populated. Each cuboid's agent_id ("team{i}_{slot}")
# is how Python identifies it in the training wire protocol (see agent_synchronizer.gd).
func _spawn_team_cuboids(level : Level) -> void:
	var is_first_cuboid : bool = true

	for team_index in range(mini(team_list.size(), level.game_mode.team_list.size())):
		var team : Team = team_list[team_index]
		var players_number : int = level.game_mode.team_list[team_index].players_number

		for slot_index in players_number:
			var cuboid : Cuboid = cuboid_scene.instantiate() as Cuboid
			cuboid.level = level
			add_child(cuboid)
			cuboid.set_team(team)
			cuboid.cuboid_ai_controller.agent_id = "team%d_cuboid%d" % [team_index, slot_index]
			SignalsManager.level.emit_level_spawn_node_at_random_pos(cuboid)


func _on_game_reset():
	for team in team_list:
		team.set_score(0)


func _on_level_resetted(_level : Level):
	for team in team_list:
		for cuboid in team.cuboid_list:
			SignalsManager.level.emit_level_spawn_node_at_random_pos(cuboid)
			cuboid.reset()
