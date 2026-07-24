extends AIController3D
class_name CuboidAIController

@export var raycast_list : Array[CubeballRaycast]
@export var print_observation : bool = false

var cuboid : Cuboid
var action_dictionary : Dictionary


func _init() -> void:
	SignalsManager.game.game_finish.connect(_on_game_finish)


func _ready():
	super()


func init(player: Node3D):
	super.init(player)
	cuboid = player as Cuboid


func _process(delta: float) -> void:
	if print_observation == true:
		print(get_observation_space())
		#print(get_observation())


func get_observation() -> Dictionary:
	var observation : Dictionary

	observation["timer"] = GameStateManager.instance.get_timer()
	observation["dash_cooldown"] = cuboid.get_dash_cooldown()

	for raycast in raycast_list:
		observation[raycast.name] = raycast.get_observation()

	#var dictionary : Dictionary
	#dictionary["self"] = cuboid.get_observation_informations(cuboid)
	#
	#var i : int = 1
	#for entity in EntityManager.instance.entity_list:
		#if entity == cuboid:
			#continue
		#
		#dictionary["entity_" + str(i)] = entity.get_observation_informations(cuboid)
	#
	#dictionary["game_state"] = GameStateManager.instance.get_observation_informations(cuboid)

	return observation


func get_observation_space() -> Dictionary:
	var observation_space : Dictionary
	observation_space["timer"] = {
		"size" : 1,
		"space" : "continuous",
	}
	observation_space["dash_cooldown"] = {
		"size" : 1,
		"space" : "continuous",
	}
	for raycast in raycast_list:
		observation_space[raycast.name] = {
			"size" : raycast.get_observation_size(),
			"space" : "continuous",
		}
	
	return observation_space

func get_action_space() -> Dictionary:
	var result : Dictionary = {
		"dash_action" : {
			"size" : 2,
			"action_type" : "discrete"
		},
		"jump_action" : {
			"size" : 2,
			"action_type" : "discrete"
		},
		"move_speed_coefficient" : {
			"size" : 1,
			"action_type" : "continuous"
		},
		"rotate_speed_coefficient" : {
			"size" : 1,
			"action_type" : "continuous"
		},
	}
	
	# Actions logit are returned in alphabetical order, so we make sure actions
	# are in the same order to match logits
	result.sort()
	
	return result


func set_action(action) -> void:
	#print("action : " + str(action))
	#print("action : " + str(action["dash_action"] == 1))
	action_dictionary = action


func _on_game_finish():
	done = true
