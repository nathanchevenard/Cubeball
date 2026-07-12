extends Control
class_name ScoreUI

@export var score_parent : Control
@export var text_theme : Theme

var team_to_label_dictionary : Dictionary[Team, Label]
var is_first_team : bool = true
var init_position : Vector2


func _init() -> void:
	SignalsManager.team.team_initialized.connect(_on_team_initialized)
	SignalsManager.team.all_teams_initialized.connect(_on_all_teams_initialized)
	SignalsManager.score.score_updated.connect(_on_score_updated)
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)
	SignalsManager.goal.goal_animation_finish.connect(_on_goal_animation_finished)


func update_score():
	var i : int = 0
	for team in team_to_label_dictionary.keys():
		team_to_label_dictionary[team].text = str(team.score)
		i += 1


func _on_team_initialized(team : Team):
	if is_first_team == false:
		var separator_label : Label = Label.new()
		add_child(separator_label)
		separator_label.theme = text_theme
		separator_label.text = "-"
	
	var label : Label = Label.new()
	add_child(label)
	label.theme = text_theme
	team_to_label_dictionary[team] = label
	is_first_team = false
	label.modulate = team.color


func _on_all_teams_initialized():
	update_score()


func _on_score_updated(_team : Team, _new_score : int):
	update_score()


func _on_goal_scored(_receiving_team : Team):
	init_position = global_position
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(score_parent, "global_position", global_position + Vector2(0, 150), 0.2)


func _on_goal_animation_finished():
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(score_parent, "global_position", init_position, 0.2)
