extends Node
class_name StateMachine

var current_state: State
var states: Dictionary = {}
var state_owner: Node = null

func _ready():
	state_owner = get_parent()
	for child in get_children():
		if child is State:
			states[child.name.to_upper()] = child
			child.state_machine = self
			child.state_owner = state_owner
			child.state_transitioned.connect(_on_state_transition)
	if states.size() > 0:
		current_state = states.values()[0]
		current_state.enter()

func _process(delta):
	if current_state:
		current_state.update(delta)

func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)

func transition_to(state_name: String):
	if current_state and states.has(state_name.to_upper()):
		current_state.exit()
		current_state = states[state_name.to_upper()]
		current_state.enter()

func _on_state_transition(from_state: State, to_state_name: String):
	if from_state == current_state:
		transition_to(to_state_name)

func get_current_state_name() -> String:
	if current_state:
		return current_state.name
	return ""
