extends AbilityBase
# This component handles the player's Shooting ability.
# It manages the "Black Hole" animation overlay and tells the player when to spawn the bullet.


# Reference to player node (set during _ready)
var player

func _ready() -> void:
	# Find our parent player
	player = get_parent().get_parent()
	if player == null:
		push_error("ShootComponent: player not found")

# This is called by the AbilitiesManager when you click Shoot
func trigger(_args: Dictionary) -> Variant:
	add_to_group("bullet")
	if player == null:
		return false
	var direction: Vector2 = _args.get("direction", Vector2.ZERO)
	return player.start_shooting(direction)

# The manager asks this to see if we are currently "busy" shooting
func is_active() -> bool:
	return player.is_shooting_action_active if player else false

# Check if we are allowed to shoot (not dashing, etc.)
func can_use() -> bool:
	if player == null:
		return false
	return not player.is_dashing and not player.is_shooting_action_active
