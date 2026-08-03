@tool
extends CubeballRaycast
class_name CuboidRaycast


func add_ray_additional_data(hit : Dictionary, result : Array):
	if hit.is_empty():
		result.append(0.0)
		result.append(0.0)
		return

	var collider = hit["collider"]
	if collider is Cuboid:
		var collider_cuboid : Cuboid = collider as Cuboid
		if cuboid.team == collider_cuboid.team:
			result.append(1.0)
		else:
			result.append(-1.0)
		result.append(collider_cuboid.get_dash_cooldown())
	else:
		result.append(0.0)
		result.append(0.0)


func get_observation_size() -> int:
	return int(n_rays_width * n_rays_height) * 3
