extends Control
class_name GoalScoredUi

@export var show_time : float = 3
@export var white_flash_panel : Control


func _init() -> void:
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)


func _ready() -> void:
	hide()


func _on_goal_scored(_receiving_team : Team):
	if AgentSynchronizer.instance.control_mode == AgentSynchronizer.ControlModes.TRAINING:
		SignalsManager.goal.emit_goal_animation_finish()
		return
	
	scale = 3 * Vector2.ONE
	white_flash_panel.modulate = Color(1, 1, 1, 1)
	
	var tween : Tween = get_tree().create_tween()
	#tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(white_flash_panel, "modulate", Color(1, 1, 1, 0), 0.4)
	show()
	
	await get_tree().create_timer(show_time).timeout
	
	tween = get_tree().create_tween()
	await tween.tween_property(self, "scale", Vector2.ZERO, 0.2).finished
	hide()
	
	SignalsManager.goal.emit_goal_animation_finish()
