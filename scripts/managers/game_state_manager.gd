extends Node
class_name GameStateManager

var game_mode : GameMode
var score : Dictionary[Team, int]
var timer : float


func _init() -> void:
	SignalsManager.game.game_mode_set.connect(_on_game_mode_set)
	SignalsManager.goal.ball_enter_goal.connect(_on_ball_enter_goal)
	SignalsManager.team.team_initialized.connect(_on_team_initialized)
	SignalsManager.game.game_reset.connect(_on_game_reset)


func _on_game_mode_set(new_game_mode : GameMode):
	game_mode = new_game_mode


func _on_team_initialized(team : Team):
	score[team] = 0


func _on_game_reset():
	for team in score.keys():
		score[team] = 0


func _on_ball_enter_goal(receiving_team : Team):
	for team : Team in score.keys():
		if team != receiving_team:
			if score[team] + 1 >= game_mode.max_goal:
				SignalsManager.game.emit_game_finish()
				SignalsManager.game.emit_game_reset()
			else:
				score[team] += 1
				SignalsManager.goal.emit_goal_scored(receiving_team)
