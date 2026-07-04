extends Node
class_name TeamsManager

@export var cuboid_scene : PackedScene

var team_list : Array[Team]


func _init() -> void:
	SignalsManager.level.level_initialized.connect(_on_level_initialized)
	SignalsManager.level.level_reset.connect(_on_level_resetted)
	SignalsManager.game.game_reset.connect(_on_game_reset)


func initialize_teams(level : Level):
	var is_first_cuboid : bool = true
	
	for game_mode_team in level.game_mode.team_list:
		var team : Team = game_mode_team.team
		team_list.append(team)
		team.initialize()
		
		for goal : Goal in level.goal_list:
			if goal.team == null:
				goal.team = team
				goal.wall_override_material.albedo_color = team.color
				break
		
		for i in game_mode_team.players_number:
			var cuboid : Cuboid = cuboid_scene.instantiate() as Cuboid
			cuboid.level = level
			add_child(cuboid)
			cuboid.set_team(team)
			SignalsManager.level.emit_level_spawn_node_at_random_pos(cuboid)
			cuboid.is_controlled = true
			
			#if OS.has_feature("editor") == true && is_first_cuboid == true:
				#is_first_cuboid = false
				#cuboid.is_controlled = true
				#
				#if DebugManager.instance.camera_on_cuboid == true:
					#cuboid.camera.current = true


func _on_level_initialized(level : Level):
	initialize_teams(level)
	
	SignalsManager.team.emit_all_teams_initialized()


func _on_game_reset():
	for team in team_list:
		team.set_score(0)


func _on_level_resetted(level : Level):
	for game_mode_team in level.game_mode.team_list:
		var team : Team = game_mode_team.team
		for cuboid in team.cuboid_list:
			SignalsManager.level.emit_level_spawn_node_at_random_pos(cuboid)
			cuboid.reset()
