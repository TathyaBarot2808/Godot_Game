extends Node
class_name AbilitiesManager

var _unlocked: Dictionary = {
	"shoot": true,
	"dash":  true,
	"recoil": true,
	"walljump": true
}

var _components: Dictionary = {}
func _ready() -> void:
	for child in get_children():
		if child is AbilityBase:
			_components[child.name.to_lower()] = child

func can_use(ability_name: String) -> bool:
	if not _is_unlocked(ability_name):
		return false
	var component := _get_component(ability_name)
	if not component:
		return false
	return component.can_use()

func execute(ability_name: String, args: Dictionary = {}) -> Variant:
	if not can_use(ability_name):
		return null
	return _get_component(ability_name).trigger(args)

func is_active(ability_name: String) -> bool:
	var component := _get_component(ability_name)
	return component.is_active() if component else false

func unlock(ability_name: String) -> void:
	if ability_name not in _unlocked:
		push_error("AbilitiesManager: unknown ability -> " + ability_name)
		return
	_unlocked[ability_name] = true

func lock(ability_name: String) -> void:
	if ability_name in _unlocked:
		_unlocked[ability_name] = false

func is_unlocked(ability_name: String) -> bool:
	return _unlocked.get(ability_name, false)

func _is_unlocked(ability_name: String) -> bool:
	return is_unlocked(ability_name)

func get_unlocked_abilities() -> Array[String]:
	var result: Array[String] = []
	for ability_name in _unlocked:
		if _unlocked[ability_name]:
			result.append(ability_name)
	return result

func _get_component(ability_name: String) -> AbilityBase:
	return _components.get(ability_name, null)
