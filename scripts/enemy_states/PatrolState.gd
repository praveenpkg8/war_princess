extends State
class_name PatrolState

const SPEED = 80.0
const WAYPOINT_THRESHOLD = 10.0

var enemy: CharacterBody2D
var current_waypoint_index: int = 0
var wait_timer: float = 0.0
const WAIT_TIME = 2.0
var is_waiting: bool = false

func enter():
	enemy = state_owner
	current_waypoint_index = 0
	is_waiting = false
	wait_timer = 0.0

func update(delta):
	if enemy.waypoints.is_empty():
		return

	if is_waiting:
		wait_timer += delta
		if wait_timer >= WAIT_TIME:
			is_waiting = false
			wait_timer = 0.0
			current_waypoint_index = (current_waypoint_index + 1) % enemy.waypoints.size()
		return

	var target = enemy.waypoints[current_waypoint_index]
	if enemy.is_target_reached(target):
		is_waiting = true
		enemy.velocity = Vector2.ZERO
	elif enemy.is_stuck(target, delta):
		current_waypoint_index = (current_waypoint_index + 1) % enemy.waypoints.size()
		is_waiting = false
		wait_timer = 0.0
	else:
		enemy.move_towards(target, SPEED)

	# Update facing direction
	if enemy.velocity.length() > 0:
		enemy.set_facing_direction(enemy.velocity.normalized())

func physics_update(delta):
	update(delta)
