extends Node
class_name SettingsManager

@export var first_cuboid_human_input : bool
@export var disable_goal_animation : bool = false
@export var disable_ui : bool = false
@export var disable_goal_nets : bool = false
@export var disable_cameras : bool = false

static var instance : SettingsManager


func _init() -> void:
	instance = self
	
	SignalsManager.team.all_teams_initialized.connect(_on_all_teams_initialized)


func _ready() -> void:
	if PythonSynchronizer.instance.control_mode == PythonSynchronizer.ControlModes.TRAINING:
		disable_goal_animation = true
		disable_ui = true
		disable_goal_nets = true
		#disable_cameras = true
	
	if disable_goal_animation == true:
		SignalsManager.settings.emit_goal_animation_disable()
	if disable_ui == true:
		SignalsManager.settings.emit_ui_disable()
	if disable_goal_nets == true:
		SignalsManager.settings.emit_goal_nets_disable()
	if disable_cameras == true:
		SignalsManager.settings.emit_cameras_disable()


func _on_all_teams_initialized():
	if OS.has_feature("editor") == true && first_cuboid_human_input == true:
		if EntityManager.instance.cuboid_list.size() > 0:
			var cuboid : Cuboid = EntityManager.instance.cuboid_list[0]
			cuboid.set_control_mode_human()
