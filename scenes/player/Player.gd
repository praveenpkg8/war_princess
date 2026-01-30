extends CharacterBody2D

const SPEED = 200.0
const SPRINT_MULTIPLIER = 1.5
const FILTER_MAX = 100.0

@export var kill_front_cone_deg: float = 90.0

signal noise_created(position: Vector2, radius: float)
signal mask_depleted

var filter_health: float = FILTER_MAX
var filter_depletion_rate: float = 20.0  # per second (50 seconds total)
var sprint_depletion_multiplier: float = 1.5
var is_coughing: bool = false
var cough_timer: Timer = null
var can_loot: Array[Node] = []
var current_loot_target: Node = null

@onready var kill_zone = $KillZone
@onready var kill_zone_collision = $KillZone/KillZoneCollision
@onready var loot_zone = $LootZone
@onready var sprite = $Sprite2D

func _ready():
	# Setup kill zone
	var kill_shape = CircleShape2D.new()
	kill_shape.radius = 30.0
	var kill_collision = CollisionShape2D.new()
	kill_collision.shape = kill_shape
	kill_zone.add_child(kill_collision)
	kill_zone.body_entered.connect(_on_kill_zone_entered)
	kill_zone.monitoring = true

	# Setup loot zone
	var loot_shape = CircleShape2D.new()
	loot_shape.radius = 40.0
	var loot_collision = CollisionShape2D.new()
	loot_collision.shape = loot_shape
	loot_zone.add_child(loot_collision)
	loot_zone.body_exited.connect(_on_loot_zone_exited)
	loot_zone.body_entered.connect(_on_loot_zone_entered)

	# Create placeholder sprite texture
	_create_placeholder_sprite()

	# Add to player group
	add_to_group("player")

	# Connect to global noise signal
	noise_created.connect(GameManager.create_noise)

func _create_placeholder_sprite():
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color(0.2, 0.8, 0.2))
	# Draw circle
	for x in range(32):
		for y in range(32):
			var center = Vector2(16, 16)
			if Vector2(x, y).distance_to(center) <= 14:
				image.set_pixel(x, y, Color(0.2, 0.8, 0.2))
			else:
				image.set_pixel(x, y, Color.TRANSPARENT)
	texture.set_image(image)
	sprite.texture = texture

func _physics_process(_delta):
	if GameManager.is_game_over:
		velocity = Vector2.ZERO
		return

	# Movement
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed = SPEED
	var is_sprinting = Input.is_action_pressed("sprint")

	if is_sprinting:
		current_speed *= SPRINT_MULTIPLIER

	velocity = direction * current_speed
	move_and_slide()

	# Noise on running
	if direction.length() > 0 and is_sprinting:
		noise_created.emit(global_position, 80.0)

	# Update sprite facing direction
	if direction.length() > 0:
		sprite.rotation = direction.angle()

func _process(delta):
	if GameManager.is_game_over:
		return

	# Filter degradation
	filter_health -= filter_depletion_rate * delta

	# Sprint depletes faster
	if Input.is_action_pressed("sprint"):
		filter_health -= filter_depletion_rate * sprint_depletion_multiplier * delta

	if filter_health <= 0:
		filter_health = 0
		if not is_coughing:
			start_coughing()

	# Check for interaction
	if Input.is_action_just_pressed("interact"):
		try_interact()
	if Input.is_action_just_pressed("kill"):
		try_kill_enemy()

func start_coughing():
	is_coughing = true
	AudioManager.play_cough()

	if cough_timer == null:
		cough_timer = Timer.new()
		cough_timer.wait_time = 0.5
		cough_timer.autostart = false
		add_child(cough_timer)
		cough_timer.timeout.connect(_on_cough_tick)

	cough_timer.start()

func stop_coughing():
	is_coughing = false
	if cough_timer and cough_timer.is_inside_tree():
		cough_timer.stop()

func _on_cough_tick():
	if is_coughing and filter_health <= 0:
		noise_created.emit(global_position, 120.0)  # Large noise radius
		AudioManager.play_cough()

func restore_filter():
	filter_health = FILTER_MAX
	stop_coughing()
	AudioManager.play_filter_swap()

func _on_kill_zone_entered(body):
	if body.is_in_group("enemy"):
		pass

func try_kill_enemy():
	var bodies = kill_zone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy") and body.has_method("can_be_killed"):
			if is_behind_enemy(body):
				body.die()

func is_behind_enemy(enemy: Node) -> bool:
	if enemy.has_method("get_facing_direction"):
		var enemy_facing = enemy.get_facing_direction()
		var to_player = (global_position - enemy.global_position).normalized()
		if enemy_facing.length() > 0:
			var front_cos = cos(deg_to_rad(kill_front_cone_deg * 0.5))
			return enemy_facing.dot(to_player) <= front_cos
	return true  # Can kill if enemy is stationary

func _on_loot_zone_entered(body):
	if body.is_in_group("lootable"):
		can_loot.append(body)
		current_loot_target = body

func _on_loot_zone_exited(body):
	if body in can_loot:
		can_loot.erase(body)
		if current_loot_target == body:
			current_loot_target = can_loot.front() if can_loot.size() > 0 else null

func try_interact():
	if current_loot_target and current_loot_target.has_method("loot"):
		current_loot_target.loot(self)

func get_filter_health_percent() -> float:
	return filter_health / FILTER_MAX
