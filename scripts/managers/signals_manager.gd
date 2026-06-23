extends Node

var goal : GoalSignals = GoalSignals.new()
var score : ScoreSignals = ScoreSignals.new()
var team : TeamSignals = TeamSignals.new()
var level : LevelSignals = LevelSignals.new()


class GoalSignals:
	signal goal_scored(receiving_team : Team)
	func emit_goal_scored(receiving_team : Team):
		goal_scored.emit(receiving_team)


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
	
	signal level_spawn_node_at_random_pos(node : Node)
	func emit_level_spawn_node_at_random_pos(node : Node):
		level_spawn_node_at_random_pos.emit(node)
