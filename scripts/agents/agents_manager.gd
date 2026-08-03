extends Node
class_name AgentsManager

enum AgentControlModes { HUMAN, TRAINING, ONNX_INFERENCE }
@export var agent_control_mode: AgentControlModes = AgentControlModes.TRAINING
@export var action_repeat : int = 8

@export var inference_manager : InferenceManager
@export var training_manager : TrainingManager

static var instance : AgentsManager

var agent_list : Array
var n_action_steps : int = 0


func _init() -> void:
	instance = self
	
	SignalsManager.agent.all_agents_initialized.connect(_on_all_agents_initialized)
	
	if OS.has_feature("editor") == true && agent_control_mode == AgentControlModes.TRAINING:
		agent_control_mode = AgentControlModes.ONNX_INFERENCE


func _ready() -> void:
	if agent_control_mode == AgentControlModes.TRAINING:
		training_manager.initialize_communication()


func _on_all_agents_initialized():
	get_agents()
	
	if agent_control_mode == AgentControlModes.TRAINING:
		training_manager.initialize_training_agents(agent_list)
	elif agent_control_mode == AgentControlModes.ONNX_INFERENCE:
		inference_manager.initialize_inference_agents(agent_list)


func get_agents():
	agent_list = get_tree().get_nodes_in_group("AGENT")
	
	for agent in agent_list:
		if agent_control_mode == AgentControlModes.TRAINING:
			agent.control_mode = agent.ControlModes.TRAINING
		elif agent_control_mode == AgentControlModes.ONNX_INFERENCE:
			agent.control_mode = agent.ControlModes.ONNX_INFERENCE
	
	print("found %d nodes in AGENT group" % [agent_list.size()])


func _physics_process(_delta):
	if n_action_steps % action_repeat != 0:
		n_action_steps += 1
		return

	n_action_steps += 1

	if agent_control_mode == AgentControlModes.TRAINING:
		training_manager._training_process()
	elif agent_control_mode == AgentControlModes.ONNX_INFERENCE:
		inference_manager._inference_process()
