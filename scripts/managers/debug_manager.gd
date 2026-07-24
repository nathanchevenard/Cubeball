extends Node
class_name DebugManager

@export var first_cuboid_human_input : bool
@export var goal_animation : bool = true

static var instance : DebugManager


func _init() -> void:
	if OS.has_feature("editor") == true:
		instance = self
		
		SignalsManager.team.all_teams_initialized.connect(_on_all_teams_initialized)
	else:
		queue_free()


func _ready() -> void:
	if PythonSynchronizer.instance.control_mode == PythonSynchronizer.ControlModes.TRAINING:
		goal_animation = false


func _on_all_teams_initialized():
	if OS.has_feature("editor") == true && first_cuboid_human_input == true:
		if EntityManager.instance.cuboid_list.size() > 0:
			var cuboid : Cuboid = EntityManager.instance.cuboid_list[0]
			cuboid.set_control_mode_human()
