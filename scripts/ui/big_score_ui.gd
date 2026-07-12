extends Control
class_name BigScoreUI

@export var display_distance : float = 300
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
	tween.tween_property(label, "global_position", label_to_positions[label][1], 0.3)


func start_hide_phase(label : Label):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(label, "global_position", label_to_positions[label][0], 0.3)


func _on_all_teams_initialized():
	var screen_width : int = DisplayServer.screen_get_size().x
	
	var team_number : int = GameStateManager.instance.game_mode.team_list.size()
	for i in team_number:
		var team : Team = GameStateManager.instance.game_mode.team_list[i].team
		
		var angle : float = PI + i * 2 * PI / team_number
		var initial_position : Vector2 = global_position + screen_width * Vector2.from_angle(angle)
		var display_position : Vector2 = global_position + display_distance * Vector2.from_angle(angle)
		
		var label : Label = Label.new()
		label.pivot_offset_ratio = Vector2(0.5, 0.5)
		add_child(label)
		label.global_position = initial_position
		label.modulate = team.color
		label.theme = text_theme
		label.add_theme_font_size_override("font_size", 160)
		
		team_to_label[team] = label
		label_to_positions[label] = [initial_position, display_position]


func _on_goal_scored(_receiving_team : Team):
	for team : Team in team_to_label.keys():
		var label : Label = team_to_label[team]
		label.text = str(team.score)
		start_show_phase(label)
	
	await get_tree().create_timer(1.2).timeout
	
	for team : Team in team_to_label.keys():
		var label : Label = team_to_label[team]
		start_hide_phase(label)
