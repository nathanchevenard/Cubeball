extends Node
class_name TrainingManager

@export var speed_up : float = 1.0

static var instance : TrainingManager

const MAJOR_VERSION := "0"
const MINOR_VERSION := "8"
const DEFAULT_PORT := "11008"
const DEFAULT_SEED := "1"
var stream: StreamPeerTCP = null
var connected = false
var message_center
var should_connect = true
var pending_goal_events: Array = []

var agents_training: Dictionary
var agents_training_policy_names: Dictionary

var need_to_send_observation = false
var args = null
var initialized = false
var just_reset = false
var _pending_spaces = false
var debug_logs_enabled : bool = false

var current_level: Level


func _init() -> void:
	instance = self

	SignalsManager.level.level_initialized.connect(_on_level_initialized)
	SignalsManager.goal.goal_scored.connect(_on_goal_scored)


func initialize_communication() -> void:
	args = _get_args()
	debug_logs_enabled = args.get("debug_logs", "false") == "true"
	_set_seed()
	_set_action_repeat()
	Engine.physics_ticks_per_second = _get_speedup() * 60
	Engine.time_scale = _get_speedup() * 1.0
	_debug_log(
		"physics ticks %s %s %s %s"
		% [Engine.physics_ticks_per_second, Engine.time_scale, _get_speedup(), speed_up]
	)
	
	connected = connect_to_server()
	if connected:
		_handshake()
	else:
		push_warning(
			"Couldn't connect to Python server, using human controls instead. ",
			"Did you start the training server using e.g. `gdrl` from the console?"
		)


func _on_level_initialized(level: Level):
	current_level = level


func _on_goal_scored(receiving_team: Team):
	pending_goal_events.append({"receiving_team_name": receiving_team.name})


func _training_process():
	if connected:
		get_tree().set_pause(true)

		if _pending_spaces:
			_pending_spaces = false
			var spaces_reply = {
				"type": "spaces",
				"observation_space": _get_training_observation_spaces(),
				"action_space": _get_training_action_spaces(),
				"agent_policy_names": agents_training_policy_names,
			}
			_send_dict_as_json_message(spaces_reply)
			handle_message()
			return

		if just_reset:
			just_reset = false

			var reply = {
				"type": "reset",
				"observation": _get_training_observations(),
				"info": _get_training_info(),
			}
			_send_dict_as_json_message(reply)
			# this should go straight to getting the action and setting it checked the agent, no need to perform one phyics tick
			get_tree().set_pause(false)
			return

		if need_to_send_observation:
			need_to_send_observation = false
			var done = _get_training_dones()
			var observation = _get_training_observations()
			var info = _get_training_info()

			var reply = {"type": "step", "observation": observation, "done": done, "info": info}
			_send_dict_as_json_message(reply)

		var handled = handle_message()


func initialize_training_agents(agents : Array):
	for agent in agents:
		agents_training[agent.agent_id] = agent
		agents_training_policy_names[agent.agent_id] = agent.policy_name


func _handshake():
	_debug_log("performing handshake")

	var json_dict = _get_dict_json_message()
	assert(json_dict["type"] == "handshake")
	var major_version = json_dict["major_version"]
	var minor_version = json_dict["minor_version"]
	if major_version != MAJOR_VERSION:
		print("WARNING: major verison mismatch ", major_version, " ", MAJOR_VERSION)
	if minor_version != MINOR_VERSION:
		print("WARNING: minor verison mismatch ", minor_version, " ", MINOR_VERSION)

	_debug_log("handshake complete")


func _get_dict_json_message():
	# returns a dictionary from of the most recent message
	# this is not waiting

	# get_available_bytes() returns -1 (not 0) once the peer is gone — "<= 0" (not
	# "== 0") is required so a broken connection still enters this loop and gets
	# caught by the stream.get_status() check below. Missing this meant Godot never
	# noticed Python had disconnected and just error-looped forever without quitting.
	while stream.get_available_bytes() <= 0:
		stream.poll()
		if stream.get_status() != 2:
			print("server disconnected status, closing")
			get_tree().quit()
			return null

		OS.delay_usec(10)

	var message = stream.get_string()
	var json_data = JSON.parse_string(message)

	return json_data


func _send_dict_as_json_message(dict):
	stream.put_string(JSON.stringify(dict, "", false))


