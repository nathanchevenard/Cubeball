extends StaticBody3D
class_name Wall

@export var collision_shape : CollisionShape3D
@export var csg_combiner : CSGCombiner3D
@export var csg_box : CSGBox3D


func is_on_ground(_checked_collisions : Array[PhysicsEntity] = []) -> bool:
	return is_in_group("ground")


func set_layer_wall():
	set_collision_layer_value(6, false)
	set_collision_layer_value(3, true)
