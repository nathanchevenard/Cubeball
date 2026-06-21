extends Node
class_name TeamsManager

@export var team_list : Array[Team]


func _ready() -> void:
	for team in team_list:
		team.initialize()
	
	SignalsManager.team.emit_all_teams_initialized()
