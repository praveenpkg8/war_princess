extends State
class_name InvestigateState

const INVESTIGATE_SPEED = 100.0
const TARGET_THRESHOLD = 15.0
const LOOK_TIME = 3.0

var enemy: CharacterBody2D
var investigation_point: Vector2
var wait_timer: float = 0.0
var is_looking: bool = false
var look_angle: float = 0.0
var look_direction: int = 1

func enter():
	enemy = state_owner
	investigation_point = enemy.investigation_target
	wait_timer = 0.0
	is_looking = false
	look_angle = 0.0
	look_direction = 1

func set_investigation_point(point: Vector2):
	investigation_point = point

func update(delta):
	if is_looking:
		look_around(delta)
		return

	var target = investigation_point
	if enemy.is_target_reached(target):
		is_looking = true
		enemy.velocity = Vector2.ZERO
		AudioManager.play_alert()
	elif enemy.is_stuck(target, delta):
		transition_to("Patrol")
	else:
		enemy.move_towards(target, INVESTIGATE_SPEED)

	# Update facing direction
	if enemy.velocity.length() > 0:
		enemy.set_facing_direction(enemy.velocity.normalized())

func physics_update(delta):
	update(delta)

func look_around(delta):
	wait_timer += delta
	look_angle += look_direction * 2.0 * delta

	if look_angle >= PI / 2 or look_angle <= -PI / 2:
		look_direction *= -1

	if wait_timer >= LOOK_TIME:
		transition_to("Patrol")

func on_noise_heard(position: Vector2, radius: float):
	if enemy.global_position.distance_to(position) <= radius:
		investigation_point = position
		wait_timer = 0.0
		is_looking = false

func on_player_seen():
	transition_to("Chase")
