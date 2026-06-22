extends PhysicsEntity
class_name Cuboid

const gravity : float = -9.81

@export var is_controlled : bool = true

@export var speed : float = 8
@export var rotation_speed : float = 3
@export var jump_force : float = 12

@export var dash_force : float = 10
@export var dash_cooldown : float = 2
@export var dash_duration : float = 1

var team : Team

var jump_colliding_bodies : Array[Node3D]
var dash_timer : float = 0
var is_dashing : bool = false

signal color_changed(color : Color)


func _ready() -> void:
	super()


func _physics_process(delta: float) -> void:
	if is_controlled == false:
		linear_velocity.x = 0
		linear_velocity.z = 0
		angular_velocity.y = 0
		return
	
	if is_dashing == false:
		if Input.is_action_pressed("move_forward"):
			linear_velocity.x = speed * transform.basis.x.x
			linear_velocity.z = speed * transform.basis.x.z
		elif Input.is_action_pressed("move_back"):
			linear_velocity.x = -speed * transform.basis.x.x
			linear_velocity.z = -speed * transform.basis.x.z
		else:
			linear_velocity.x = 0
			linear_velocity.z = 0
		
		if Input.is_action_pressed("rotate_left"):
			angular_velocity.y = rotation_speed
		elif Input.is_action_pressed("rotate_right"):
			angular_velocity.y = -rotation_speed
		else:
			angular_velocity.y = 0
	
	if Input.is_action_just_pressed("jump") && is_on_ground():
		linear_velocity.y = jump_force
	
	dash_timer += delta
	
	if is_dashing == true && dash_timer > dash_duration:
		is_dashing = false
		lock_rotation = false
	
	if Input.is_action_just_pressed("dash") && dash_timer >= dash_cooldown:
		dash_timer = 0
		is_dashing = true
		lock_rotation = true
		linear_velocity.x = dash_force * transform.basis.x.x
		linear_velocity.z = dash_force * transform.basis.x.z


func is_on_ground(checked_collisions : Array[PhysicsEntity] = []) -> bool:
	checked_collisions.append(self)
	
	for body in jump_colliding_bodies:
		if body.is_in_group("ground") || body.is_on_ground(checked_collisions):
			return true
	
	return false


func set_team(new_team : Team):
	team = new_team
	color_changed.emit(team.color)


func _on_jump_detection_area_3d_body_entered(body: Node3D) -> void:
	if body != self:
		jump_colliding_bodies.append(body)


func _on_jump_detection_area_3d_body_exited(body: Node3D) -> void:
	jump_colliding_bodies.erase(body)
