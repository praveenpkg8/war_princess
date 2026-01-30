extends CharacterBody2D

@export var waypoints: Array[Vector2] = []
@export var vision_range: float = 200.0
@export var vision_angle: float = 90.0  # degrees

var investigation_target: Vector2 = Vector2.ZERO
var is_dead: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var state_machine: StateMachine = null

@onready var sprite = $Sprite2D
@onready var vision_cone = $VisionCone
@onready var hearing_zone = $HearingZone
@onready var loot_prompt = $LootPrompt
@onready var state_machine_node = $StateMachine

var player_ref: Node = null

func _ready():
	# Add to groups
	add_to_group("enemy")

	# Setup vision cone
	setup_vision_cone()

	# Get state machine reference
	state_machine = state_machine_node

	# Hide loot prompt initially
	if loot_prompt:
		loot_prompt.visible = false

	# Create placeholder sprite
	_create_placeholder_sprite()

	# Connect to noise signals
	GameManager.noise_created.connect(_on_noise_heard)

	# Find player reference
	call_deferred("_find_player")

func _find_player():
	player_ref = get_tree().get_first_node_in_group("player")

func setup_vision_cone():
	# Vision cone is handled by Area2D with collision
	if vision_cone:
		vision_cone.body_entered.connect(_on_vision_cone_entered)

func _create_placeholder_sprite():
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)

	# Draw red circle with darker outline
	for x in range(32):
		for y in range(32):
			var center = Vector2(16, 16)
			var dist = Vector2(x, y).distance_to(center)
			if dist <= 14:
				image.set_pixel(x, y, Color(0.8, 0.2, 0.2))
			elif dist <= 16 and dist > 14:
				image.set_pixel(x, y, Color(0.5, 0.1, 0.1))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)

	texture.set_image(image)
	sprite.texture = texture

func _physics_process(delta):
	if is_dead:
		return

	# Check for player in vision cone
	if player_ref and not GameManager.is_game_over:
		_check_vision()

func _check_vision():
	if not player_ref:
		return

	var distance = global_position.distance_to(player_ref.global_position)
	if distance > vision_range:
		return

	# Check if player is in vision cone
	var to_player = (player_ref.global_position - global_position).normalized()

	if facing_direction.length() > 0:
		var angle = to_player.angle_to(facing_direction)
		if abs(angle) <= deg_to_rad(vision_angle / 2):
			# Check line of sight
			if has_line_of_sight():
				_on_player_seen()

func has_line_of_sight() -> bool:
	if not player_ref:
		return false

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player_ref.global_position,
		collision_mask
	)
	query.exclude = [self.get_rid()]
	var result = space_state.intersect_ray(query)

	return result and result.collider == player_ref

func _on_vision_cone_entered(body):
	if body.is_in_group("player") and not is_dead:
		if has_line_of_sight():
			_on_player_seen()

func _on_player_seen():
	if state_machine:
		var current_state = state_machine.get_current_state_name()
		if current_state != "Chase":
			state_machine.transition_to("Chase")

func _on_noise_heard(position: Vector2, radius: float):
	if is_dead:
		return

	var distance = global_position.distance_to(position)
	if distance <= radius:
		investigation_target = position
		if state_machine:
			var current_state = state_machine.get_current_state_name()
			if current_state == "Patrol":
				state_machine.transition_to("Investigate")

func set_facing_direction(direction: Vector2):
	facing_direction = direction.normalized()
	if facing_direction.length() > 0:
		sprite.rotation = facing_direction.angle()

func get_facing_direction() -> Vector2:
	return facing_direction

func can_be_killed() -> bool:
	return not is_dead

func die():
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color(0.3, 0.3, 0.3)

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Disable vision and hearing
	if vision_cone:
		vision_cone.set_deferred("monitoring", false)
	if hearing_zone:
		hearing_zone.set_deferred("monitoring", false)

	# Add to lootable group
	add_to_group("lootable")

	# Show loot prompt
	if loot_prompt:
		loot_prompt.visible = true

func loot(player: Node):
	if is_dead:
		player.restore_filter()
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and not is_dead:
		GameManager.game_over("Caught by guard!")
