extends State
class_name NPC_find_player

const search_timer = 100.0

var timer=0

func enter():
	super()
	if is_on:
		print("entered")
		fsm.npc.nav_agent.target_position = fsm.npc.player_seen_pos
		timer = 0


func _physics_process(delta):
	timer += delta
	if timer >= search_timer:
		fsm.change_to("NPC_idle")
		timer = 0
	super(delta)
	

