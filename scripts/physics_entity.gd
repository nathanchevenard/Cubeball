extends RigidBody3D
class_name PhysicsEntity


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 10


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
