class_name FollowCamera
extends Camera3D

var move_speed: float = 2
@export var guide: Node3D
@export var look_at_target: Node3D

func _physics_process(delta):
	if guide != null:
		global_position = global_position.slerp(guide.global_position, delta )
	else:
		print("Need to set guide in Follow Camera")
		
	if look_at_target != null:
		look_at(look_at_target.global_position, Vector3.UP, false)
	else:
		print("Need to set look_at_target in Follow Camera")
