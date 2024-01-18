extends State
class_name NPC_chase_player


func enter():
	super()
	if is_on:
		print("entered")
		fsm.npc.move_to(fsm.npc.player.position)


func _physics_process(delta):
	super(delta)
	fsm.npc.nav_agent.target_position = fsm.npc.player.position
