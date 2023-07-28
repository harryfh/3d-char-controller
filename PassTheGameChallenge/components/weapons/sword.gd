extends Node3D


signal blowStopped


func _on_hurt_box_blocked():
	emit_signal("blowStopped")
