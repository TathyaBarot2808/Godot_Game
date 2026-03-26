extends AbilityBase

@export_group("Dash Settings")
@export var DASH_SPEED: float = 1800.0
@export var DASH_DURATION: float = 0.12
@export var DASH_COOLDOWN: float = 0.5

signal dash_started
signal dash_ended

var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _cooldown_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _dash_timer > 0:
		_dash_timer -= delta
		if _dash_timer <= 0:
			_is_dashing = false
			dash_ended.emit()
	if _cooldown_timer > 0:
		_cooldown_timer -= delta

# ── AbilityBase interface ─────────────────────────────────────────────────────

func can_use() -> bool:
	return not _is_dashing and _cooldown_timer <= 0.0

# args: { "direction": float }  (-1.0 left, 1.0 right)
func trigger(args: Dictionary) -> Variant:
	var direction: float = args.get("direction", 1.0)
	_is_dashing = true
	_dash_timer = DASH_DURATION
	_cooldown_timer = DASH_COOLDOWN
	dash_started.emit()
	return Vector2(direction * DASH_SPEED, 0.0)

func is_active() -> bool:
	return _is_dashing
