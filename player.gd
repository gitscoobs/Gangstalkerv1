extends CharacterBody3D

#Player Nodes
@onready var head = $head
@onready var crouching_collision_shape_2 = $crouching_collision_shape2
@onready var standing_collision_shape = $standing_collision_shape
@onready var ray_cast_3d = $RayCast3D

#Speed Vars
var current_speed = 5.0
const walking_speed = 5.0
const sprint_speed = 8.0
const crouch_speed = 3.0

#Movement Vars
const jump_velocity = 4.5
var crouching_depth = -0.5
var lerp_speed = 8.0

#Input Vars
var direction = Vector3.ZERO
const mouse_sens = 0.25

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		#mouse looking logic
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))

func _physics_process(delta):
	
	#Handle Movement State
	
	# CROUCHING
	if Input.is_action_pressed("crouch"):
		current_speed = crouch_speed
		head.position.y = lerp(head.position.y,1.8 + crouching_depth,delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		
		crouching_collision_shape_2.disabled = false
	elif !ray_cast_3d.is_colliding():
		
	# STANDING
		standing_collision_shape.disabled = false
		crouching_collision_shape_2.disabled = true
		
		head.position.y = lerp(head.position.y,1.8,delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
			#SPRINTING
			current_speed = sprint_speed
		else:
			#NORMAL SPEED
			current_speed = walking_speed
		
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
