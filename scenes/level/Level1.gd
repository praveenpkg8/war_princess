extends Node2D

@onready var prisoner_cell = $PrisonerCell

func _ready():
	prisoner_cell.body_entered.connect(_on_prisoner_reached)

func _on_prisoner_reached(body):
	if body.is_in_group("player"):
		GameManager.win()
		if has_node("/root/Main/GameOver"):
			var game_over = get_node("/root/Main/GameOver")
			if game_over.has_method("show_win_screen"):
				game_over.show_win_screen()
