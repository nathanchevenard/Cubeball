extends PhysicsEntity
class_name Cuboid

enum InputMode {
	HUMAN,
	AI,
}

@export var input_mode : InputMode = InputMode.AI

@export var speed : float = 8
@export var rotation_speed : float = 3
@export var rotation_speed_keyboard_coefficient : float = 0.8
@export var jump_force : float = 12

@export var dash_force : float = 10
@export var dash_cooldown : float = 2
@export var dash_duration : float = 1

@export var cuboid_ai_controller : CuboidAIController

@export var behind_phantom_camera : PhantomCamera3D
@export var mouse_sensitivity: float = 1.0/40.0

var team : Team
var jump_colliding_bodies : Array[Node3D]
var dash_timer : float = 0
var is_dashing : bool = false
var rotation_speed_coefficient : float

var free_phantom_camera : PhantomCamera3D

var inputs : Dictionary[String, bool]
static var possible_move_list : Array[String] = [
	"move_forward",
	"move_back",
	"rotate_left",
	"rotate_right",
	"jump",
	"dash",
]

signal color_changed(color : Color)


func _ready() -> void:
	super()
	
	EntityManager.instance.cuboid_list.append(self)
	cuboid_ai_controller.init(self)


# queue_free() (called by PhysicsEntity.destroy) only actually removes the node at the
# end of the frame — but TeamsManager destroys the previous episode's cuboids and spawns
# the new roster within the same synchronous call chain, so PythonSynchronizer's
# `get_tree().get_nodes_in_group("AGENT")` would otherwise still see the about-to-be-freed
# ones moments later, colliding with the new roster's agent_id and leaving stale node
# references in agents_training. Removing from the group immediately avoids that.
func destroy() -> void:
	cuboid_ai_controller.remove_from_group("AGENT")
	EntityManager.instance.cuboid_list.erase(self)
	
	if team != null:
		team.cuboid_list.erase(self)
	
	super.destroy()


func _physics_process(delta: float) -> void:
	inputs = get_inputs()
	handle_inputs(delta)


func _unhandled_input(event: InputEvent) -> void:
	if input_mode == InputMode.HUMAN && event is InputEventMouseMotion\
	&& CameraManager.instance.camera_mode == CameraManager.CameraMode.BEHIND:
		if event.relative.x > 2:
			inputs["rotate_right"] = true
			rotation_speed_coefficient = clampf(-event.relative.x * mouse_sensitivity, -1.0, 1.0)
		elif event.relative.x < -2:
			inputs["rotate_left"] = true
			rotation_speed_coefficient = clampf(-event.relative.x * mouse_sensitivity, -1.0, 1.0)


func get_inputs() -> Dictionary[String, bool]:
	match input_mode:
		InputMode.HUMAN:
			for possible_move : String in possible_move_list:
				set_human_input(possible_move)
		InputMode.AI:
			inputs["move_forward"] = cuboid_ai_controller.move_forward_action
			inputs["move_back"] = cuboid_ai_controller.move_back_action
			inputs["rotate_left"] = cuboid_ai_controller.rotate_left_action
			inputs["rotate_right"] = cuboid_ai_controller.rotate_right_action
			inputs["jump"] = cuboid_ai_controller.jump_action
			inputs["dash"] = cuboid_ai_controller.dash_action
	
	return inputs


func set_human_input(input : String):
	var value : bool = Input.is_action_pressed(input)
	if value == true:
		inputs[input] = value
	
	if input == "rotate_right" && value == true:
		rotation_speed_coefficient = -1 * rotation_speed_keyboard_coefficient
	elif input == "rotate_left" && value == true:
		rotation_speed_coefficient = 1 * rotation_speed_keyboard_coefficient


func handle_inputs(delta : float):
	if is_dashing == false:
		if inputs.has("move_forward") && inputs["move_forward"] == true:
			linear_velocity.x = speed * transform.basis.z.x
			linear_velocity.z = speed * transform.basis.z.z
		elif inputs.has("move_back") && inputs["move_back"] == true:
			linear_velocity.x = -speed * transform.basis.z.x
			linear_velocity.z = -speed * transform.basis.z.z
		else:
			linear_velocity.x = 0
			linear_velocity.z = 0
		
		if inputs.has("rotate_left") && inputs["rotate_left"] == true:
			angular_velocity.y = rotation_speed * rotation_speed_coefficient
		elif inputs.has("rotate_right") && inputs["rotate_right"] == true:
			angular_velocity.y = rotation_speed * rotation_speed_coefficient
		else:
			angular_velocity.y = 0
		print(angular_velocity.y)
	
	if inputs.has("jump") && inputs["jump"] == true && is_on_ground():
		linear_velocity.y = jump_force
	
	dash_timer += delta
	
	if is_dashing == true && dash_timer > dash_duration:
		is_dashing = false
		lock_rotation = false
	
	if inputs.has("dash") && inputs["dash"] == true && dash_timer >= dash_cooldown:
		dash_timer = 0
		is_dashing = true
		lock_rotation = true
		linear_velocity.x = dash_force * transform.basis.z.x
		linear_velocity.z = dash_force * transform.basis.z.z
	
	for key in inputs.keys():
		inputs[key] = false


func is_on_ground(checked_collisions : Array[PhysicsEntity] = []) -> bool:
	checked_collisions.append(self)

	for body in jump_colliding_bodies:
		if body.is_in_group("ground"):
			return true
		if body is PhysicsEntity && checked_collisions.has(body) == false && body.is_on_ground(checked_collisions):
			return true

	return false


func set_team(new_team : Team):
	team = new_team
	team.cuboid_list.append(self)
	color_changed.emit(team.color)


func _on_jump_detection_area_3d_body_entered(body: Node3D) -> void:
	if body != self:
		jump_colliding_bodies.append(body)


func _on_jump_detection_area_3d_body_exited(body: Node3D) -> void:
	jump_colliding_bodies.erase(body)


func get_observation_informations(caller : Cuboid) -> Dictionary:
	var dictionary : Dictionary = super.get_observation_informations(caller)

	dictionary["is_same_team"] = 1 if caller.team == team else 0
	dictionary["dash_cooldown"] = get_dash_cooldown()

	return dictionary


func get_dash_cooldown() -> float:
	return clampf(dash_timer / dash_cooldown, 0, 1)
