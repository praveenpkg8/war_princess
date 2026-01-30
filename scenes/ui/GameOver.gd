extends CanvasLayer

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var reason_label = $CenterContainer/VBoxContainer/ReasonLabel
@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton
@onready var quit_button = $CenterContainer/VBoxContainer/QuitButton

var death_reason: String = "You were spotted!"

func _ready():
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	GameManager.game_over_reached.connect(_on_game_over)

func _process(_delta):
	if visible:
		if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(Key.KEY_R):
			_on_restart_pressed()
		if Input.is_key_pressed(Key.KEY_Q):
			_on_quit_pressed()

func _on_game_over(reason: String):
	death_reason = reason
	visible = true
	reason_label.text = death_reason

func _on_restart_pressed():
	GameManager.restart_game()
	visible = false

func _on_quit_pressed():
	GameManager.quit_game()

func show_win_screen():
	title_label.text = "YOU ESCAPED!"
	reason_label.text = "Together at last..."
	restart_button.text = "Play Again"
	visible = true
