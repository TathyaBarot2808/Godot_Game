extends Node
class_name AbilityBase

# Base class for all player abilities.
# Every ability must override these three functions.

func trigger(_args: Dictionary) -> Variant:
	push_error("trigger() not implemented in: " + name)
	return null

func can_use() -> bool:
	push_error("can_use() not implemented in: " + name)
	return false

func is_active() -> bool:
	return false
