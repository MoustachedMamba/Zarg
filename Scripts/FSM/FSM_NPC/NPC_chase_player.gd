extends State
class_name NPC_chase_player


func enter():
	super()
	if is_on:
		fsm.npc.move_to(fsm.npc.player_seen_pos)


func _physics_process(delta):
	super(delta)
	fsm.npc.nav_agent.target_position = fsm.npc.player_seen_pos
