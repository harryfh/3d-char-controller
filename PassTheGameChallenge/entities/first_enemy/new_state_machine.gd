extends Node



# reworked state machine


@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var detection_area: Area3D = $"../DetectionArea"

# States
enum states {WANDER, PAUSE, CHASE, ATTACK, BLOCKED}
var states_str = {states.WANDER : "wander", states.PAUSE  : "pause", 
			states.CHASE : "chase", states.ATTACK : "attack", states.BLOCKED : "blocked"}
var state : states



var mob: FirstEnemy
var rand_gen: RandomNumberGenerator
var attack_target: Node3D = null

# Movement

var wander_target: Vector3
var wander_stop_distance: float = 2.0
var wander_max_distance: float = 5.0
var wander_min_distance: float = 2.0

# Timer's

var pause_timer: Timer
var pause_time: float = 0.5
var pause_time_variance: float = 0.1

var is_blocked = false # Flag from received signal
var in_blocked_state_timer : Timer
var blocked_animation_time : float = 0.5

var can_attack = false # Flag from received signal
var swing_sword_cooldown_timer: Timer
@export var swing_sword_range: float = 3
@export var swing_sword_cooldown_min: float = 0.25
@export var swing_sword_cooldown_max: float = 0.75

signal state_changed

func _ready():
	state = states.WANDER


	rand_gen = RandomNumberGenerator.new()
	randomize()
	mob = get_parent()

	# Constructing and adding the timers
	pause_timer = Timer.new()
	pause_timer.one_shot = true
	pause_timer.wait_time = pause_time
	add_child(pause_timer)
	
	

	swing_sword_cooldown_timer = Timer.new()
	swing_sword_cooldown_timer.one_shot = true 
	swing_sword_cooldown_timer.wait_time = 0.5
	
	
	add_child(swing_sword_cooldown_timer)
	
	in_blocked_state_timer = Timer.new()
	in_blocked_state_timer.one_shot = true 
	in_blocked_state_timer.wait_time = 0.5
	
	
	add_child(in_blocked_state_timer)
	
	# This state machine controls the node that it is a child of


func _physics_process(delta):
	if !mob.is_on_floor():
		mob.apply_gravity(delta)

	if attack_target == null:
		
		find_player_in_detection_area()
	
	if state == states.WANDER:
		pass
	if state in [states.PAUSE, states.ATTACK]:
		mob.direction = Vector3.ZERO
	if state == states.CHASE:
		mob.direction = mob.global_position.direction_to(attack_target.global_position)

	mob.accelerate(delta)
	mob.apply_movement()
	mob.rotate_towards_motion_no_y(delta)
	
	
func _process(delta):
	match state:
		states.WANDER:
			process_state_wander()
		states.PAUSE:
			process_state_pause()
		states.CHASE:
			process_state_chase()
		states.ATTACK:
			process_state_attack()
		states.BLOCKED:
			process_state_blocked()

func set_state_blocked():
	state = states.BLOCKED
	anim_player.play("BlockedAnim")
	emit_signal("state_changed", states_str[state])
	in_blocked_state_timer.wait_time = blocked_animation_time
	in_blocked_state_timer.start()
	
func process_state_blocked():
	if in_blocked_state_timer.time_left > 0:
		return
	elif attack_target :	
		set_state_chase()
	else:	
		set_state_wander()

func set_state_wander():
	state = states.WANDER
	emit_signal("state_changed", states_str[state])
	anim_player.play("idle",0.2)

func set_state_pause():
	state = states.PAUSE
	emit_signal("state_changed", states_str[state])
	pause_timer.wait_time = rand_gen.randf_range(pause_time - pause_time_variance, pause_time + pause_time_variance)
	pause_timer.start()

func set_state_chase():
	state = states.CHASE
	can_attack = true
	anim_player.play("idle",0.2)
	emit_signal("state_changed", states_str[state])

func set_state_attack():
	state = states.ATTACK
	can_attack = true
	emit_signal("state_changed", states_str[state])

func process_state_wander():
	if attack_target:	
		set_state_chase()
		return
	if mob.global_position.distance_to(wander_target) < wander_stop_distance:	
		set_state_pause()
		return
	var wander_x_relative: float = rand_gen.randf_range(wander_min_distance, wander_max_distance)
	if rand_gen.randi_range(0, 1) == 1:
		wander_x_relative = -wander_x_relative
	var wander_z_relative: float = rand_gen.randf_range(wander_min_distance, wander_max_distance)
	if rand_gen.randi_range(0, 1) == 1:
		wander_z_relative = -wander_z_relative
	
	# Set the wander target position
	wander_target = mob.global_position + Vector3(wander_x_relative, 
		0, 
		wander_z_relative)
	mob.direction = mob.global_position.direction_to(wander_target).normalized()
	if mob.is_on_floor():
		mob.apply_jump()	
	
func process_state_pause():

	if pause_timer.time_left > 0:
		return
	elif attack_target :	
		set_state_chase()
	else:	
		set_state_wander()

func process_state_chase():

	if mob.global_position.distance_to(attack_target.global_position) < swing_sword_range:
		if swing_sword_cooldown_timer.time_left <= 0:
			set_state_attack()
	elif !attack_target:
		set_state_wander()
	

func process_state_attack():
	
	if can_attack:
		can_attack = false
		
		var swing_time = get_swing_cooldown()
		swing_sword_cooldown_timer.wait_time = swing_time
		anim_player.play("sword_slash_horizontal",-1,1/swing_time)
		swing_sword_cooldown_timer.start()
	elif is_blocked:
		set_state_blocked()
		is_blocked = false
	elif swing_sword_cooldown_timer.is_stopped():
		set_state_wander()


func get_swing_cooldown() -> float:
	return randf_range(swing_sword_cooldown_min, swing_sword_cooldown_max)


func get_blow_stopped():
	# cancel the swing animation
	is_blocked = true
	
	
	pass # Replace with function body.


func _exit_state(_old_state, _new_state):
	pass


func find_player_in_detection_area():
	for n in detection_area.get_overlapping_bodies():
		if n is Player:
			attack_target = n
			print("Found player in detection area")
