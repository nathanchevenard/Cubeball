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

var free_phantom_camera : PhantomCamera3D

var inputs : Dictionary[String, Variant]
static var possible_move_list : Array[String] = [
	"move_speed_coefficient",
	"rotate_speed_coefficient",
	"jump",
	"dash",
]

signal color_changed(color : Color)


func _ready() -> void:
	super()
	
	EntityManager.instance.cuboid_list.append(self)
	cuboid_ai_controller.init(self)
	reset_inputs()


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
		if abs(event.relative.x) > 2:
			inputs["rotate_speed_coefficient"] = clampf(-event.relative.x * mouse_sensitivity, -1.0, 1.0)


func get_inputs() -> Dictionary[String, Variant]:
	match input_mode:
		InputMode.HUMAN:
			if Input.is_action_pressed("rotate_left"):
				inputs["rotate_speed_coefficient"] = rotation_speed_keyboard_coefficient
			if Input.is_action_pressed("rotate_right"):
				inputs["rotate_speed_coefficient"] = -rotation_speed_keyboard_coefficient
			if Input.is_action_pressed("move_forward"):
				inputs["move_speed_coefficient"] = 1.0
			if Input.is_action_pressed("move_back"):
				inputs["move_speed_coefficient"] = -1.0
			inputs["jump"] = Input.is_action_pressed("jump")
			inputs["dash"] = Input.is_action_pressed("dash")
		InputMode.AI:
			inputs["move_forward"] = cuboid_ai_controller.move_forward_action
			inputs["move_back"] = cuboid_ai_controller.move_back_action
			inputs["rotate_left"] = cuboid_ai_controller.rotate_left_action
			inputs["rotate_right"] = cuboid_ai_controller.rotate_right_action
			inputs["jump"] = cuboid_ai_controller.jump_action
			inputs["dash"] = cuboid_ai_controller.dash_action
	
	return inputs


func handle_inputs(delta : float):
	if is_dashing == false:
		linear_velocity.x = inputs["move_speed_coefficient"] * speed * transform.basis.z.x
		linear_velocity.z = inputs["move_speed_coefficient"] * speed * transform.basis.z.z
		
		angular_velocity.y = inputs["rotate_speed_coefficient"] * rotation_speed
	
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
	
	reset_inputs()


func reset_inputs():
	inputs["rotate_speed_coefficient"] = 0.0
	inputs["move_speed_coefficient"] = 0.0
	inputs["jump"] = false
	inputs["dash"] = false


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
