extends CharacterBody3D

#Player Nodes

@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes
@onready var crouching_collision_shape_2 = $crouching_collision_shape2
@onready var standing_collision_shape = $standing_collision_shape
@onready var ray_cast_3d = $RayCast3D
@onready var camera_3d = $neck/head/eyes/Camera3D

#Speed Vars
var current_speed = 4.0
const walking_speed = 4.0
const sprint_speed = 6.0
const crouch_speed = 2.0

#States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

#Slide Vars
var slide_timer = 0.0
var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 6

#Head bobbing vars
const head_bobbing_sprint_speed = 22
const head_bobbing_walking_speed = 14
const head_bobbing_crouch_speed = 10

const head_bobbing_sprint_intesnse = 0.2
const head_bobbing_walking_intense = 0.1
const head_bobbing_crouch_intense = 0.3

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var head_bobbing_current_instense = 0.0

#Movement Vars
const jump_velocity = 4.5
var crouching_depth = -0.5
var lerp_speed = 8.0
var free_look_tilt = 8

#Input Vars
var direction = Vector3.ZERO
const mouse_sens = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		if free_looking:
				neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
				neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
				
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))
		

func _physics_process(delta):
	#Getting movement inputs
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	
	#Handle Movement State
	
	# CROUCHING
	if Input.is_action_pressed("crouch") || sliding:
		
		current_speed = crouch_speed
		head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape_2.disabled = false
		
		#Slide Begin Logic
		
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			free_looking = true
			print("Slide Begins")
			
		
		walking = false
		sprinting = false
		crouching = true
		
	
	elif !ray_cast_3d.is_colliding():
		
	# STANDING
		standing_collision_shape.disabled = false
		crouching_collision_shape_2.disabled = true
		
		head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			#SPRINTING
			current_speed = sprint_speed
			
			walking = false
			sprinting = true
			crouching = false
			
		else:
			#NORMAL SPEED
			current_speed = walking_speed
			
			walking = true
			sprinting = false
			crouching = false
	
	#Handle freelooking
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		
		if sliding:
			camera_3d.rotation.z = lerp(camera_3d.rotation.z,-deg_to_rad(1.25),delta * lerp_speed)
		else:
			camera_3d.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt)
		
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		camera_3d.rotation.z = lerp(camera_3d.rotation.y,0.0,delta*lerp_speed)
		
	#Handle Sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
			free_looking = false
			print("Slide Ends")
			
	#Handle Headbobbing
	if sprinting:
			head_bobbing_current_instense = head_bobbing_sprint_intesnse
			head_bobbing_index += head_bobbing_sprint_speed*delta
	elif walking:
			head_bobbing_current_instense = head_bobbing_walking_intense
			head_bobbing_index += head_bobbing_walking_speed*delta
	elif crouching:
			head_bobbing_current_instense = head_bobbing_crouch_intense
			head_bobbing_index += head_bobbing_crouch_speed*delta
			
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
		
		eyes.position.y = lerp(eyes.position.y,head_bobbing_vector.y*(head_bobbing_current_instense/2.0),delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,head_bobbing_vector.x*head_bobbing_current_instense,delta*lerp_speed)
	else: 
		eyes.position.y = lerp(eyes.position.y,0.0,delta*lerp_speed)
		eyes.position.x = lerp(eyes.position.x,0.0,delta*lerp_speed)
		
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false
		

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x,0,slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.05) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.05) * slide_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
