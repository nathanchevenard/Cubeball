@tool
extends ISensor3D
class_name RayCastSensor3D
@export_flags_3d_physics var collision_mask = 1:
	get:
		return collision_mask
	set(value):
		collision_mask = value
		
@export_flags_3d_physics var boolean_class_mask = 1:
	get:
		return boolean_class_mask
	set(value):
		boolean_class_mask = value
		

@export var n_rays_width := 6.0:
	get:
		return n_rays_width
	set(value):
		n_rays_width = value
		

@export var n_rays_height := 6.0:
	get:
		return n_rays_height
	set(value):
		n_rays_height = value
		

@export var ray_length := 10.0:
	get:
		return ray_length
	set(value):
		ray_length = value
		

@export var cone_width := 60.0:
	get:
		return cone_width
	set(value):
		cone_width = value
		

@export var cone_height := 60.0:
	get:
		return cone_height
	set(value):
		cone_height = value
		

@export var collide_with_areas := false:
	get:
		return collide_with_areas
	set(value):
		collide_with_areas = value
		

@export var collide_with_bodies := true:
	get:
		return collide_with_bodies
	set(value):
		collide_with_bodies = value
		

@export var class_sensor := false

var rays : Array[RayCast3D] = []
var geo = null

# Runtime-only ray directions (local space), used instead of spawning RayCast3D
# nodes so training doesn't pay for hundreds of Node3D instances per sensor.
var ray_directions : Array[Vector3] = []
var _ray_query : PhysicsRayQueryParameters3D


func _ready() -> void:
	if Engine.is_editor_hint() == false:
		_compute_ray_directions()


func _compute_ray_directions() -> void:
	ray_directions.clear()

	var horizontal_step = cone_width / (n_rays_width)
	var vertical_step = cone_height / (n_rays_height)

	var horizontal_start = horizontal_step / 2 - cone_width / 2
	var vertical_start = vertical_step / 2 - cone_height / 2

	for i in n_rays_width:
		for j in n_rays_height:
			var angle_w = horizontal_start + i * horizontal_step
			var angle_h = vertical_start + j * vertical_step
			ray_directions.append(to_spherical_coords(ray_length, angle_w, angle_h))


# Casts a single ray along a local-space direction using the physics server
# directly (no RayCast3D node involved). Reuses one query object across calls;
# space_state is fetched once per calculate_raycasts() call by the caller,
# not per ray.
func _cast_ray(local_direction: Vector3, space_state: PhysicsDirectSpaceState3D) -> Dictionary:
	if _ray_query == null:
		_ray_query = PhysicsRayQueryParameters3D.new()

	var origin = global_transform.origin
	_ray_query.from = origin
	_ray_query.to = origin + (global_transform.basis * local_direction)
	_ray_query.collision_mask = collision_mask
	_ray_query.collide_with_areas = collide_with_areas
	_ray_query.collide_with_bodies = collide_with_bodies

	return space_state.intersect_ray(_ray_query)


func _spawn_nodes():
	#print("spawning nodes")
	for ray in get_children():
		ray.queue_free()
	if geo:
		geo.clear()
	#$Lines.remove_points()
	rays = []

	var horizontal_step = cone_width / (n_rays_width)
	var vertical_step = cone_height / (n_rays_height)

	var horizontal_start = horizontal_step / 2 - cone_width / 2
	var vertical_start = vertical_step / 2 - cone_height / 2

	var points = []

	for i in n_rays_width:
		for j in n_rays_height:
			var angle_w = horizontal_start + i * horizontal_step
			var angle_h = vertical_start + j * vertical_step
			#angle_h = 0.0
			var ray = RayCast3D.new()
			var cast_to = to_spherical_coords(ray_length, angle_w, angle_h)
			ray.set_target_position(cast_to)

			points.append(cast_to)

			ray.set_name("node_" + str(i) + " " + str(j))
			ray.enabled = true
			ray.collide_with_bodies = collide_with_bodies
			ray.collide_with_areas = collide_with_areas
			ray.collision_mask = collision_mask
			add_child(ray)
			ray.set_owner(get_tree().edited_scene_root)
			rays.append(ray)
			ray.force_raycast
		
		


#    if Engine.editor_hint:
#        _create_debug_lines(points)


func _create_debug_lines(points):
	if not geo:
		geo = ImmediateMesh.new()
		add_child(geo)

	geo.clear()
	geo.begin(Mesh.PRIMITIVE_LINES)
	for point in points:
		geo.set_color(Color.AQUA)
		geo.add_vertex(Vector3.ZERO)
		geo.add_vertex(point)
	geo.end()


func display():
	if geo:
		geo.display()


func to_spherical_coords(r, inc, azimuth) -> Vector3:
	return Vector3(
		r * sin(deg_to_rad(inc)) * cos(deg_to_rad(azimuth)),
		r * sin(deg_to_rad(azimuth)),
		r * cos(deg_to_rad(inc)) * cos(deg_to_rad(azimuth))
	)


func get_observation() -> Array:
	return self.calculate_raycasts()


func calculate_raycasts() -> Array:
	var result = []
	var space_state = get_world_3d().direct_space_state
	for local_direction in ray_directions:
		var hit = _cast_ray(local_direction, space_state)
		var distance = _get_raycast_distance(hit)

		result.append(distance)
		if class_sensor:
			var hit_class: float = 0
			if hit.has("collider"):
				var hit_collision_layer = hit["collider"].collision_layer
				hit_collision_layer = hit_collision_layer & collision_mask
				hit_class = (hit_collision_layer & boolean_class_mask) > 0
			result.append(float(hit_class))
	return result


func _get_raycast_distance(hit: Dictionary) -> float:
	if hit.is_empty():
		return 0.0

	var distance = (global_transform.origin - (hit["position"] as Vector3)).length()
	distance = clamp(distance, 0.0, ray_length)
	return (ray_length - distance) / ray_length
