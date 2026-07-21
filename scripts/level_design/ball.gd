extends PhysicsEntity
class_name Ball

@export var air_resistance : float = 0.1
@export var friction : float = 10
@export var maximum_speed : float = 50

var current_colliding_goal : Goal


func _physics_process(delta: float) -> void:
	var new_speed = linear_velocity.length() / (1 + linear_velocity.length() * air_resistance * delta)
	linear_velocity = linear_velocity.normalized() * new_speed
	
	if is_on_ground():
		var normalized_velocity = linear_velocity.normalized()
		
		if linear_velocity.x > 0:
			linear_velocity.x = max(0, linear_velocity.x - normalized_velocity.x * friction * delta)
		elif linear_velocity.x < 0:
			linear_velocity.x = min(0, linear_velocity.x - normalized_velocity.x * friction * delta)
		if linear_velocity.z > 0:
			linear_velocity.z = max(0, linear_velocity.z - normalized_velocity.z * friction * delta)
		elif linear_velocity.z < 0:
			linear_velocity.z = min(0, linear_velocity.z - normalized_velocity.z * friction * delta)
		
		#if linear_velocity.length() > maximum_speed:
			#linear_velocity = maximum_speed * linear_velocity.normalized()
