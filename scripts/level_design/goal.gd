extends Area3D

@export var team : Team


func score_goal():
	SignalsManager.goal.emit_goal_scored(team)


func _on_body_entered(body: Node3D) -> void:
	if body is Ball:
		score_goal()
