extends State
class_name ChaseState

const CHASE_SPEED = 180.0
const LOSE_SIGHT_TIME = 5.0

var enemy: CharacterBody2D
var player_ref: Node = null
var lose_sight_timer: float = 0.0
var has_seen_player: bool = false

func enter():
	enemy = state_owner
	player_ref = get_tree().get_first_node_in_group("player")
	lose_sight_timer = 0.0
	has_seen_player = false
	AudioManager.play_alert()

func update(delta):
	if not player_ref:
		transition_to("Patrol")
		return

	if can_see_player():
		has_seen_player = true
		lose_sight_timer = 0.0
		var direction = (player_ref.global_position - enemy.global_position).normalized()
		enemy.velocity = direction * CHASE_SPEED
		enemy.move_and_slide()

		# Update facing direction
		enemy.set_facing_direction(direction)

		# Check if caught player
		if enemy.global_position.distance_to(player_ref.global_position) < 20:
			GameManager.game_over("Caught by guard!")
	else:
		if has_seen_player:
			lose_sight_timer += delta
			if lose_sight_timer >= LOSE_SIGHT_TIME:
				# Go to investigate last seen position
				enemy.investigation_target = player_ref.global_position
				transition_to("Investigate")
		else:
			transition_to("Patrol")

func physics_update(delta):
	update(delta)

func can_see_player() -> bool:
	if not player_ref:
		return false

	var distance = enemy.global_position.distance_to(player_ref.global_position)
	if distance > enemy.vision_range:
		return false

	# Check if player is in vision cone
	var to_player = (player_ref.global_position - enemy.global_position).normalized()
	var facing_dir = enemy.get_facing_direction()

	if facing_dir.length() > 0:
		var angle = to_player.angle_to(facing_dir)
		if abs(angle) > deg_to_rad(enemy.vision_angle / 2):
			return false

	# Check for walls
	var space_state = enemy.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		enemy.global_position,
		player_ref.global_position,
		enemy.collision_mask
	)
	var result = space_state.intersect_ray(query)

	if result and result.collider == player_ref:
		return true

	return false

func on_noise_heard(position: Vector2, radius: float):
	pass  # Ignore noise while chasing

func on_player_seen():
	has_seen_player = true
	lose_sight_timer = 0.0
