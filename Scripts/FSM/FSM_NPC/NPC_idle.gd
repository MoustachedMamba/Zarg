extends State
class_name NPC_idle

func enter():
	pass


func exit(next_state):
	fsm.change_to(next_state)
