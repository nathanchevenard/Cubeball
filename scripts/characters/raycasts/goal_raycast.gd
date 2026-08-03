@tool
extends CubeballRaycast
class_name GoalRaycast


func add_ray_additional_data(hit : Dictionary, result : Array):
	if hit.is_empty():
		result.append(0.0)
		return

	var collider = hit["collider"]
	if collider is Goal:
		var collider_goal : Goal = collider as Goal
		if cuboid.team == collider_goal.team:
			result.append(1.0)
		else:
			result.append(-1.0)
	else:
		result.append(0.0)


func get_observation_size() -> int:
	return int(n_rays_width * n_rays_height) * 2
