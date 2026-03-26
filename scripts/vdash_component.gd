extends AbilityBase

# ── Exports ───────────────────────────────────────────────────────────────────

@export_group("Vertical Dash")
@export var VDASH_SPEED: float = 1800.0
@export var VDASH_DURATION: float = 0.15
@export var VDASH_COOLDOWN: float = 0.5
@export var VDASH_GRAVITY_RECOVERY: float = 0.2

# ── Signals ───────────────────────────────────────────────────────────────────

signal vdash_started
signal vdash_ended

# ── State ─────────────────────────────────────────────────────────────────────

var _is_vdashing: bool = false
var _vdash_timer: float = 0.0
var _cooldown_timer: float = 0.0
var _recovery_timer: float = 0.0

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _vdash_timer > 0:
		_vdash_timer -= delta
		if _vdash_timer <= 0:
			_is_vdashing = false
			_cooldown_timer = VDASH_COOLDOWN
			_recovery_timer = VDASH_GRAVITY_RECOVERY
			vdash_ended.emit()

	if _cooldown_timer > 0:
		_cooldown_timer -= delta

	if _recovery_timer > 0:
		_recovery_timer -= delta

# ── AbilityBase Interface ─────────────────────────────────────────────────────

func can_use() -> bool:
	return not _is_vdashing and _cooldown_timer <= 0

func is_active() -> bool:
	return _is_vdashing

func trigger(args: Dictionary) -> Variant:
	var direction: Vector2 = args.get("direction", Vector2.UP)
	if direction == Vector2.ZERO:
		direction = Vector2.UP

	_is_vdashing = true
	_vdash_timer = VDASH_DURATION
	_cooldown_timer = 0.0
	_recovery_timer = 0.0
	vdash_started.emit()

	return direction * VDASH_SPEED

# ── Gravity Helpers (used by player_move._apply_gravity) ─────────────────────

func is_recovering() -> bool:
	return _recovery_timer > 0.0

func get_recovery_factor() -> float:
	return _recovery_timer / VDASH_GRAVITY_RECOVERY
