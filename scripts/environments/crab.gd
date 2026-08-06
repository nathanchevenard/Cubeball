extends Node3D
class_name Crab

@export var walk_speed : float = 10
@export var walk_duration : float = 5
@export var stop_duration : float = 5
@export var animation_player : AnimationPlayer

var is_walking : bool = false
var is_walking_left : bool = true
var timer : float = 0


func _ready() -> void:
	timer = stop_duration


func _process(delta: float) -> void:
	timer += delta
	
	if is_walking == false && timer >= stop_duration:
		is_walking = true
		is_walking_left = !is_walking_left
		timer = 0
		animation_player.play("walk")
	
	if is_walking == true && timer >= walk_duration:
		is_walking = false
		timer = 0
		animation_player.play("idle")
	
	if is_walking == true:
		walk(delta)


func walk(delta : float):
	var direction : Vector3 = transform.basis.x
	if is_walking_left == true:
		direction *= -1
	
	global_position += direction * delta * walk_speed
