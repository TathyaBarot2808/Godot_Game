extends Node
class_name HealthComponent

signal health_changed(current: float, max_value: float)
signal damaged(amount: float, current: float, max_value: float)
signal healed(amount: float, current: float, max_value: float)
signal died

@export_group("Health")
@export var max_health: float = 100.0
@export var start_health: float = -1.0 # -1 means start at max_health

@export_group("Death Handling")
@export var auto_destroy_owner: bool = false
@export var destroy_owner_delay: float = 0.0

var current_health: float = 0.0
var _dead: bool = false

func _ready() -> void:
	max_health = maxf(max_health, 1.0)
	if start_health < 0.0:
		current_health = max_health
	else:
		current_health = clampf(start_health, 0.0, max_health)
	_emit_health_changed()
	if current_health <= 0.0:
		_dead = true

func take_damage(amount: float) -> float:
	if amount <= 0.0 or _dead:
		return 0.0
	var old := current_health
	current_health = maxf(current_health - amount, 0.0)
	var applied := old - current_health
	if applied <= 0.0:
		return 0.0
	emit_signal("damaged", applied, current_health, max_health)
	_emit_health_changed()
	if current_health <= 0.0:
		_handle_death()
	return applied

func damage(amount: float) -> float:
	return take_damage(amount)

func heal(amount: float) -> float:
	if amount <= 0.0 or _dead:
		return 0.0
	var old := current_health
	current_health = minf(current_health + amount, max_health)
	var applied := current_health - old
	if applied <= 0.0:
		return 0.0
	emit_signal("healed", applied, current_health, max_health)
	_emit_health_changed()
	return applied

func set_max_health(value: float, keep_ratio: bool = true) -> void:
	var safe_value := maxf(value, 1.0)
	if keep_ratio and max_health > 0.0:
		var ratio := current_health / max_health
		max_health = safe_value
		current_health = clampf(ratio * max_health, 0.0, max_health)
	else:
		max_health = safe_value
		current_health = clampf(current_health, 0.0, max_health)
	_emit_health_changed()
	if current_health <= 0.0 and not _dead:
		_handle_death()

func is_dead() -> bool:
	return _dead

func reset_health() -> void:
	current_health = max_health
	_dead = false
	_emit_health_changed()

func get_health_percent() -> float:
	return current_health / max_health if max_health > 0.0 else 0.0

func _emit_health_changed() -> void:
	emit_signal("health_changed", current_health, max_health)

func _handle_death() -> void:
	if _dead:
		return
	_dead = true
	emit_signal("died")
	if auto_destroy_owner:
		if destroy_owner_delay <= 0.0:
			_queue_free_owner()
		else:
			var timer := get_tree().create_timer(destroy_owner_delay)
			timer.timeout.connect(_queue_free_owner, CONNECT_ONE_SHOT)

func _queue_free_owner() -> void:
	var owner_node := get_parent()
	if owner_node and is_instance_valid(owner_node):
		owner_node.queue_free()
