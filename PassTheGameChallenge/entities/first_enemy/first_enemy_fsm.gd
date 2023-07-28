extends StateMachine

var mob: FirstEnemy
var rand_gen: RandomNumberGenerator
var follow_target: Node3D = null
@onready var anim_player: AnimationPlayer = $"../AnimationPlayer"
@onready var detection_area: Area3D = $"../DetectionArea"
var attack_target: Node3D = null

var wander_target: Vector3
var wander_stop_distance: float = 2.0
var wander_max_distance: float = 5.0
var wander_min_distance: float = 2.0

var pause_timer: Timer
var pause_time: float = 0.5
var pause_time_variance: float = 0.1


var swing_sword_cooldown_timer: Timer

@export var swing_sword_range: float = 3
@export var swing_sword_cooldown_min: float = 0.1
@export var swing_sword_cooldown_max: float = 0.5

func _ready():
	rand_gen = RandomNumberGenerator.new()
	randomize()
	
	# Constructing and adding the timers
	pause_timer = Timer.new()
	pause_timer.one_shot = true
	pause_timer.wait_time = pause_time
	add_child(pause_timer)
	
	swing_sword_cooldown_timer = Timer.new()
	swing_sword_cooldown_timer.one_shot = true
	swing_sword_cooldown_timer.wait_time = get_swing_cooldown()
	add_child(swing_sword_cooldown_timer)
	
	# This state machine controls the node that it is a child of
	mob = get_parent()
	
	# Create states
	add_state("wander")
	add_state("pause")
	add_state("move_to_target")
	add_state("swing_sword")
	call_deferred("set_state", states.wander)
	


func get_swing_cooldown() -> float:
	return randf_range(swing_sword_cooldown_min, swing_sword_cooldown_max)

func _state_logic(delta):
	mob.apply_gravity(delta)
	
	
	if !attack_target:
		find_player_in_detection_area()
	
	if state == states.wander:
		pass
	if [states.pause, states.swing_sword].has(state):
		mob.direction = Vector3.ZERO
	if state == states.move_to_target:
		mob.direction = mob.global_position.direction_to(attack_target.global_position)

	mob.accelerate(delta)
	mob.apply_movement()
	mob.rotate_towards_motion_no_y(delta)

func _get_transition(_delta):
	match state:
		states.wander:
			if attack_target != null:
					return states.move_to_target
			if mob.global_position.distance_to(wander_target) < wander_stop_distance:
				return states.pause
		states.pause:
			if pause_timer.time_left <= 0:
				if follow_target != null:
					return states.follow
				else:
					return states.wander
		states.move_to_target:
			if mob.global_position.distance_to(attack_target.global_position) < swing_sword_range:
				return states.swing_sword
		states.swing_sword:
			if swing_sword_cooldown_timer.time_left > 0:
				return null # Do not transition
			else:
				
				if attack_target != null:
					return states.move_to_target
				else:
					return states.wander
	return null

func _enter_state(_new_state, _previous_state):
	state_changed.emit(states.keys()[_new_state])
	
	match state:
		states.wander:
			# Get a random x and z around the frog
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
			pass
		states.pause:
			pause_timer.wait_time = rand_gen.randf_range(pause_time - pause_time_variance, pause_time + pause_time_variance)
			pause_timer.start()
			pass
		states.move_to_target:
			pass
		states.swing_sword:
			var swing_time = 0.25
			anim_player.play("sword_slash_horizontal",-1,2) # Original was 0.5
			swing_sword_cooldown_timer.wait_time = swing_time
			swing_sword_cooldown_timer.start()

			pass
	pass

func _on_sword_blow_stopped():
	
	# cancel the swing animation
	var is_blocked = true
	anim_player.stop()
	anim_player.play("BlockedAnim")
	
	pass # Replace with function body.


func _exit_state(_old_state, _new_state):
	pass


func find_player_in_detection_area():
	for n in detection_area.get_overlapping_bodies():
		if n is Player:
			attack_target = n
			print("Found player in detection area")
