extends Node
class_name EntityManager

static var instance : EntityManager

var entity_list : Array[PhysicsEntity]


func _init() -> void:
	instance = self
