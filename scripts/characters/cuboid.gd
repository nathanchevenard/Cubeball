extends PhysicsEntity
class_name Cuboid

const gravity : float = -9.81

var speed : float = 8
var rotation_speed : float = 3
var jump_force : float = 12

var jump_colliding_bodies : Array[Node3D]


func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("move_forward"):
		linear_velocity.x = speed * transform.basis.x.x
		linear_velocity.z = speed * transform.basis.x.z
	elif Input.is_action_pressed("move_back"):
		linear_velocity.x = -speed * transform.basis.x.x
		linear_velocity.z = -speed * transform.basis.x.z
	else:
		linear_velocity.x = 0
		linear_velocity.z = 0
	
	if Input.is_action_pressed("rotate_left"):
		angular_velocity.y = rotation_speed
	elif Input.is_action_pressed("rotate_right"):
		angular_velocity.y = -rotation_speed
	else:
		angular_velocity.y = 0
	
	if Input.is_action_just_pressed("jump") && is_on_ground():
		linear_velocity.y = jump_force


func is_on_ground(checked_collisions : Array[PhysicsEntity] = []) -> bool:
	checked_collisions.append(self)
	
	for body in jump_colliding_bodies:
		if body.is_in_group("ground") || body.is_on_ground(checked_collisions):
			return true
	
	return false


func _on_jump_detection_area_3d_body_entered(body: Node3D) -> void:
	if body != self:
		jump_colliding_bodies.append(body)


func _on_jump_detection_area_3d_body_exited(body: Node3D) -> void:
	jump_colliding_bodies.erase(body)
