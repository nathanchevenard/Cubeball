extends AIController3D
class_name CuboidAIController

@export var print_obs : bool = false

var cuboid : Cuboid

var dash_action : bool = false
var jump_action : bool = false
var move_back_action : bool = false
var move_forward_action : bool = false
var rotate_left_action : bool = false
var rotate_right_action : bool = false


func _init() -> void:
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)


func _ready():
	super()
	if OS.has_feature("editor") == true:
		control_mode = AIController3D.ControlModes.HUMAN


func init(player: Node3D):
	super.init(player)
	cuboid = player as Cuboid


func _process(delta: float) -> void:
	if print_obs == true:
		print(get_obs())


func get_obs() -> Dictionary:
	var dictionary : Dictionary
	
	dictionary["self"] = cuboid.get_observation_informations(cuboid)
	
	var i : int = 1
	for entity in EntityManager.instance.entity_list:
		if entity == cuboid:
			continue
		
		dictionary["entity_" + str(i)] = entity.get_observation_informations(cuboid)
	
	dictionary["game_state"] = GameStateManager.instance.get_observation_informations(cuboid)
	
	return { "obs" : dictionary }


func get_reward() -> float:
	return reward


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
		"move_back_action" : {
			"size" : 2,
			"action_type" : "discrete"
		},
		"move_forward_action" : {
			"size" : 2,
			"action_type" : "discrete"
		},
		"rotate_left_action" : {
			"size" : 2,
			"action_type" : "discrete"
		},
		"rotate_right_action" : {
			"size" : 2,
			"action_type" : "discrete"
		},
	}
	
	# Actions logit are returned in alphabetical order, so we make sure actions
	# are in the same order to match logits
	result.sort()
	
	return result


func set_action(action) -> void:
	dash_action = action["dash_action"] == 1
	jump_action = action["jump_action"] == 1
	move_back_action = action["move_back_action"] == 1
	move_forward_action = action["move_forward_action"] == 1
	rotate_left_action = action["rotate_left_action"] == 1
	rotate_right_action = action["rotate_right_action"] == 1


func _on_goal_scored(receiving_team : Team):
	if receiving_team == cuboid.team:
		reward -= 1
	else:
		reward += 1
