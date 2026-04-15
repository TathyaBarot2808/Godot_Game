extends AbilityBase

@onready var player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D

func is_active() -> bool:
	return player != null and player.is_on_wall() and Input.is_action_pressed("jump")

func can_use() -> bool:
	return player != null and player.is_on_wall() and Input.is_action_just_pressed("jump") and not player.is_on_floor()

func trigger(_args: Dictionary) -> Variant:
	if player == null:
		return null
	var wall_normal: Vector2 = player.get_wall_normal()
	var jump_speed: float = absf(float(player.get("JUMP_VELOCITY")))
	var jump_velocity: Vector2 = Vector2(-wall_normal.x, -1).normalized() * jump_speed
	return jump_velocity
