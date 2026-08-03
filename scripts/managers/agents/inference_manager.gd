extends Node
class_name InferenceManager

@export var onnx_model_path : String = ""

static var instance : InferenceManager

var onnx_models: Dictionary
var onnx_model = null

var agent_inference_list: Array
var action_space_inference: Array[Dictionary] = []


func initialize_inference_agents(agents : Array):
	action_space_inference.clear()
	agent_inference_list = agents

	if agent_inference_list.size() > 0:
		assert(
			FileAccess.file_exists(onnx_model_path),
			"Onnx Model Path set on Sync node does not exist: %s" % onnx_model_path
		)
		if not onnx_models.has(onnx_model_path):
			onnx_models[onnx_model_path] = ONNXModel.new(onnx_model_path, 1)

		for agent in agent_inference_list:
			var action_space = agent.get_action_space()
			action_space_inference.append(action_space)

			var agent_onnx_model: ONNXModel
			if agent.onnx_model_path.is_empty():
				assert(
					onnx_models.has(onnx_model_path),
					(
						"Node %s has no onnx model path set " % agent.get_path()
						+ "and sync node's control mode is not set to OnnxInference. "
						+ "Either add the path to the AIController, "
						+ "or if you want to use the path set on sync node instead, "
						+ "set control mode to OnnxInference."
					)
				)
				prints(
					"Info: AIController %s" % agent.get_path(),
					"has no onnx model path set.",
					"Using path set on the sync node instead."
				)
				agent_onnx_model = onnx_models[onnx_model_path]
			else:
				if not onnx_models.has(agent.onnx_model_path):
					assert(
						FileAccess.file_exists(agent.onnx_model_path),
						(
							"Onnx Model Path set on %s node does not exist: %s"
							% [agent.get_path(), agent.onnx_model_path]
						)
					)
					onnx_models[agent.onnx_model_path] = ONNXModel.new(agent.onnx_model_path, 1)
				agent_onnx_model = onnx_models[agent.onnx_model_path]

			agent.onnx_model = agent_onnx_model


func _flatten_observation_dict(observation: Dictionary) -> Array:
	var keys = observation.keys()
	keys.sort()

	var result: Array = []
	for key in keys:
		var value = observation[key]
		if value is Array:
			result.append_array(value)
		else:
			result.append(value)
	return result


func _inference_process():
	if agent_inference_list.size() > 0:
		var observations: Array = _get_observations_from_agents(agent_inference_list)
		var actions = []

		for agent_id in range(0, agent_inference_list.size()):
			var model: ONNXModel = agent_inference_list[agent_id].onnx_model
			var flat_observation = _flatten_observation_dict(observations[agent_id])
			var raw_actions = model.run_inference(flat_observation)
			actions.append(_cast_onnx_actions(raw_actions, action_space_inference[agent_id]))

		_set_agent_actions(actions, agent_inference_list)
		_reset_agents_if_done(agent_inference_list)
		get_tree().set_pause(false)


func _cast_onnx_actions(raw_actions: Dictionary, action_space: Dictionary) -> Dictionary:
	var result = {}
	for key in action_space.keys():
		var action_type = action_space[key]["action_type"]
		if action_type == "discrete":
			result[key] = int(round(raw_actions[key][0]))
		else:
			result[key] = raw_actions[key]
	return result


func _reset_agents_if_done(agents):
	for agent in agents:
		if agent.get_done():
			agent.set_done_false()


func _get_observations_from_agents(agents: Array):
	var observations = []
	for agent in agents:
		observations.append(agent.get_observation())
	return observations


func _set_agent_actions(actions, agents: Array):
	for i in range(len(actions)):
		agents[i].set_action(actions[i])
