extends Node
class_name GameStateManager

@export var timer_label : Label

var game_mode : GameMode
var score : Dictionary[Team, int]
var timer : float
var is_post_goal : bool = false

var pending_goal_events: Array = []

static var instance : GameStateManager


func _init() -> void:
	instance = self
	
	SignalsManager.game.game_mode_set.connect(_on_game_mode_set)
	SignalsManager.goal.ball_enter_goal.connect(_on_ball_enter_goal)
	SignalsManager.goal.goal_animation_finish.connect(_on_goal_animation_finished)
	SignalsManager.team.team_initialized.connect(_on_team_initialized)
	SignalsManager.game.start_next_point.connect(_on_start_next_point)
	SignalsManager.game.game_reset.connect(_on_game_reset)
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)
	SignalsManager.game.game_finish.connect(_on_game_finished)


func _ready() -> void:
	SignalsManager.agent.emit_environment_initialized(self)


func _process(delta: float) -> void:
	timer += delta
	
	if timer_label != null:
		timer_label.text = "%0.1f" % (game_mode.max_duration_seconds - timer)
	
	if timer >= game_mode.max_duration_seconds:
		SignalsManager.game.emit_game_finish()

		# When Python is driving training, the next match's parameters come from
		# Python's next "reset" message (see PythonSynchronizer._start_new_match)
		# instead of an immediate auto-restart with the same config.
		if AgentsManager.instance.agent_control_mode != AgentsManager.AgentControlModes.TRAINING:
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
	if timer_label != null:
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
	
	if SettingsManager.instance.disable_goal_animation == true:
		check_game_reset()


func check_game_reset():
	for team : Team in score.keys():
		if score[team] >= game_mode.max_goal:
			if AgentsManager.instance.agent_control_mode != AgentsManager.AgentControlModes.TRAINING:
				SignalsManager.game.emit_game_reset()
			return
	
	SignalsManager.game.emit_start_next_point()


func _on_goal_animation_finished():
	check_game_reset()


func _on_goal_scored(receiving_team: Team):
	pending_goal_events.append({"receiving_team_name": receiving_team.name})


func _on_game_finished():
	SignalsManager.agent.emit_episode_done()


func get_training_info() -> Dictionary:
	var entities : Array = []
	for entity in EntityManager.instance.entity_list:
		entities.append(entity.get_state_dictionary())

	var goals : Dictionary = {}
	for goal in Level.instance.goal_list:
		var goal_position : Vector3 = goal.global_position
		goals[goal.team.name] = [goal_position.x, goal_position.y, goal_position.z]

	var goal_events : Array = pending_goal_events
	pending_goal_events = []

	var level_size : Vector3 = game_mode.level_size
	var max_steps : int = ceili(game_mode.max_duration_seconds * Engine.physics_ticks_per_second / AgentsManager.instance.action_repeat)
	return {
		"entities": entities,
		"goals": goals,
		"goal_events": goal_events,
		"level_size": [level_size.x, level_size.y, level_size.z],
		"max_steps": max_steps,
	}
