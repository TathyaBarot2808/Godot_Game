extends Node
class_name AbilitiesManager

# Unlock state — edit defaults here or call unlock() at runtime (e.g. from a pickup)
var _unlocked: Dictionary = {
	"recoil": true,   # player starts with recoil (shoot)
	"dash":   true,  # locked until unlocked by gameplay
	"vdash": true,
}

# Populated automatically in _ready from child AbilityBase nodes
var _components: Dictionary = {}
func _ready() -> void:
	for child in get_children():
		if child is AbilityBase:
			_components[child.name.to_lower()] = child

# ── Public API ────────────────────────────────────────────────────────────────

# Returns true if the ability is unlocked AND currently usable (no cooldown, not active, etc.)
func can_use(ability_name: String) -> bool:
	if not _is_unlocked(ability_name):
		return false
	var component := _get_component(ability_name)
	if not component:
		return false
	return component.can_use()

# Runs the ability if allowed. Returns the result (e.g. velocity Vector2), or null if blocked.
func execute(ability_name: String, args: Dictionary = {}) -> Variant:
	if not can_use(ability_name):
		return null
	return _get_component(ability_name).trigger(args)

# Returns true if the ability is currently mid-execution
func is_active(ability_name: String) -> bool:
	var component := _get_component(ability_name)
	return component.is_active() if component else false

# ── Unlock System ─────────────────────────────────────────────────────────────

func unlock(ability_name: String) -> void:
	if ability_name not in _unlocked:
		push_error("AbilitiesManager: unknown ability -> " + ability_name)
		return
	_unlocked[ability_name] = true

func lock(ability_name: String) -> void:
	if ability_name in _unlocked:
		_unlocked[ability_name] = false

func _is_unlocked(ability_name: String) -> bool:
	return _unlocked.get(ability_name, false)
	
func get_unlocked_abilities() -> Array[String]:
	var result: Array[String] = []
	for ability_name in _unlocked:
		if _unlocked[ability_name]:
			result.append(ability_name)
	return result

# ── Private ───────────────────────────────────────────────────────────────────

func _get_component(ability_name: String) -> AbilityBase:
	return _components.get(ability_name, null)
