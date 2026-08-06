extends Node3D
class_name AIController3D

@export var onnx_data : OnnxData
@export var policy_name: String = "shared_policy"

var onnx_model: ONNXModel

var done := false
var agent_id := ""


func _init() -> void:
	SignalsManager.agent.episode_done.connect(_on_episode_done)


func _ready():
	add_to_group("AGENT")


#-- Methods that need implementing using the "extend script" option in Godot --#
func get_observation() -> Dictionary:
	assert(false, "the get_observation method is not implemented when extending from ai_controller")
	return {"observation": []}


func get_action_space() -> Dictionary:
	assert(
		false,
		"the get_action_space method is not implemented when extending from ai_controller"
	)
	return {
		"example_actions_continous": {"size": 2, "action_type": "continuous"},
		"example_actions_discrete": {"size": 2, "action_type": "discrete"},
	}


func set_action(action) -> void:
	assert(false, "the set_action method is not implemented when extending from ai_controller")


#-- Methods that sometimes need implementing using the "extend script" option in Godot --#
# Only needed if you are recording expert demos with this AIController
func get_action() -> Array:
	assert(false, "the get_action method is not implemented in extended AIController but demo_recorder is used")
	return []


func get_observation_space():
	# may need overriding if the observation space is complex
	var observation = get_observation()
	return {
		"observation": {"size": [len(observation["observation"])], "space": "box"},
	}


func _on_episode_done():
	done = true
