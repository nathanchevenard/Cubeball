extends RigidBody3D
class_name PhysicsEntity

enum EntityType {
	CUBOID = 0,
	BALL = 1,
	OBSTACLE = 2,
}

@export var entity_type : EntityType

var level : Level


func _ready() -> void:
	EntityManager.instance.entity_list.append(self)
	
	contact_monitor = true
	max_contacts_reported = 10


func destroy():
	EntityManager.instance.entity_list.erase(self)
	queue_free()


func is_on_ground(checked_collisions : Array[PhysicsEntity] = []) -> bool:
	var collisions : Array[Node3D] = get_colliding_bodies()
	
	for collision in collisions:
		if collision.is_in_group("ground"):
			return true
	
	checked_collisions.append(self)
	
	for collision in collisions:
		if collision is PhysicsEntity && checked_collisions.has(collision) == false:
			if collision.is_on_ground(checked_collisions) == true:
				return true
	
	return false


func reset():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func get_observation_informations(caller : Cuboid) -> Dictionary:
	var dictionary : Dictionary
	dictionary["type"] = entity_to_onehot(entity_type)
	dictionary["position"] = global_position / level.game_mode.level_size
	dictionary["rotation"] = global_rotation / (2 * PI)
	dictionary["linear_velocity"] = linear_velocity
	dictionary["angular_velocity"] = angular_velocity
	
	return dictionary


func entity_to_onehot(entity_type_key : EntityType) -> Array[int]:
	var array : Array[int]
	
	for i in EntityType.keys().size():
		array.append(0)
	
	array[entity_type_key] = 1
	
	return array
