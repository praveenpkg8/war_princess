extends Node

signal game_over_reached(reason: String)
signal noise_created(position: Vector2, radius: float)
signal game_won()

var is_game_over: bool = false
var current_level: String = "res://scenes/level/Level1.tscn"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game():
	is_game_over = false
	get_tree().change_scene_to_file(current_level)

func game_over(reason: String = "You were spotted!"):
	if is_game_over:
		return
	is_game_over = true
	game_over_reached.emit(reason)
	get_tree().paused = true

func restart_game():
	is_game_over = false
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit_game():
	get_tree().quit()

func win():
	if is_game_over:
		return
	is_game_over = true
	game_won.emit()
	get_tree().paused = true

func create_noise(position: Vector2, radius: float):
	noise_created.emit(position, radius)
