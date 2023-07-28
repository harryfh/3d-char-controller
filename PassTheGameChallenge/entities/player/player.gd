class_name Player
extends CharacterBody3D

## Player controller for a 3rd Person Game
##
## Individual functions have been broken up so they can be either called here
## or in a state machine (ex. apply_gravity)
# Check out the gdscript style guide: https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html

# Movement Variables
var gravity_multiplier := 3.0
var move_speed: float = 0
const walk_speed: float = 8
const run_speed: float = 12
var acceleration: float = 8
var deceleration: float = 10
var jump_height: float = 10
var angular_velocity = 5.0
@onready var gravity: float = (ProjectSettings.get_setting("physics/3d/default_gravity") 
		* gravity_multiplier)
var direction := Vector3()
var forward: Vector3
var sensitivity_x: float = 0.2
var sensitivity_y: float = 0.2

# Components
@onready var health_component: HealthComponent = $HealthComponent
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/CameraGuide

#Animation 
@onready var animator : AnimationPlayer = $AnimationPlayer
var shieldFirst = false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health_component.health_died.connect(on_death)
	move_speed = walk_speed
	$WeaponManager/Shield/Shield_box.hide()

func _physics_process(delta):
	if Input.is_action_just_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if Input.is_action_just_pressed("jump"):
		apply_jump()
		
	
	if Input.is_action_just_pressed("SwordStance") :
		
		if (!shieldFirst) :
			
			#lunge animation
			animator.play("Thrust")
			
		else :
			
			animator.play_backwards("ShieldFirst")
			
			shieldFirst = false
			
		
	
	if Input.is_action_just_pressed("ShieldStance"):
		
		
		if (shieldFirst):
			
			animator.play("Bump")
			
		else :
			
			animator.play("ShieldFirst")
			
			shieldFirst = true
			
			
		
	
	
	if not is_on_floor():
		apply_gravity(delta)
	
	handle_move_input( delta)
	handle_sprint_input()
	accelerate(delta)
	
	apply_movement()

# changed phyisics/common/physics_ticks_per_second to 144 instead of default 60 since bc of my monitor, it may cause issues IDK
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * sensitivity_x)
		$CameraPivot.rotate_x(deg_to_rad(-event.relative.y) * sensitivity_y)
		$CameraPivot.rotation_degrees.x = clampf($CameraPivot.rotation_degrees.x, -30, 15) 

	

func handle_move_input( delta : float ):
	forward = -camera.global_transform.basis.z.normalized()
	var input_axis = Input.get_vector(&"move_backward", &"move_forward",
			&"move_left", &"move_right")
	
	# Removed the Y movement as it now serve directly in the rotation of the character
	direction = -forward * -input_axis.x  + forward.cross(Vector3.UP) * input_axis.y
	
	# turn the character in the direction of the movement
	#if (abs(input_axis.y) > 0) :
		
	#	global_rotation += Vector3(0, - input_axis.y, 0) * delta * 3
		


func handle_sprint_input():
	if Input.is_action_pressed("sprint"):
		move_speed = run_speed
	else:
		move_speed = walk_speed


func apply_gravity(delta):
	velocity.y -= gravity * delta


func apply_movement():
	move_and_slide()


func apply_jump():
	velocity.y = jump_height


func accelerate(delta: float) -> void:
	# Using only the horizontal velocity, interpolate towards the input.
	var temp_vel := velocity
	temp_vel.y = 0
	
	var temp_accel: float
	var target: Vector3 = direction * move_speed
	
	if direction.dot(temp_vel) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deceleration
	
	temp_vel = temp_vel.lerp(target, temp_accel * delta)
	
	velocity.x = temp_vel.x
	velocity.z = temp_vel.z


func on_death():
	# Reset the player
	global_position = Vector3.ZERO
	velocity = Vector3.ZERO
	health_component.full_heal()


func rotate_towards_motion_no_y(delta: float):
	# Rotate so caller is facing the position
	var current_direction := -global_transform.basis.z
	# Get the axis to rotate on
	var axis := Vector3.UP
	# Make sure its not zero
	if axis == Vector3.ZERO:
		return
	var angle := current_direction.signed_angle_to(direction, axis)
	var angle_step: float = min(angular_velocity * delta, abs(angle)) * sign(angle)
	rotate(axis, angle_step)
	
func take_damage(damage : int):
	health_component.take_damage(damage)
