extends Node3D
class_name Level

@export var length : float
@export var width : float


func _ready() -> void:
	SignalsManager.level.emit_level_initialized(self)
