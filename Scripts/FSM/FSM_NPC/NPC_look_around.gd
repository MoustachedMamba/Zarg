extends State

class_name NPC_look_around
const search_timer = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_on:
		timer += delta
		if timer > search_timer:
			fsm.change_to("NPC_find_player")
			fsm.current_state.timer += timer
			timer = 0
	super(delta)
