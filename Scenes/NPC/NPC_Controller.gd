extends CharacterBody3D


const SPEED := 6.0
const JUMP_VELOCITY = 4.5
const TURN_SPEED = 10.0


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_path: PackedVector3Array


@onready var nav_agent = $NavigationAgent3D
@onready var state_machine = $NPC_StateMachine

@export var player: CharacterBody3D


func _ready():
	state_machine.change_to("NPC_idle")


func _physics_process(delta):
	var direction := Vector3()
	var current_location = global_transform.origin
	var next_location = nav_agent.get_next_path_position()
	var new_velocity = (next_location - current_location).normalized() * SPEED

	if not is_on_floor():
			velocity.y -= gravity * delta
	else:
		velocity = velocity.move_toward(new_velocity, delta*TURN_SPEED)
	
	if position != next_location:
		look_at(next_location)
	
	move_and_slide()


func _on_navigation_agent_3d_target_reached():
	nav_agent.target_position = position
	state_machine.change_to("NPC_idle")


func move_to(coor: Vector3):
	nav_agent.target_position = coor


func get_hit():
	state_machine.change_to("NPC_chase_player")


func _unhandled_input(event):
	if event.is_action_pressed("Use"):
		state_machine.change_to("NPC_chase_player")
