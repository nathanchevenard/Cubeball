extends Control
class_name BigScoreUI

@export var display_distance : float = 300
@export var show_time : float = 0.6
@export var middle_time : float = 0.6
@export var increase_score_time : float = 0.4
@export var text_theme : Theme

var team_to_label : Dictionary[Team, Label]
var label_to_positions : Dictionary[Label, Array]


func _init() -> void:
	SignalsManager.team.all_teams_initialized.connect(_on_all_teams_initialized)
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)


func start_show_phase(label : Label):
	var tween : Tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "position", label_to_positions[label][1], 0.3)


func start_hide_phase(label : Label):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(label, "position", label_to_positions[label][0], 0.3)


func increase_score(receiving_team : Team):
	var label : Label = team_to_label[receiving_team]
	var tween : Tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SPRING)
	await tween.tween_property(label, "scale", 1.5 * Vector2.ONE, 0.15).finished
	label.text = str(receiving_team.score)
	await get_tree().create_timer(increase_score_time).timeout
	tween = get_tree().create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.1)


func _on_all_teams_initialized():
	var screen_width : int = DisplayServer.screen_get_size().x
	
	var team_number : int = GameStateManager.instance.game_mode.team_list.size()
	for i in team_number:
		var team : Team = GameStateManager.instance.game_mode.team_list[i].team
		
		var label : Label = Label.new()
		label.pivot_offset_ratio = Vector2(0.5, 0.5)
		add_child(label)
		label.modulate = team.color
		label.theme = text_theme
		label.custom_minimum_size.x = 300
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 160)
		
		var angle : float = PI + i * 2 * PI / team_number
		var initial_position : Vector2 = screen_width * Vector2.from_angle(angle) - label.size / 2
		var display_position : Vector2 = display_distance * Vector2.from_angle(angle) - label.size / 2
		
		label.position = initial_position
		team_to_label[team] = label
		label_to_positions[label] = [initial_position, display_position]


func _on_goal_scored(receiving_team : Team):
	if AgentSynchronizer.instance.control_mode == AgentSynchronizer.ControlModes.TRAINING:
		return
	
	for team : Team in team_to_label.keys():
		var label : Label = team_to_label[team]
		var score : int = team.score
		label.text = str(score)
		label.scale = Vector2.ONE
		start_show_phase(label)
	
	await get_tree().create_timer(show_time).timeout
	
	for team : Team in team_to_label.keys():
		if team != receiving_team:
			increase_score(team)
	
	await get_tree().create_timer(middle_time).timeout
	
	for team : Team in team_to_label.keys():
		var label : Label = team_to_label[team]
		start_hide_phase(label)
