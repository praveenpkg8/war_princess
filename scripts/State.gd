extends Node
class_name State

signal state_transitioned(from_state: State, to_state_name: String)

var state_machine: StateMachine = null
var state_owner: Node = null

func enter():
	pass

func exit():
	pass

func update(delta: float):
	pass

func physics_update(delta: float):
	pass

func transition_to(state_name: String):
	state_transitioned.emit(self, state_name)
