class_name HealthBar
extends ProgressBar

var health_component: HealthComponent


func set_health_component(component: HealthComponent):
	if health_component != null:
		health_component.queue_free()
	health_component = component
	
	health_component.health_changed.connect(on_health_changed)
	max_value = health_component.max_health
	min_value = 0
	value = health_component.get_health()


func on_health_changed(health_value: int):
	value = health_value
