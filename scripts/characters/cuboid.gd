extends PhysicsEntity
class_name Cuboid

enum InputMode {
	HUMAN,
	AI,
}

@export var input_mode : InputMode = InputMode.AI

@export var speed : float = 8
@export var rotation_speed : float = 3
@export var jump_force : float = 12

@export var dash_force : float = 10
@export var dash_cooldown : float = 2
@export var dash_duration : float = 1

@export var camera : Camera3D
@export var cuboid_ai_controller : CuboidAIController

var team : Team

var jump_colliding_bodies : Array[Node3D]
var dash_timer : float = 0
var is_dashing : bool = false


signal color_changed(color : Color)


func _ready() -> void:
	super()
	
	cuboid_ai_controller.init(self)


func _physics_process(delta: float) -> void:
	handle_inputs(get_inputs(), delta)


func get_inputs() -> Dictionary[String, bool]:
	var inputs : Dictionary[String, bool]
	
	match input_mode:
		InputMode.HUMAN:
			inputs["move_forward"] = Input.is_action_pressed("move_forward")
			inputs["move_back"] = Input.is_action_pressed("move_back")
			inputs["rotate_left"] = Input.is_action_pressed("rotate_left")
			inputs["rotate_right"] = Input.is_action_pressed("rotate_right")
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


func handle_inputs(inputs : Dictionary[String, bool], delta : float):
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
			angular_velocity.y = rotation_speed
		elif inputs.has("rotate_right") && inputs["rotate_right"] == true:
			angular_velocity.y = -rotation_speed
		else:
			angular_velocity.y = 0

	
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
	dictionary["dash_cooldown"] = clampf(dash_timer / dash_cooldown, 0, 1)
	
	return dictionary
