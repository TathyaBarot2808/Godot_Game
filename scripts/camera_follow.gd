extends Camera2D
# -------------------------------------------------------------------------
# CAMERA LOOK-AHEAD
# Smoothly shifts the camera offset in the direction the player is moving
# so the player can always see what's coming ahead of them.
# -------------------------------------------------------------------------

@export_group("Look-Ahead")
@export var LOOKAHEAD_X: float = 160.0        # How far ahead to look horizontally (pixels)
@export var LOOKAHEAD_Y_UP: float = 100.0     # How far ahead to look when jumping upward
@export var LOOKAHEAD_Y_DOWN: float = 180.0   # How far ahead to look when falling (more room below)
@export var LOOKAHEAD_SPEED: float = 2.5      # How quickly the camera smoothly slides to the target offset

# Velocity thresholds — avoids jitter from tiny accidental speeds
@export_group("Thresholds")
@export var X_VELOCITY_THRESHOLD: float = 80.0   # Min horizontal speed to trigger horizontal look-ahead
@export var Y_VELOCITY_THRESHOLD: float = 80.0   # Min vertical speed to trigger vertical look-ahead

var _target_offset: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	var player: CharacterBody2D = get_parent() as CharacterBody2D
	if player == null:
		return

	var vel: Vector2 = player.velocity

	# ---- Horizontal look-ahead ----
	if vel.x > X_VELOCITY_THRESHOLD:
		_target_offset.x = LOOKAHEAD_X
	elif vel.x < -X_VELOCITY_THRESHOLD:
		_target_offset.x = -LOOKAHEAD_X
	else:
		_target_offset.x = 0.0

	# ---- Vertical look-ahead ----
	# Falling: look further down so the player can see what's below
	# Jumping: look a bit up so the player can see platforms above
	if vel.y > Y_VELOCITY_THRESHOLD:
		_target_offset.y = LOOKAHEAD_Y_DOWN      # Falling — shift camera down
	elif vel.y < -Y_VELOCITY_THRESHOLD:
		_target_offset.y = -LOOKAHEAD_Y_UP       # Rising — shift camera up
	else:
		_target_offset.y = 0.0

	# Smoothly lerp the camera offset toward the target
	offset = offset.lerp(_target_offset, LOOKAHEAD_SPEED * delta)
