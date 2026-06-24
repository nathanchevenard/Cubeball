extends Node
class_name GameModeManager

@export var game_mode : GameMode


func _ready() -> void:
	SignalsManager.game.emit_game_mode_set(game_mode)
