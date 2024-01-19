extends StateMachine
class_name NPC_StateMachine


@export var npc: CharacterBody3D


func change_to(state):
	print("Changed to ", state)
	super(state)

