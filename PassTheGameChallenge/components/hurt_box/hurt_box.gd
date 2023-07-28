class_name HurtBox
extends Area3D

@export var damage: int = 10
@export var cooldown_time: float = 1.0
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready():
	cooldown_timer.wait_time = cooldown_time
	body_entered.connect(on_body_entered)

func on_body_entered(body: Node3D):

	# Don't deal damage if still cooling down
	if cooldown_timer.time_left > 0:
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		cooldown_timer.start()
		



signal blocked




func _on_area_entered(area):
	
	if area.get("IsAShield") != null :
		
		emit_signal("blocked")
	
