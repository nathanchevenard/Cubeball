@tool
extends CubeballRaycast
class_name GoalRaycast


func get_ray_additional_data(ray : RayCast3D) -> float:
	if ray.is_colliding() == false:
		return 0.0
	
	if ray.get_collider() is Goal:
		var collider_goal : Goal = ray.get_collider() as Goal
		if cuboid.team == collider_goal.team:
			return 1.0
		else:
			return -1.0
	
	return 0.0
