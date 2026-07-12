extends Node

var goal : GoalSignals = GoalSignals.new()
var score : ScoreSignals = ScoreSignals.new()
var team : TeamSignals = TeamSignals.new()
var level : LevelSignals = LevelSignals.new()
var game : GameSignals = GameSignals.new()


class GoalSignals:
	signal ball_enter_goal(receiving_team : Team)
	func emit_ball_enter_goal(receiving_team : Team):
		ball_enter_goal.emit(receiving_team)
	
	signal goal_scored(receiving_team : Team)
	func emit_goal_scored(receiving_team : Team):
		goal_scored.emit(receiving_team)
	
	signal goal_animation_finish
	func emit_goal_animation_finish():
		goal_animation_finish.emit()


class ScoreSignals:
	signal score_updated(team : Team, new_score : int)
	func emit_score_updated(team : Team, new_score : int):
		score_updated.emit(team, new_score)


class TeamSignals:
	signal team_initialized(team : Team)
	func emit_team_initialized(team : Team):
		team_initialized.emit(team)
	
	signal all_teams_initialized
	func emit_all_teams_initialized():
		all_teams_initialized.emit()


class LevelSignals:
	signal level_initialized(level : Level)
	func emit_level_initialized(level : Level):
		level_initialized.emit(level)
	
	signal level_reset(level : Level)
	func emit_level_reset(level : Level):
		level_reset.emit(level)
	
	signal level_spawn_node_at_random_pos(node : Node)
	func emit_level_spawn_node_at_random_pos(node : Node):
		level_spawn_node_at_random_pos.emit(node)


class GameSignals:
	signal game_mode_set(game_mode : GameMode)
	func emit_game_mode_set(game_mode : GameMode):
		game_mode_set.emit(game_mode)
	
	signal game_start
	func emit_game_start():
		game_start.emit()
	
	signal game_finish
	func emit_game_finish():
		game_finish.emit()
	
	signal game_reset
	func emit_game_reset():
		game_reset.emit()
