extends AbilityBase
# This component handles the player's Shooting ability.
# It manages the "Black Hole" animation overlay and tells the player when to spawn the bullet.

# References to nodes on the player (set during _ready)
var shoot_effect: AnimatedSprite2D
var player: CharacterBody2D

func _ready() -> void:
	# Find our parent player
	player = get_parent().get_parent() 
	shoot_effect = player.get_node("ShootEffectSprite")

# This is called by the AbilitiesManager when you click Shoot
func trigger(_args: Dictionary) -> Variant:
	if shoot_effect:
		shoot_effect.show()
		shoot_effect.play("default")
		shoot_effect.set_frame_and_progress(0, 0.0)
	return null # This ability doesn't return a velocity boost like dash does

# The manager asks this to see if we are currently "busy" shooting
func is_active() -> bool:
	return player.is_shooting_action_active if player else false

# Check if we are allowed to shoot (not dashing, etc.)
func can_use() -> bool:
	return not player.is_dashing if player else true