func connect_to_server():
	_debug_log("Waiting for one second to allow server to start")
	OS.delay_msec(1000)
	_debug_log("trying to connect to server")
	stream = StreamPeerTCP.new()

	# "localhost" was not working on windows VM, had to use the IP
	var ip = "127.0.0.1"
	var port = _get_port()
	var connect = stream.connect_to_host(ip, port)
	stream.set_no_delay(true)  # TODO check if this improves performance or not
	stream.poll()
	# Fetch the status until it is either connected (2) or failed to connect (3)
	while stream.get_status() < 2:
		stream.poll()
	return stream.get_status() == 2


func _get_args():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			# Options without an argument will be present in the dictionary,
			# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""

	return arguments


func _get_speedup():
	_debug_log(args)
	return args.get("speedup", str(speed_up)).to_float()


func _get_port():
	return args.get("port", DEFAULT_PORT).to_int()


func _set_seed():
	var _seed = args.get("env_seed", DEFAULT_SEED).to_int()
	seed(_seed)


func _set_action_repeat():
	AgentsManager.instance.action_repeat = args.get("action_repeat", str(AgentsManager.instance.action_repeat)).to_int()


func disconnect_from_server():
	stream.disconnect_from_host()


func _debug_log(message) -> void:
	if debug_logs_enabled:
		print(message)


func handle_message() -> bool:
	# get json message: reset, step, close
	var message = _get_dict_json_message()
	if message == null:
		# connection was already lost (see _get_dict_json_message), quit() was
		# already requested there, nothing left to handle
		return false

	if message["type"] == "close":
		print("received close message, closing game")
		get_tree().quit()
		get_tree().set_pause(false)
		return true

	if message["type"] == "reset":
		_debug_log("starting new match with config: %s" % [message["config"]])
		_start_new_episode(message["config"])
		just_reset = true
		get_tree().set_pause(false)
		return true

	if message["type"] == "get_spaces":
		_debug_log("discovering spaces with config: %s" % [message["config"]])
		_start_new_episode(message["config"])
		_pending_spaces = true
		get_tree().set_pause(false)
		return true

	if message["type"] == "action":
		_set_training_agent_actions(message["action"])
		need_to_send_observation = true
		get_tree().set_pause(false)
		return true

	print("message was not handled")
	return false


# Applies a new episode config pushed by Python (field size, ball/obstacle counts,
# duration, goal target, players per team) and rebuilds the arena and roster for it —
# used for every episode, including the first (see _ready(): training mode never builds
# anything until this runs for the first time).
func _start_new_episode(config : Dictionary) -> void:
	var new_game_mode : GameMode = GameModeManager.instance.create_game_mode(config)
	SignalsManager.game.emit_game_mode_set(new_game_mode)
	SignalsManager.game.emit_game_reset()


func _get_training_observation_spaces() -> Dictionary:
	var observation_spaces : Dictionary = {}
	for agent_id in agents_training:
		observation_spaces[agent_id] = agents_training[agent_id].get_observation_space()
	return observation_spaces


func _get_training_action_spaces() -> Dictionary:
	var action_spaces : Dictionary = {}
	for agent_id in agents_training:
		action_spaces[agent_id] = agents_training[agent_id].get_action_space()
	return action_spaces


func _get_training_observations() -> Dictionary:
	var observations : Dictionary = {}
	for agent_id in agents_training:
		observations[agent_id] = agents_training[agent_id].get_observation()
	return observations


func _get_training_info() -> Dictionary:
	var entities : Array = []
	for entity in EntityManager.instance.entity_list:
		entities.append(entity.get_state_dictionary())

	var goals : Dictionary = {}
	for goal in current_level.goal_list:
		var goal_position : Vector3 = goal.global_position
		goals[goal.team.name] = [goal_position.x, goal_position.y, goal_position.z]

	var goal_events : Array = pending_goal_events
	pending_goal_events = []

	var level_size : Vector3 = current_level.game_mode.level_size
	var max_steps : int = ceili(current_level.game_mode.max_duration_seconds * Engine.physics_ticks_per_second / AgentsManager.instance.action_repeat)
	return {
		"entities": entities,
		"goals": goals,
		"goal_events": goal_events,
		"level_size": [level_size.x, level_size.y, level_size.z],
		"max_steps": max_steps,
	}


func _get_training_dones() -> Dictionary:
	var dones : Dictionary = {}
	for agent_id in agents_training:
		var agent = agents_training[agent_id]
		var done = agent.get_done()
		if done:
			agent.set_done_false()
		dones[agent_id] = done
	return dones


func _set_training_agent_actions(actions : Dictionary) -> void:
	for agent_id in actions:
		if agents_training.has(agent_id):
			agents_training[agent_id].set_action(actions[agent_id])
