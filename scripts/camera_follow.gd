extends Camera2D

@export_group("Look-Ahead")
@export var LOOKAHEAD_X: float = 160.0
@export var LOOKAHEAD_Y_UP: float = 100.0
@export var LOOKAHEAD_Y_DOWN: float = 180.0
@export var LOOKAHEAD_SPEED: float = 2.5

@export_group("Thresholds")
@export var X_VELOCITY_THRESHOLD: float = 80.0
@export var Y_VELOCITY_THRESHOLD: float = 80.0

@export_group("Shake")
@export var HIT_SHAKE_STRENGTH: float = 8.0
@export var HIT_SHAKE_DURATION: float = 0.18
@export var SHAKE_DECAY: float = 20.0

var _look_ahead_offset: Vector2 = Vector2.ZERO
var _smoothed_look_ahead_offset: Vector2 = Vector2.ZERO
var _shake_offset: Vector2 = Vector2.ZERO
var _shake_time_left: float = 0.0
var _shake_strength: float = 0.0

func shake(strength: float = HIT_SHAKE_STRENGTH, duration: float = HIT_SHAKE_DURATION) -> void:
	_shake_strength = max(_shake_strength, strength)
	_shake_time_left = max(_shake_time_left, duration)

func _physics_process(delta: float) -> void:
	var player: CharacterBody2D = get_parent() as CharacterBody2D
	if player == null:
		return

	var vel: Vector2 = player.velocity

	if vel.x > X_VELOCITY_THRESHOLD:
		_look_ahead_offset.x = LOOKAHEAD_X
	elif vel.x < -X_VELOCITY_THRESHOLD:
		_look_ahead_offset.x = -LOOKAHEAD_X
	else:
		_look_ahead_offset.x = 0.0

	if vel.y > Y_VELOCITY_THRESHOLD:
		_look_ahead_offset.y = LOOKAHEAD_Y_DOWN
	elif vel.y < -Y_VELOCITY_THRESHOLD:
		_look_ahead_offset.y = -LOOKAHEAD_Y_UP
	else:
		_look_ahead_offset.y = 0.0

	var look_ahead_weight := minf(1.0, LOOKAHEAD_SPEED * delta)
	_smoothed_look_ahead_offset = _smoothed_look_ahead_offset.lerp(_look_ahead_offset, look_ahead_weight)

	_update_shake(delta)
	offset = _smoothed_look_ahead_offset + _shake_offset

func _update_shake(delta: float) -> void:
	if _shake_time_left <= 0.0:
		_shake_offset = Vector2.ZERO
		_shake_strength = 0.0
		return

	_shake_time_left -= delta
	_shake_strength = move_toward(_shake_strength, 0.0, SHAKE_DECAY * delta)
	_shake_offset = Vector2(
		randf_range(-_shake_strength, _shake_strength),
		randf_range(-_shake_strength, _shake_strength)
	)
