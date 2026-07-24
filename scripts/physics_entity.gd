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
	call_deferred("queue_free")


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


func get_state_dictionary() -> Dictionary:
	var dictionary : Dictionary
	dictionary["entity_type"] = EntityType.keys()[entity_type]
	dictionary["position"] = [global_position.x, global_position.y, global_position.z]
	dictionary["linear_velocity"] = [linear_velocity.x, linear_velocity.y, linear_velocity.z]

	return dictionary


func get_observation_informations(caller : Cuboid) -> Dictionary:
	var dictionary : Dictionary
	dictionary["type"] = entity_to_onehot(entity_type)
	dictionary["position"] = global_position / level.game_mode.level_size
	dictionary["rotation"] = global_rotation / (2 * PI)
	dictionary["linear_velocity"] = linear_velocity
	dictionary["angular_velocity"] = angular_velocity
	dictionary["distance_to_entity"] = (caller.global_position - global_position).length() / level.game_mode.level_size.length()
	dictionary["position_difference"] = (caller.global_position - global_position) / level.game_mode.level_size
	dictionary["angle_to_entity"] = projected_signed_angles(caller.transform.basis.z, (global_position - caller.global_position).normalized())
	dictionary["rotation_difference"] = (caller.global_rotation - global_rotation) / (2 * PI)
	
	return dictionary


func entity_to_onehot(entity_type_key : EntityType) -> Array[int]:
	var array : Array[int]
	
	for i in EntityType.keys().size():
		array.append(0)
	
	array[entity_type_key] = 1
	
	return array


static func signed_angle_2d(forward: Vector2, target: Vector2) -> float:
	if forward.is_zero_approx() or target.is_zero_approx():
		return 0.0
	return forward.angle_to(target)

static func signed_angle_2d_normalized(forward: Vector2, target: Vector2) -> float:
	return signed_angle_2d(forward, target) / PI

static func projected_signed_angles(forward: Vector3, target: Vector3) -> Vector3:
	var angle_xy = signed_angle_2d_normalized(
		Vector2(forward.x, forward.y),
		Vector2(target.x, target.y)
	)
	var angle_xz = signed_angle_2d_normalized(
		Vector2(forward.x, forward.z),
		Vector2(target.x, target.z)
	)
	var angle_yz = signed_angle_2d_normalized(
		Vector2(forward.y, forward.z),
		Vector2(target.y, target.z)
	)
	return Vector3(angle_xy, angle_xz, angle_yz)
