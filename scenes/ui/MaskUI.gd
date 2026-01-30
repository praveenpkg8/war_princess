extends CanvasLayer

const HOLD_TIME = 0.5

@onready var progress_bar = $Panel/ProgressBar
@onready var vignette = $Vignette
@onready var interaction_prompt = $InteractionPrompt
@onready var prompt_label = $InteractionPrompt/PromptBackground/PromptLabel
@onready var prompt_progress = $InteractionPrompt/PromptBackground/PromptProgress

var player_ref: Node = null
var hold_timer: float = 0.0
var is_near_loot: bool = false
var current_loot_target: Node = null

func _ready():
	interaction_prompt.visible = false
	prompt_progress.value = 0

func _process(delta):
	_find_player()

	if player_ref and not GameManager.is_game_over:
		_update_filter_display()
		_update_vignette(delta)
		_update_interaction(delta)

func _find_player():
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")

func _update_filter_display():
	if player_ref and player_ref.has_method("get_filter_health_percent"):
		var health_percent = player_ref.get_filter_health_percent()
		progress_bar.value = health_percent * 100

		# Change color based on health
		if health_percent > 0.5:
			progress_bar.modulate = Color(0.2, 0.8, 0.2)
		elif health_percent > 0.2:
			progress_bar.modulate = Color(1, 0.8, 0)
		else:
			progress_bar.modulate = Color(0.8, 0.2, 0.2)

func _update_vignette(delta):
	if not player_ref:
		return

	var filter_health = player_ref.filter_health if player_ref.has_method("filter_health") else 100

	if filter_health < 20:
		var target_alpha = 0.3
		vignette.color = Color(0, 1, 0, lerp(vignette.color.a, target_alpha, 0.1))

		# Play heartbeat when low
		AudioManager.play_heartbeat(filter_health / 100.0)
	else:
		vignette.color = Color(0, 1, 0, lerp(vignette.color.a, 0.0, 0.1))
		AudioManager.stop_heartbeat()

func _update_interaction(delta):
	# Check for nearby loot
	is_near_loot = false
	current_loot_target = null

	if player_ref:
		var lootables = get_tree().get_nodes_in_group("lootable")
		for loot in lootables:
			if player_ref.global_position.distance_to(loot.global_position) < 50:
				is_near_loot = true
				current_loot_target = loot
				break

	if is_near_loot and current_loot_target:
		interaction_prompt.visible = true
		_handle_interaction_hold(delta)
	else:
		interaction_prompt.visible = false
		hold_timer = 0.0
		prompt_progress.value = 0

func _handle_interaction_hold(delta):
	if Input.is_action_pressed("interact"):
		hold_timer += delta
		prompt_progress.value = (hold_timer / HOLD_TIME) * 100

		if hold_timer >= HOLD_TIME:
			_complete_interaction()
			hold_timer = 0.0
			prompt_progress.value = 0
	else:
		hold_timer = 0.0
		prompt_progress.value = 0

func _complete_interaction():
	if current_loot_target and current_loot_target.has_method("loot"):
		current_loot_target.loot(player_ref)
