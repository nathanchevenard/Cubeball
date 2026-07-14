extends Node
class_name GameModeManager

@export var game_mode : GameMode

static var instance : GameModeManager


func _init() -> void:
	instance = self


func _ready() -> void:
	# Always builds an initial arena from the editor-assigned GameMode, even in
	# training mode — relying on AgentSynchronizer having already decided whether it's
	# waiting for Python by the time this runs would depend on sibling _ready() order,
	# which is fragile. Instead, if Python is driving training, its first "reset"
	# message tears this down and rebuilds moments later through the exact same path
	# as every later episode (see AgentSynchronizer.handle_message/_start_new_match and
	# Level.rebuild/TeamsManager._spawn_roster, which already handle "destroy previous,
	# build new" robustly). The one-time wasted build is a negligible startup cost.
	SignalsManager.game.emit_game_mode_set(game_mode)


# Starts from `base_mode` (always the GameMode assigned in the editor, never a previous
# runtime result) and returns a duplicated, overridden GameMode. `overrides` is a plain
# Dictionary, built from the "config" object of a Python "reset" message (see
# AgentSynchronizer._start_new_match). Missing keys keep `base_mode`'s value.
func apply_overrides(base_mode : GameMode, overrides : Dictionary) -> GameMode:
	var runtime_game_mode : GameMode = base_mode.duplicate(true)

	if overrides.has("max_duration_seconds"):
		runtime_game_mode.max_duration_seconds = float(overrides["max_duration_seconds"])
	if overrides.has("max_goal"):
		runtime_game_mode.max_goal = int(overrides["max_goal"])
	if overrides.has("ball_number"):
		runtime_game_mode.ball_number = int(overrides["ball_number"])
	if overrides.has("obstacle_number_min"):
		runtime_game_mode.obstacle_number_min = int(overrides["obstacle_number_min"])
	if overrides.has("obstacle_number_max"):
		runtime_game_mode.obstacle_number_max = int(overrides["obstacle_number_max"])
	if overrides.has("level_size"):
		runtime_game_mode.level_size = _to_vector3(overrides["level_size"])
	if overrides.has("goal_size"):
		runtime_game_mode.goal_size = _to_vector3(overrides["goal_size"])

	if overrides.has("players_per_team"):
		var players_per_team : Array = overrides["players_per_team"]
		for i in range(mini(players_per_team.size(), runtime_game_mode.team_list.size())):
			runtime_game_mode.team_list[i].players_number = int(players_per_team[i])

	return runtime_game_mode


func _to_vector3(value) -> Vector3:
	if value is Vector3:
		return value
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
