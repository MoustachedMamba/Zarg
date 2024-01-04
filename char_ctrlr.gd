extends CharacterBody3D


@export var walk_speed = 3.0
@export var sprint_speed = 7.0
@export var jump_velocity = 4.5
@export var sensitivity = Vector2(1.0,1.0)
@export var camera_responsive = Vector2(7.0,7.0)
@export var air_control = 0.0
@export var accel = 16.0
@onready var head = $Node3D
@onready var headbob = $Node3D/headbobcentre
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_rot : Vector2
var look_target : Vector2
var current_speed = walk_speed
var target_speed = walk_speed
var head_bob_timer = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("Sprint"):
		target_speed = sprint_speed
	if Input.is_action_just_released("Sprint"):
		target_speed = walk_speed 
	
	current_speed = lerp(current_speed,target_speed,accel*delta*0.3)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = lerp(velocity.x,direction.x * current_speed,accel*delta)
		velocity.z = lerp(velocity.z,direction.z * current_speed,accel*delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, accel*delta)
		velocity.z = lerp(velocity.z, 0.0, accel*delta)

	move_and_slide()
	look_rot.x = lerp(look_rot.x,look_target.x,delta*camera_responsive.x)
	look_rot.y = lerp(look_rot.y,look_target.y,delta*camera_responsive.y)
	head.rotation_degrees.x = look_rot.x
	rotation_degrees.y = look_rot.y
	
		
func _process(delta):
	if is_on_floor():
		head_bob_timer += delta*velocity.length()*3.0
	headbob.position.y = sin(head_bob_timer)*0.1
		
	
	
func _input(event):
	if event is InputEventMouseMotion:
		look_target.y -= event.relative.x*sensitivity.x
		look_target.x -= event.relative.y*sensitivity.y
		look_target.x = clamp(look_target.x,-80,90)	
		#look_target.y = fmod(look_target.y,360.0)

	
	
