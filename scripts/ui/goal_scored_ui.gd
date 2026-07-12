extends Control
class_name GoalScoredUI

@export var show_time : float = 0.2
@export var middle_time : float = 1.3
@export var hide_time : float = 0.2
@export var shake_amplitude : float = 5
@export var shake_time : float = 0.1
@export var shake_count : int = 10
@export var white_flash_panel : Control

var init_position : Vector2


func _init() -> void:
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)


func _ready() -> void:
	init_position = position
	hide()


func _on_goal_scored(_receiving_team : Team):
	if AgentSynchronizer.instance.control_mode == AgentSynchronizer.ControlModes.TRAINING:
		SignalsManager.goal.emit_goal_animation_finish()
		return
	
	await start_show_phase()
	await start_middle_phase()
	await start_hide_phase()
	
	SignalsManager.goal.emit_goal_animation_finish()


func start_show_phase():
	scale = 3 * Vector2.ONE
	white_flash_panel.modulate = Color(1, 1, 1, 1)
	
	var tween : Tween = get_tree().create_tween()
	#tween.set_trans(Tween.TRANS_SPRING)
	tween.tween_property(self, "scale", Vector2.ONE, show_time)
	tween.parallel().tween_property(white_flash_panel, "modulate", Color(1, 1, 1, 0), show_time * 2)
	show()
	
	await get_tree().create_timer(show_time).timeout


func start_middle_phase():
	start_shake()
	await get_tree().create_timer(middle_time).timeout


func start_hide_phase():
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(white_flash_panel, "modulate", Color(1, 1, 1, 1), hide_time)
	tween.parallel().tween_property(self, "scale", Vector2(scale.x + 1, 0), hide_time)
	
	await get_tree().create_timer(hide_time).timeout
	hide()


func start_shake():
	var tween : Tween = get_tree().create_tween()
	for i in shake_count:
		tween.tween_property(self, "position", init_position + Vector2(randf_range(-shake_amplitude, shake_amplitude), randf_range(-shake_amplitude, shake_amplitude)), shake_time)
	tween.tween_property(self, "position", init_position, shake_time)
