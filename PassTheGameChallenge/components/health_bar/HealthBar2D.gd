class_name HealthBar2D
extends Control

@export var health_component: HealthComponent
@onready var health_bar_ui: HealthBar = $MarginContainer/HealthBar

func _ready():
	
	health_bar_ui.set_health_component(health_component)
