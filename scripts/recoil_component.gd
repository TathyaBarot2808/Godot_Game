extends AbilityBase

@export_group("Shotgun Recoil")
@export var RECOIL_SPEED: float = 1500.0
@export var RECOIL_DURATION: float = 0.1
@export var RECOIL_GRAVITY_RECOVERY: float = 0.15

var _recoil_timer: float = 0.0
var _recovery_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if _recoil_timer > 0:
		_recoil_timer -= delta
		if _recoil_timer <= 0:
			_recovery_timer = RECOIL_GRAVITY_RECOVERY
	if _recovery_timer > 0:
		_recovery_timer -= delta

# ── AbilityBase interface ─────────────────────────────────────────────────────

func can_use() -> bool:
	return not is_active()

# args: { "direction": Vector2 }
func trigger(args: Dictionary) -> Variant:
	var direction: Vector2 = args.get("direction", Vector2.UP)
	_recoil_timer = RECOIL_DURATION
	_recovery_timer = 0.0
	return direction * RECOIL_SPEED

func is_active() -> bool:
	return _recoil_timer > 0

# ── Recoil-specific helpers (used by player_move.gd via typed ref) ────────────

func is_recovering() -> bool:
	return _recovery_timer > 0

func get_recovery_factor() -> float:
	# Returns 0.0 → 1.0 ramp as recovery completes (eases gravity back in)
	if _recovery_timer <= 0:
		return 1.0
	return 1.0 - (_recovery_timer / RECOIL_GRAVITY_RECOVERY)
