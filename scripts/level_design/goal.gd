extends Area3D
class_name Goal

@export var team : Team
@export var wall_scene : PackedScene
@export var wall_override_material : StandardMaterial3D
@export var wall_width : float = 1
@export var csg_box : CSGBox3D
@export var soft_body : SoftBody3D
@export var net_mesh : Mesh

var wall_csg_box_list : Array[CSGBox3D]


func initialize(spawn_scale):
	scale = spawn_scale
	scale_net(spawn_scale, global_position, global_rotation)
	
	# Floor Wall
	#var floor_wall : Wall = spawn_wall(Vector3(0, 0, 0), Vector3(PI, 0, 0), Vector3(spawn_scale.x, wall_width, spawn_scale.z) / scale)
	#floor_wall.add_to_group("ground")
	# Ceiling Wall
	#spawn_wall(Vector3(0, spawn_scale.y, 0) / scale, Vector3(0, 0, 0), Vector3(spawn_scale.x, wall_width, spawn_scale.z) / scale)
	# Back Wall
	#spawn_wall(Vector3(spawn_scale.x, 0, 0) / scale, Vector3(0, 0, 0), Vector3(wall_width, spawn_scale.y, spawn_scale.z) / scale)
	# Left Wall
	#spawn_wall(Vector3(0, 0, -spawn_scale.z / 2 - wall_width / 2) / scale, Vector3(0, 0, 0), Vector3(spawn_scale.x, spawn_scale.y, wall_width) / scale)
	# Right Wall
	#spawn_wall(Vector3(0, 0, spawn_scale.z / 2 + wall_width / 2) / scale, Vector3(0, 0, 0), Vector3(spawn_scale.x, spawn_scale.y, wall_width) / scale)
	
	if wall_override_material != null:
		csg_box.material = wall_override_material


func scale_net(spawn_scale : Vector3, spawn_position : Vector3, spawn_rotation : Vector3, pivot_local : Vector3 = Vector3.ZERO):
	# Si pivot_local est laissé à ZERO, on calcule le centre de masse
	if pivot_local == Vector3.ZERO:
		# Récupération de tous les sommets pour calculer le centre original
		var all_vertices = []
		var total_vertices = 0
		var min_y = 1e9
		var min_x = 1e9
		
		for surface_index in net_mesh.get_surface_count():
			var arrays = net_mesh.surface_get_arrays(surface_index)
			var vertices = arrays[Mesh.ARRAY_VERTEX]
			all_vertices.append(vertices)
			total_vertices += vertices.size()
			
			for i in range(vertices.size()):
				var v = vertices[i]
				if v.y < min_y:
					min_y = v.y
				if v.x < min_x:
					min_x = v.x
		
		var center = Vector3.ZERO
		for vertices_array in all_vertices:
			for v in vertices_array:
				center += v
		center /= total_vertices
		pivot_local = Vector3(0, min_y / 2, center.z)  # on utilise le centre de masse par défaut
	
	# Matrices
	var scale_matrix = Transform3D().scaled(spawn_scale / 4)
	var rotation_basis = Basis.from_euler(spawn_rotation + Vector3(0, PI, 0))
	
	var scaled_mesh = ArrayMesh.new()
	
	
	for surface_index in net_mesh.get_surface_count():
		var arrays = net_mesh.surface_get_arrays(surface_index)
		var vertices = arrays[Mesh.ARRAY_VERTEX]
		
		for i in range(vertices.size()):
			# 1. Décalage par rapport au pivot
			var v = vertices[i] - pivot_local
			# 2. Échelle autour du pivot
			v = scale_matrix * v
			# 3. Rotation autour du pivot
			v = rotation_basis * v
			# 4. Translation : le pivot se retrouve à spawn_position
			v = v + spawn_position
			
			vertices[i] = v
		
		arrays[Mesh.ARRAY_VERTEX] = vertices
		scaled_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	scaled_mesh.regen_normal_maps()
	
	if net_mesh.get_surface_count() > 0:
		scaled_mesh.surface_set_material(0, net_mesh.surface_get_material(0))
	
	soft_body.mesh = scaled_mesh
	soft_body.transform = Transform3D()  # identité car position/orientation déjà dans le mesh


func spawn_wall(spawn_position : Vector3, spawn_rotation : Vector3, spawn_scale : Vector3) -> Wall:
	var wall : Wall = wall_scene.instantiate() as Wall
	add_child(wall)
	wall.position = spawn_position
	wall.rotation = spawn_rotation
	wall.scale = spawn_scale
	
	if wall_override_material != null:
		wall.csg_box.material = wall_override_material
	
	wall_csg_box_list.append(wall.csg_box)
	
	return wall


func ball_enter_goal(ball : Ball):
	ball.current_colliding_goal = self


func _on_body_entered(body: Node3D) -> void:
	if body is Ball:
		ball_enter_goal(body)


func _on_body_exited(body: Node3D) -> void:
	if body is Ball:
		body.current_colliding_goal = null
