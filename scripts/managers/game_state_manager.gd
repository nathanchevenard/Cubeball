extends Node
class_name GameStateManager

var game_mode : GameMode
var score : Dictionary[Team, int]
var timer : float

@export var timer_label : Label

static var instance : GameStateManager


func _init() -> void:
	instance = self
	
	SignalsManager.game.game_mode_set.connect(_on_game_mode_set)
	SignalsManager.goal.ball_enter_goal.connect(_on_ball_enter_goal)
	SignalsManager.team.team_initialized.connect(_on_team_initialized)
	SignalsManager.game.game_reset.connect(_on_game_reset)


func _process(delta: float) -> void:
	timer += delta
	timer_label.text = "%0.1f" % (game_mode.max_duration_seconds - timer)
	
	if timer >= game_mode.max_duration_seconds:
		SignalsManager.game.emit_game_finish()
		SignalsManager.game.emit_game_reset()


func get_observation_informations(caller : Cuboid) -> Dictionary:
	var dictionary : Dictionary

	dictionary["timer"] = timer / game_mode.max_duration_seconds
	dictionary["score"] = 0

	return dictionary


func get_time_remaining_ratio() -> float:
	return clampf(1.0 - (timer / game_mode.max_duration_seconds), 0.0, 1.0)


func _on_game_mode_set(new_game_mode : GameMode):
	game_mode = new_game_mode
	timer_label.text = "%0.1f" % game_mode.max_duration_seconds


func _on_team_initialized(team : Team):
	score[team] = 0


func _on_game_reset():
	timer = 0
	
	for team in score.keys():
		score[team] = 0


func _on_ball_enter_goal(receiving_team : Team):
	SignalsManager.goal.emit_goal_scored(receiving_team)
	
	for team : Team in score.keys():
		if team != receiving_team:
			score[team] += 1
			if score[team] >= game_mode.max_goal:
				SignalsManager.game.emit_game_finish()
				SignalsManager.game.emit_game_reset()
