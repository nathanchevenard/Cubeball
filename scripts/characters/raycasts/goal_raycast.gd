@tool
extends CubeballRaycast
class_name GoalRaycast


func add_ray_additional_data(ray : RayCast3D, result : Array):
	if ray.is_colliding() == false:
		result.append(0.0)
		return
	
	if ray.get_collider() is Goal:
		var collider_goal : Goal = ray.get_collider() as Goal
		if cuboid.team == collider_goal.team:
			result.append(1.0)
		else:
			result.append(-1.0)
	else:
		result.append(0.0)


func get_observation_size() -> int:
	return int(n_rays_width * n_rays_height) * 2
