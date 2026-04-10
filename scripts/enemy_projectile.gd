extends Area2D
# This script is attached to the bullet you fire.
# Area2D is perfect for bullets because it detects when it overlaps with things
# (like enemies or walls) without bouncing off them physically.

# Speed of the bullet in pixels per second. 
# @export lets you change this number directly in the Godot inspector.
@export var speed: float = 800.0
@export var damage: float = 10.0

# The direction the bullet will travel. This is set by the player when fired.
var direction: Vector2 = Vector2.RIGHT

# _physics_process runs consistently 60 times a second.
# It's where all movement should happen.
func _physics_process(delta: float) -> void:
	# Move the bullet forward. 
	# 'delta' ensures it moves at the exact same speed regardless of computer framerate.
	position += direction * speed * delta

# This function triggers automatically the moment the Area2D overlaps a physics body
func _on_body_entered(body: Node2D) -> void:
	# A safety check: if the bullet somehow spawns touching the player, ignore it completely.
	if body.is_in_group("enemy1"):
		return

	# Prefer reusable HealthComponent; fallback to legacy take_damage methods.
	var health := _find_health_component(body)
	if health != null:
		health.take_damage(damage)
	elif body.has_method("take_damage"):
		body.take_damage(damage)
		
	# queue_free() tells Godot to delete this bullet from the game permanently
	queue_free()

# This triggers when the bullet flies completely off the player's screen
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# We delete the bullet so it doesn't fly through empty space forever taking up memory!
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
