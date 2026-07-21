extends Node
class_name EntityManager

static var instance : EntityManager

var entity_list : Array[PhysicsEntity]
var cuboid_list : Array[Cuboid]
var ball_list : Array[Ball]


func _init() -> void:
	instance = self
