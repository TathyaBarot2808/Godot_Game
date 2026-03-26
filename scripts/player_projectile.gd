extends Area2D
# This script is attached to the bullet you fire.
# Area2D is perfect for bullets because it detects when it overlaps with things
# (like enemies or walls) without bouncing off them physically.

# Speed of the bullet in pixels per second. 
# @export lets you change this number directly in the Godot inspector.
@export var speed: float = 800.0

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
	if body.name == "Player":
		return
		
	# If the thing we hit has a function called "take_damage" (like an enemy would),
	# tell that enemy to take 10 damage!
	if body.has_method("take_damage"):
		body.take_damage(10)
		
	# queue_free() tells Godot to delete this bullet from the game permanently
	queue_free()

# This triggers when the bullet flies completely off the player's screen
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	# We delete the bullet so it doesn't fly through empty space forever taking up memory!
	queue_free()
