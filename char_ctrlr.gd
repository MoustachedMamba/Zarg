extends CharacterBody3D


@export var walk_speed = 4.0
@export var sprint_speed = 7.0
@export var crouch_walk_speed = 2.5
@export var jump_velocity = 5.0
@export var sensitivity = Vector2(0.25,0.4)
@export var camera_responsive = Vector2(7.0,7.0)
@export var air_control = 0.0
@export var gain_accel = 4.0
@export var lose_accel = 6.5
@export var bob_amp = 0.02
@export var bob_fr = 3.0
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
var crouched = false
var crouch_input = false
var sprinting = false
var crouch_height = 1.0
var stand_height
var lean = 0
var vert_offset = 0.0
var start_pos
var handpos
var handtarget
var default_handpos
var attack_hold_dir = 0
var attack_power = 0
var state = "normal"
var attack_start_transform
var angle_from_speed


func _ready():
	start_pos = position
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	stand_height = collider.shape.height
	handtarget = $head/headbobcentre/hand_temp/Target
	default_handpos = handtarget.position
	handpos = default_handpos
	
	
func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if crouch_input and !crouched:
		crouched = is_on_floor()
	if !crouch_input and crouched:
		crouched = is_under_smth()
		if !crouched:
			target_speed = sprint_speed if sprinting else walk_speed
	get_crouch(delta*5,crouched)
	current_speed = lerp(current_speed,target_speed,gain_accel*delta)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction and is_on_floor():
		velocity.x = lerp(velocity.x,direction.x * current_speed,gain_accel*delta)
		velocity.z = lerp(velocity.z,direction.z * current_speed,gain_accel*delta)
	elif is_on_floor():
		velocity.x = lerp(velocity.x, 0.0, lose_accel*delta)
		velocity.z = lerp(velocity.z, 0.0, lose_accel*delta)
	else:
		pass

	move_and_slide()
	look_rot.x = lerp(look_rot.x,look_target.x,delta*camera_responsive.x)
	look_rot.y = lerp(look_rot.y,look_target.y,delta*camera_responsive.y)
	head.rotation_degrees.x = look_rot.x
	rotation_degrees.y = look_rot.y
	get_lean(delta)
	determine_speed()
	camera_fov_control()
	
		
