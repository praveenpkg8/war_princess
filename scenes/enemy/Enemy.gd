extends CharacterBody2D

@export var waypoints: Array[Vector2] = []
@export var vision_range: float = 200.0
@export var vision_angle: float = 90.0  # degrees
@export var reach_tolerance: float = 10.0
@export var stuck_timeout: float = 2.5
@export var stuck_min_speed: float = 5.0
@export var stuck_progress_epsilon: float = 1.0

var investigation_target: Vector2 = Vector2.ZERO
var is_dead: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var state_machine: StateMachine = null

@onready var sprite = $Sprite2D
@onready var vision_cone = $VisionCone
@onready var hearing_zone = $HearingZone
@onready var loot_prompt = $LootPrompt
@onready var state_machine_node = $StateMachine
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var player_ref: Node = null
var _nav_desired_velocity: Vector2 = Vector2.ZERO
var _nav_ready: bool = false
var _debug_target: Vector2 = Vector2.ZERO
var _debug_nav_target: Vector2 = Vector2.ZERO
var _debug_next_pos: Vector2 = Vector2.ZERO
var _debug_has_path: bool = false
var _stuck_timer: float = 0.0
var _last_distance: float = INF

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

	if nav_agent:
		nav_agent.velocity_computed.connect(_on_nav_velocity_computed)
	call_deferred("_enable_nav_ready")

func _enable_nav_ready() -> void:
	_nav_ready = true

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
		if vision_cone:
			vision_cone.rotation = facing_direction.angle()

func get_facing_direction() -> Vector2:
	return facing_direction

func move_towards(target: Vector2, speed: float) -> bool:
	if nav_agent:
		var nav_target = get_nav_target(target)
		if nav_agent.target_position != nav_target:
			nav_agent.target_position = nav_target

		var direct_to_target = nav_target - global_position
		_debug_target = target
		_debug_nav_target = nav_target
		_debug_has_path = not nav_agent.is_navigation_finished()
		if direct_to_target.length() <= nav_agent.target_desired_distance:
			velocity = Vector2.ZERO
			return false

		if not nav_agent.is_target_reachable():
			return _move_directly(nav_target, speed)

		if nav_agent.is_navigation_finished():
			return _move_directly(target, speed)

		var next_pos = nav_agent.get_next_path_position()
		_debug_next_pos = next_pos
		queue_redraw()
		var dir = next_pos - global_position
		if dir.length() <= 0.001:
			return _move_directly(nav_target, speed)

		_nav_desired_velocity = dir.normalized() * speed
		if nav_agent.avoidance_enabled:
			nav_agent.velocity = _nav_desired_velocity
		else:
			velocity = _nav_desired_velocity
			move_and_slide()
		return true

	return _move_directly(target, speed)

func get_nav_target(point: Vector2) -> Vector2:
	if not nav_agent:
		return point

	var map_rid = nav_agent.get_navigation_map()
	if map_rid.is_valid() and _nav_ready:
		var iteration_id = NavigationServer2D.map_get_iteration_id(map_rid)
		if iteration_id <= 0:
			return point
		var closest = NavigationServer2D.map_get_closest_point(map_rid, point)
		if closest == Vector2.ZERO and point.length() > 10.0:
			return point
		return closest

	return point

func _move_directly(target: Vector2, speed: float) -> bool:
	_debug_target = target
	_debug_nav_target = target
	_debug_next_pos = target
	_debug_has_path = false
	queue_redraw()
	var direct = target - global_position
	if direct.length() <= 0.001:
		velocity = Vector2.ZERO
		return false

	velocity = direct.normalized() * speed
	move_and_slide()
	return true

func is_target_reached(target: Vector2) -> bool:
	var desired = reach_tolerance
	if nav_agent:
		desired = max(desired, nav_agent.target_desired_distance)
	return global_position.distance_to(target) <= desired

func is_stuck(target: Vector2, delta: float) -> bool:
	if is_target_reached(target):
		_stuck_timer = 0.0
		_last_distance = INF
		return false

	var distance = global_position.distance_to(target)
	var made_progress = distance < (_last_distance - stuck_progress_epsilon)
	if made_progress or velocity.length() >= stuck_min_speed:
		_stuck_timer = 0.0
	else:
		_stuck_timer += delta

	_last_distance = distance
	return _stuck_timer >= stuck_timeout

func _on_nav_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead:
		return
	if safe_velocity.length() <= 0.001 and _nav_desired_velocity.length() > 0.001:
		velocity = _nav_desired_velocity
	else:
		velocity = safe_velocity
	move_and_slide()

func _draw() -> void:
	# Debug overlay: target (yellow), nav target (cyan), next path (magenta)
	if _debug_target != Vector2.ZERO:
		draw_circle(to_local(_debug_target), 4.0, Color(1.0, 0.9, 0.2))
	if _debug_nav_target != Vector2.ZERO:
		draw_circle(to_local(_debug_nav_target), 4.0, Color(0.2, 0.9, 1.0))
	if _debug_next_pos != Vector2.ZERO:
		draw_circle(to_local(_debug_next_pos), 4.0, Color(1.0, 0.2, 0.9))
	if _debug_has_path and _debug_next_pos != Vector2.ZERO:
		draw_line(Vector2.ZERO, to_local(_debug_next_pos), Color(1.0, 0.2, 0.9), 1.5)

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
