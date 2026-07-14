extends Node
class_name GameModeManager

@export var game_mode : GameMode

static var instance : GameModeManager


func _init() -> void:
	instance = self


func _ready() -> void:
	SignalsManager.game.emit_game_mode_set(game_mode)


func create_game_mode(game_mode_data : Dictionary) -> GameMode:
	var new_game_mode : GameMode = GameMode.new(game_mode_data)
	return new_game_mode
