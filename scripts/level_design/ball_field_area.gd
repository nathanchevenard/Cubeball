extends Node3D
class_name BallFieldArea


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Ball && (body as Ball).current_colliding_goal != null:
		var ball : Ball = body as Ball
		SignalsManager.goal.emit_ball_enter_goal(ball.current_colliding_goal.team)
