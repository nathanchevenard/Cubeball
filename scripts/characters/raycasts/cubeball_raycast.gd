@tool
extends RayCastSensor3D
class_name CubeballRaycast

@export var ray_color : Color:
	get:
		return ray_color
	set(value):
		ray_color = value
		_update()

@export var cuboid : Cuboid
@export var display_raycasts_colliding : bool = false
@export var display_raycasts_not_colliding : bool = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() == false:
		calculate_raycasts()
		#print(name + " : " + str(calculate_raycasts()))


func _spawn_nodes():
	super()
	
	for ray in rays:
		ray.debug_shape_custom_color = ray_color


func calculate_raycasts() -> Array:
	var result = []
	for ray : RayCast3D in rays:
		ray.set_enabled(true)
		ray.force_raycast_update()
		var distance = _get_raycast_distance(ray)
		result.append(distance)
		
		add_ray_additional_data(ray, result)
		
		if display_raycasts_colliding == true && ray.is_colliding() == true:
			var start = ray.global_position
			var end = ray.get_collision_point()
			DebugDraw3D.draw_line(start, end, ray_color)
		if display_raycasts_not_colliding == true && ray.is_colliding() == false:
			var start = ray.global_position
			var end = ray.target_position
			DebugDraw3D.draw_line(start, end, ray_color)
		
		ray.set_enabled(false)
	
	return result


# Element count of get_observation()'s result, known from the ray grid config alone —
# lets CuboidAIController.get_observation_space() compute a shape without needing an
# actual observation (and the live raycasts it requires) to exist yet.
func get_observation_size() -> int:
	return int(n_rays_width * n_rays_height)


func add_ray_additional_data(ray : RayCast3D, result : Array):
	pass
