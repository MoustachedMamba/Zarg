extends CharacterBody3D


@export var walk_speed = 3.5
@export var sprint_speed = 7.0
@export var crouch_walk_speed = 2.0
@export var jump_velocity = 5.0
@export var sensitivity = Vector2(0.2,0.4)
@export var camera_responsive = Vector2(7.0,7.0)
@export var air_control = 0.0
@export var accel = 5.0
@onready var head = $head
@onready var headbob = $head/headbobcentre
@onready var collider = $CollisionShape3D
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var look_rot : Vector2
var look_target : Vector2
var current_speed = walk_speed
var target_speed = walk_speed
var head_bob_timer = 0.0
var head_height_default = 1.5
var head_height_crouch = 0.7
var crouched = false
var crouch_input = false
var sprinting = false
var crouch_height = 1.0
var stand_height

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	stand_height = collider.shape.height
	
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	
		
		
	
	head.position.y = lerp(head.position.y,float(crouched)*head_height_crouch+float(!crouched)*head_height_default,delta*5)
	if !crouch_input and crouched:
		crouched = is_under_smth()
		if !crouched:
			target_speed = sprint_speed if sprinting else walk_speed
	get_crouch(delta*5,crouched)
	current_speed = lerp(current_speed,target_speed,accel*delta)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and is_on_floor():
		velocity.x = lerp(velocity.x,direction.x * current_speed,accel*delta)
		velocity.z = lerp(velocity.z,direction.z * current_speed,accel*delta)
	elif is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, accel*delta)
		velocity.z = lerp(velocity.z, 0.0, accel*delta)
	else:
		pass

	move_and_slide()
	look_rot.x = lerp(look_rot.x,look_target.x,delta*camera_responsive.x)
	look_rot.y = lerp(look_rot.y,look_target.y,delta*camera_responsive.y)
	head.rotation_degrees.x = look_rot.x
	rotation_degrees.y = look_rot.y
	
		
func _process(delta):
	if is_on_floor():
		head_bob_timer += delta*velocity.length()*3.0
	headbob.position.y = sin(head_bob_timer)*0.1
	print(target_speed)
		
	
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		look_target.y -= event.relative.x * sensitivity.x * (0.5 + float(is_on_floor())*0.5)
		look_target.x -= event.relative.y * sensitivity.y * (0.5 + float(is_on_floor())*0.5)
		look_target.x = clamp(look_target.x,-80,90)	
	
	if event.is_action_pressed("Exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("Return") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
	if event.is_action_pressed("Sprint"):
		sprinting = true
		if !crouched:
			target_speed = sprint_speed
	if event.is_action_released("Sprint"):
		sprinting = false
		if crouched:
			target_speed = crouch_walk_speed
		else:
			target_speed = walk_speed
	if event.is_action_pressed("Crouch"):
		crouched = true
		crouch_input = true
		target_speed = crouch_walk_speed
	if event.is_action_released("Crouch"):
		crouch_input = false
		crouched = is_under_smth()
		if sprinting and !crouched:
			target_speed = sprint_speed
		elif !crouched:
			target_speed = walk_speed
	
func get_crouch(delta : float, crouching = false):
	var target_height : float = crouch_height if crouching else stand_height
	
	collider.shape.height = lerp(collider.shape.height, target_height, delta)
	collider.position.y = lerp(collider.position.y, target_height * 0.5, delta)
	head.position.y = collider.shape.height-0.5

func is_under_smth()->bool:
	return $CollisionShape3D/Area3D.has_overlapping_bodies() and is_on_floor()
	
