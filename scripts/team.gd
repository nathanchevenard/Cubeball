extends Resource
class_name Team

@export var name : String
@export var color : Color

var score : int = 0
var cuboid_list : Array[Cuboid]


func initialize():
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)
	SignalsManager.team.emit_team_initialized(self)


func set_score(value : int):
	score = value
	SignalsManager.score.emit_score_updated(self, score)


func add_score(value : int):
	score += value
	SignalsManager.score.emit_score_updated(self, score)


func _on_goal_scored(receiving_team : Team):
	if receiving_team != self:
		add_score(1)
