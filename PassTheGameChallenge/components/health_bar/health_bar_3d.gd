class_name HealthBar3D
extends Sprite3D

@export var health_component: HealthComponent
@onready var health_bar_ui: HealthBar = $SubViewport/HealthBar

func _ready():
	health_bar_ui.set_health_component(health_component)
