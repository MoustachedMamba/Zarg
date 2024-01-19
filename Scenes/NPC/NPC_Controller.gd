extends CharacterBody3D


const SPEED := 6.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 10.0
const FOV = 170.0
const VISION_LENGTH = 20.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_path: PackedVector3Array
var player_seen_pos
var player_direction_bias = Vector3(0,0,0)

@onready var nav_agent = $NavigationAgent3D
@onready var state_machine = $NPC_StateMachine

@export var player: CharacterBody3D


func _ready():
	state_machine.change_to("NPC_idle")
	player_seen_pos = player.position


func _physics_process(delta):
	var player_dir = (player.position - position).normalized()
	var forward_vector = transform.basis*Vector3(0,0,-1).normalized()
	var angle = acos(forward_vector.dot(player_dir))/PI * 180
	if angle < FOV/2:
		$RayCast3D.target_position = to_local((player.position-position).normalized()*VISION_LENGTH +position) + Vector3(0,0.1,0)
		if $RayCast3D.is_colliding():
			if $RayCast3D.get_collider() is CharacterBody3D:
				player_seen_pos = player.position
				player_direction_bias = player.velocity
				if state_machine.current_state is NPC_find_player:
					state_machine.change_to("NPC_chase_player")
			else:
				if state_machine.current_state is NPC_chase_player:
					state_machine.change_to("NPC_find_player")
	
	var direction := Vector3()
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * SPEED
	print(next_location, current_location, new_velocity)
	if not is_on_floor():
			velocity.y -= gravity * delta
	else:
		velocity = velocity.move_toward(new_velocity, delta*TURN_SPEED)
	
	if velocity.x != 0 or velocity.z != 0:
		transform = transform.looking_at(transform.origin+Vector3(velocity.x,0,velocity.z).normalized())
	move_and_slide()


func _on_navigation_agent_3d_target_reached():
	if state_machine.current_state is NPC_chase_player:
		nav_agent.target_position = position
		state_machine.change_to("NPC_idle")
	elif state_machine.current_state is NPC_find_player:
		nav_agent.target_position = player_seen_pos + Vector3(randf()*10,0,randf()*10) + randf()*player_direction_bias*10
		nav_agent.target_position = nav_agent.get_final_position()


func move_to(coor: Vector3):
	
	nav_agent.target_position = coor


func get_hit():
	state_machine.change_to("NPC_chase_player")


func _unhandled_input(event):
	if event.is_action_pressed("Use"):
		state_machine.change_to("NPC_find_player")
