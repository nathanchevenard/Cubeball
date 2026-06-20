extends PhysicsEntity
class_name Cuboid

const gravity : float = -9.81

var speed : float = 8
var rotation_speed : float = 3
var jump_force : float = 10


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
		linear_velocity.y += jump_force
