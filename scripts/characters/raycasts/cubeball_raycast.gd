@tool
extends RayCastSensor3D
class_name CubeballRaycast

@export var ray_color : Color:
	get:
		return ray_color
	set(value):
		ray_color = value

@export var cuboid : Cuboid
@export var display_raycasts_colliding : bool = false
@export var display_raycasts_not_colliding : bool = false


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() == false && (display_raycasts_colliding || display_raycasts_not_colliding):
		calculate_raycasts()
		#print(name + " : " + str(calculate_raycasts()))


func _spawn_nodes():
	super()
	
	for ray in rays:
		ray.debug_shape_custom_color = ray_color


func calculate_raycasts() -> Array:
	var result = []
	var space_state = get_world_3d().direct_space_state
	for local_direction in ray_directions:
		var hit = _cast_ray(local_direction, space_state)
		var distance = _get_raycast_distance(hit)
		result.append(distance)

		add_ray_additional_data(hit, result)

		if display_raycasts_colliding == true && hit.is_empty() == false:
			var start = global_transform.origin
			var end = hit["position"] as Vector3
			DebugDraw3D.draw_line(start, end, ray_color)
		if display_raycasts_not_colliding == true && hit.is_empty() == true:
			var start = global_transform.origin
			var end = start + (global_transform.basis * local_direction)
			DebugDraw3D.draw_line(start, end, ray_color)

	return result


# Element count of get_observation()'s result, known from the ray grid config alone —
# lets CuboidAIController.get_observation_space() compute a shape without needing an
# actual observation (and the live raycasts it requires) to exist yet.
func get_observation_size() -> int:
	return int(n_rays_width * n_rays_height)


func add_ray_additional_data(hit : Dictionary, result : Array):
	pass
