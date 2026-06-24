extends Node
class_name DebugManager

@export var camera_on_cuboid : bool

static var instance : DebugManager


func _init() -> void:
	if OS.has_feature("editor") == true:
		instance = self
	else:
		queue_free()
