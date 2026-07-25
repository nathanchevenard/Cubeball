extends Control
class_name TimerUI

var init_position : Vector2


func _init() -> void:
	SignalsManager.settings.ui_disable.connect(_on_ui_disabled)
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)
	SignalsManager.goal.goal_animation_finish.connect(_on_goal_animation_finished)


func _on_ui_disabled():
	call_deferred("queue_free")


func _on_goal_scored(_receiving_team : Team):
	if SettingsManager.instance.disable_goal_animation == true:
		return
	
	init_position = global_position
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", global_position + Vector2(0, -150), 0.2)


func _on_goal_animation_finished():
	if SettingsManager.instance.disable_goal_animation == true:
		return
	
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", init_position, 0.2)