func _process(delta):
	print(state)
	if is_on_floor():
		head_bob_timer += delta*velocity.length()*bob_fr
	headbob.position.y = sin(head_bob_timer)*clamp(current_speed,3.0,5.0)*bob_amp
	vert_offset = lerp(vert_offset,clamp(velocity.y,-10.0,6)*0.07,delta*4.0)
	headbob.position.y += vert_offset*1.6
	#headbob.rotation_degrees.x = vert_offset*9 
	var target_basis = head.basis
	var horizontal_vel = Vector3(velocity.x,0,velocity.z)
	if horizontal_vel:
		var axis = horizontal_vel.rotated(Vector3(0,1,0), PI/2)
		var localaxis =  (axis * basis).normalized()
		target_basis = head.basis.rotated(localaxis,horizontal_vel.length()*0.01)
	headbob.basis = headbob.basis.slerp(target_basis,1)
	handlehands(delta)
			
	
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		look_target.y -= event.relative.x * sensitivity.x * (0.5 + float(is_on_floor())*0.5)
		look_target.x -= event.relative.y * sensitivity.y * (0.5 + float(is_on_floor())*0.5)
		look_target.x = clamp(look_target.x,-80,90)	
	
	if event.is_action_pressed("Exit"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if event.is_action_pressed("Return") and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("Jump") and is_on_floor() and !is_under_smth():
		velocity.y = jump_velocity
	if event.is_action_pressed("Sprint"):
		sprinting = true
	if event.is_action_released("Sprint"):
		sprinting = false
	if event.is_action_pressed("Crouch"):
		if is_on_floor(): crouched = true
		crouch_input = true
	if event.is_action_released("Crouch"):
		crouch_input = false
		crouched = is_under_smth()
	if event.is_action_pressed("AttackLeft") and state == "normal":
		attack_start_transform = handtarget.transform
		attack_hold_dir = 1
		$WindupTimer.start()
		state = "windup"
	if event.is_action_pressed("AttackRight") and state == "normal":
		attack_start_transform = handtarget.transform
		attack_hold_dir = -1
		$WindupTimer.start()
		state = "windup"
	if  state == "windup" and (event.is_action_released("AttackRight") or event.is_action_released("AttackLeft")):
		if ($WindupTimer.wait_time - $WindupTimer.time_left)/$WindupTimer.wait_time < 0.4:
			state = "add_windup"
		else: begin_attack(attack_hold_dir*-1)
	
func get_crouch(delta : float, crouching = false):
	var target_height : float = crouch_height if crouching else stand_height
	
	collider.shape.height = lerp(collider.shape.height, target_height, delta)
	collider.position.y = lerp(collider.position.y, target_height * 0.5, delta)
	head.position.y = collider.shape.height-0.2

func is_under_smth()->bool:
	return $CollisionShape3D/Area3D.has_overlapping_bodies() and is_on_floor()

func get_lean(delta):
	var can_lean_right = float(!$CollisionShape3D/right_ear.has_overlapping_bodies() and $CollisionShape3D/front.has_overlapping_bodies())
	var can_lean_left = float(!$CollisionShape3D/left_ear.has_overlapping_bodies() and $CollisionShape3D/front.has_overlapping_bodies())
	var target_lean : float = float(Input.is_action_pressed("LeanRight"))*can_lean_right - float(Input.is_action_pressed("LeanLeft"))*can_lean_left
	head.position.x = lerp(head.position.x, 0.7*target_lean, delta*(4.0 - abs(target_lean)))
	head.rotation_degrees.z = lerp(head.rotation_degrees.z, -20*target_lean, delta*(4.0 - abs(target_lean)))

func determine_speed():
	if crouched:
		target_speed = crouch_walk_speed
	elif sprinting:
		target_speed = sprint_speed
	else:
		target_speed = walk_speed
		
func camera_fov_control():
	$head/headbobcentre/Camera3D.set_fov(70+0.2*Vector2(velocity.z,velocity.x).length()*current_speed + 0.4*abs(head.rotation_degrees.z))
		

func die():
	position = start_pos

func handlehands(delta):
	var target_rot = Quaternion(handtarget.basis.orthonormalized())
	var inteerp_start_rot = Quaternion(handtarget.basis.orthonormalized())
	var centerbasis = $head/headbobcentre/hand_temp.basis.rotated(Vector3(0, 1, 0),PI).orthonormalized()
	var progress = 0
	if($head/headbobcentre/hand_temp/RayCast3D.is_colliding()):
		handpos = $head/headbobcentre/hand_temp.to_local($head/headbobcentre/hand_temp/RayCast3D.get_collision_point())*3/5
	else:
		handpos = default_handpos
	if state == "normal":
		target_rot = Quaternion(centerbasis)
		handtarget.position = lerp(handtarget.position, handpos+Vector3(sin(head_bob_timer/2)*0.8,sin(head_bob_timer)*0.3,sin(head_bob_timer)*0.3),delta*4)
		target_rot = Quaternion(centerbasis.rotated(Vector3(0, 0, 1),sin(head_bob_timer/2)*0.1).orthonormalized())
		progress = 1-$AttackTimer.time_left / $AttackTimer.wait_time
	elif state == "windup" or state == "add_windup":
		progress = 1-$WindupTimer.time_left/$WindupTimer.wait_time
		progress = pow(progress, 0.6)
		handpos.x += progress * attack_hold_dir * 2
		handpos.z -= progress * 1
		handpos.y += progress * 1
		inteerp_start_rot = Quaternion(attack_start_transform.basis.orthonormalized())
		target_rot = Quaternion(centerbasis.rotated(Vector3(0, 0, 1),-1.0*attack_hold_dir).orthonormalized())
		handtarget.position = lerp(handtarget.position, handpos, delta*4)
		if  state == "add_windup" and ($WindupTimer.wait_time - $WindupTimer.time_left)/$WindupTimer.wait_time >= 0.4:
			begin_attack(attack_hold_dir*-1)
	elif state == "attacking":
		progress = 1 - $AttackTimer.time_left / $AttackTimer.wait_time
		progress = pow(progress, 1.3)
		handpos.x += attack_power*2
		handpos.z += abs(attack_power)*0.5
		handpos.y -= abs(attack_power)*1
		handtarget.position = (handpos - attack_start_transform.origin)*progress + attack_start_transform.origin
		inteerp_start_rot = Quaternion(attack_start_transform.basis.orthonormalized())
		#handtarget.position = lerp(handtarget.position, handpos,delta*10)
		centerbasis = centerbasis.rotated(Vector3(0, 1, 0),PI/2*attack_power).orthonormalized()
		centerbasis = centerbasis.rotated(Vector3(1, 0, 0),PI/2).orthonormalized()
		#-0.3*(1.0 - abs(attack_power))
		target_rot = Quaternion(centerbasis.rotated(Vector3(0, 1, 0),attack_power*1).orthonormalized())
		if $AttackTimer.is_stopped():
			state = "recovery"
			$AttackTimer.wait_time/=1.3
			$AttackTimer.start()
	elif state == "recovery":
		handtarget.position = lerp(handtarget.position, handpos,delta*3)
		target_rot = Quaternion(centerbasis)
		if (handtarget.position-handpos).length() < 0.5:
			state = "normal"
		progress = 1-$AttackTimer.time_left / $AttackTimer.wait_time
	inteerp_start_rot = inteerp_start_rot.normalized()
	target_rot = target_rot.normalized()
	handtarget.basis = Basis(inteerp_start_rot.slerp(target_rot,progress))
	#handtarget.basis = Basis(target_rot)
	handtarget.transform = handtarget.transform.orthonormalized()

func begin_attack(dir):
	attack_start_transform = handtarget.transform
	attack_hold_dir = 0
	attack_power = (0.2+(($WindupTimer.wait_time - $WindupTimer.time_left)/$WindupTimer.wait_time)*0.8)
	attack_power *= dir
	$AttackTimer.wait_time = 0.2 + (abs(attack_power)-0.2)*0.3
	$AttackTimer.start()
	$WindupTimer.stop()
	state = "attacking"
