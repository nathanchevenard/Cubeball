@tool
extends CubeballRaycast
class_name CuboidRaycast


func get_ray_additional_data(ray : RayCast3D) -> float:
	if ray.is_colliding() == false:
		return 0.0
	
	if ray.get_collider() is Cuboid:
		var collider_cuboid : Cuboid = ray.get_collider() as Cuboid
		if cuboid.team == collider_cuboid.team:
			return 1.0
		else:
			return -1.0
	
	return 0.0
