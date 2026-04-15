extends AbilityBase

var player

func _ready() -> void:

	player = get_parent().get_parent()
	if player == null:
		push_error("ShootComponent: player not found")

func trigger(_args: Dictionary) -> Variant:
	if player == null:
		return false
	var direction: Vector2 = _args.get("direction", Vector2.ZERO)
	return player.start_shooting(direction)

func is_active() -> bool:
	return player.is_shooting_action_active if player else false

func can_use() -> bool:
	if player == null:
		return false
	return not player.is_dashing and not player.is_shooting_action_active
