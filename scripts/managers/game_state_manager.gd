extends Node
class_name GameStateManager

var game_mode : GameMode
var score : Dictionary[Team, int]
var timer : float
var is_post_goal : bool = false

@export var timer_label : Label

static var instance : GameStateManager


func _init() -> void:
	instance = self
	
	SignalsManager.game.game_mode_set.connect(_on_game_mode_set)
	SignalsManager.goal.ball_enter_goal.connect(_on_ball_enter_goal)
	SignalsManager.goal.goal_animation_finish.connect(_on_goal_animation_finished)
	SignalsManager.team.team_initialized.connect(_on_team_initialized)
	SignalsManager.game.start_next_point.connect(_on_start_next_point)
	SignalsManager.game.game_reset.connect(_on_game_reset)


func _process(delta: float) -> void:
	timer += delta
	timer_label.text = "%0.1f" % (game_mode.max_duration_seconds - timer)
	
	if timer >= game_mode.max_duration_seconds:
		SignalsManager.game.emit_game_finish()

		# When Python is driving training, the next match's parameters come from
		# Python's next "reset" message (see AgentSynchronizer._start_new_match)
		# instead of an immediate auto-restart with the same config.
		if not AgentSynchronizer.is_python_training():
			SignalsManager.game.emit_game_reset()


func get_observation_informations(caller : Cuboid) -> Dictionary:
	var dictionary : Dictionary

	dictionary["timer"] = timer / game_mode.max_duration_seconds
	dictionary["score"] = 0

	return dictionary


func get_timer() -> float:
	return clampf(timer / game_mode.max_duration_seconds, 0.0, 1.0)


func _on_game_mode_set(new_game_mode : GameMode):
	game_mode = new_game_mode
	timer_label.text = "%0.1f" % game_mode.max_duration_seconds


func _on_team_initialized(team : Team):
	score[team] = 0


func _on_start_next_point():
	is_post_goal = false
	timer = 0


func _on_game_reset():
	is_post_goal = false
	timer = 0
	
	for team in score.keys():
		score[team] = 0


func _on_ball_enter_goal(receiving_team : Team):
	if is_post_goal == true:
		return
	
	is_post_goal = true
	SignalsManager.goal.emit_goal_scored(receiving_team)
	
	for team : Team in score.keys():
		if team != receiving_team:
			score[team] += 1
			if score[team] >= game_mode.max_goal:
				SignalsManager.game.emit_game_finish()


func _on_goal_animation_finished():
	for team : Team in score.keys():
		if score[team] >= game_mode.max_goal:
			if not AgentSynchronizer.is_python_training():
				SignalsManager.game.emit_game_reset()
			return

	SignalsManager.game.emit_start_next_point()
