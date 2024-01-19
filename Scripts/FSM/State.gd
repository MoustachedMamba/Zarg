extends Node
class_name State


@export var scr: Script

var fsm: StateMachine  # Link to current StateMachine
var is_on = false  # To track if this is a current state, to on/off _process and _physics_process methods
var timer = 0

func enter():
	is_on = true


func exit(next_state):
	fsm.change_to(next_state)
	is_on = false


func _process(delta):
	if not is_on:
		return


func _physics_process(delta):
	if not is_on:
		return
