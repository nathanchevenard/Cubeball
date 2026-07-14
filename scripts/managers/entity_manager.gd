extends Node
class_name EntityManager

static var instance : EntityManager

var entity_list : Array[PhysicsEntity]
var cuboid_list : Array[Cuboid]


func _init() -> void:
	instance = self
