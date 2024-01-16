extends Node
class_name State


@export var scr: Script

var fsm: StateMachine


func enter():
	pass


func exit(next_state):
	fsm.change_to(next_state)
