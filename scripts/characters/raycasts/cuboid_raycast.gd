@tool
extends CubeballRaycast
class_name CuboidRaycast


func add_ray_additional_data(ray : RayCast3D, result : Array):
	if ray.is_colliding() == false:
		result.append(0.0)
		result.append(0.0)
		return
	
	if ray.get_collider() is Cuboid:
		var collider_cuboid : Cuboid = ray.get_collider() as Cuboid
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
