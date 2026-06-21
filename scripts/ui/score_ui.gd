extends Control
class_name ScoreUI

@export var font_size : int = 35

var team_to_label_dictionary : Dictionary[Team, Label]


func _init() -> void:
	SignalsManager.team.team_initialized.connect(_on_team_initialized)
	SignalsManager.team.all_teams_initialized.connect(_on_all_teams_initialized)
	SignalsManager.score.score_updated.connect(_on_score_updated)


func update_score():
	var i : int = 0
	for team in team_to_label_dictionary.keys():
		team_to_label_dictionary[team].text = ""
		
		if i > 0:
			team_to_label_dictionary[team].text = " - "
		
		team_to_label_dictionary[team].text += str(team.score)
		i += 1


func _on_team_initialized(team : Team):
	var label : Label = Label.new()
	add_child(label)
	label.add_theme_font_size_override("font_size", font_size)
	team_to_label_dictionary[team] = label


func _on_all_teams_initialized():
	update_score()


func _on_score_updated(_team : Team, _new_score : int):
	update_score()
