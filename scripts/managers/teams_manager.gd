extends Node
class_name TeamsManager

@export var team_list : Array[Team]
@export var team_size : int = 1
@export var cuboid_scene : PackedScene


func _init() -> void:
	SignalsManager.level.level_initialized.connect(_on_level_initialized)


func initialize_teams(level : Level):
	var is_first_cuboid : bool = true
	
	for team in team_list:
		team.initialize()
		
		for i in team_size:
			var cuboid : Cuboid = cuboid_scene.instantiate() as Cuboid
			add_child(cuboid)
			cuboid.set_team(team)
			var random_x : float = randf_range((-level.size_x / 2), (level.size_x / 2))
			var random_z : float = randf_range((-level.size_z / 2), (level.size_z / 2))
			cuboid.global_position = Vector3(random_x, 0, random_z)
			
			if OS.has_feature("editor") == true && is_first_cuboid == true:
				is_first_cuboid = false
				cuboid.is_controlled = true


func _on_level_initialized(level : Level):
	initialize_teams(level)
	
	SignalsManager.team.emit_all_teams_initialized()
