extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5


var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


@onready var navagent = $NavigationAgent3D


# Handle gravity
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()



