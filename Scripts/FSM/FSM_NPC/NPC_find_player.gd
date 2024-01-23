extends State
class_name NPC_find_player

const search_timer = 100.0
var search_radius = 0
var search_bias = 0
var smart_bias = 0

func enter():
	super()
	if is_on:
		print("entered")
		if fsm.history[-1] == "NPC_chase_player":
			search_bias = 0
			search_radius = 0
			smart_bias = 0.4
			timer = 0
			print("i chased")
		print("rad ",search_radius," bias ",search_bias, " smart b ", smart_bias)
		fsm.npc.get_search_point(search_radius,search_bias, smart_bias)


func _physics_process(delta):
	if is_on:
		timer += delta
		search_radius = 5 + 15*timer/search_timer
		search_bias = 2
		if timer > 5:
			smart_bias = 0
		if timer >= search_timer:
			fsm.change_to("NPC_idle")
			timer = 0
		if !fsm.npc.nav_agent.is_target_reachable():
			fsm.npc.get_search_point(search_radius,search_bias, smart_bias)
	super(delta)
	

