extends Area2D
@export var speed: float = 800.0
@export var damage: float = 10.0

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("enemy_projectile")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		return
	if not body.is_in_group("player"):
		queue_free()
		return

	var health := _find_health_component(body)
	if health != null:
		health.take_damage(damage)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _find_health_component(start_node: Node) -> HealthComponent:
	var current: Node = start_node
	while current != null:
		if current is HealthComponent:
			return current as HealthComponent
		for child in current.get_children():
			if child is HealthComponent:
				return child as HealthComponent
		current = current.get_parent()
	return null
