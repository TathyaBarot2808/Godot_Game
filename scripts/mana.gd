extends Node2D

@export_group("Mana Settings")
@export var max_mana: float = 100.0
@export var regen_rate: float = 20.0
@export var regen_delay: float = 2.0
@export var shoot_cost: float = 5.0
@export var dash_cost: float = 15.0
@export var recoil_cost: float = 30.0
@export var walljump_cost: float = 10.0

signal mana_changed(current: float, max: float)

var current_mana: float
var regen_timer: float = 0.0

func _ready() -> void:
	current_mana = max_mana

func _process(delta: float) -> void:

	if regen_timer > 0:
		regen_timer -= delta
		return

	if current_mana < max_mana:

		current_mana = minf(current_mana + regen_rate * delta, max_mana)

		mana_changed.emit(current_mana, max_mana)

func can_spend(amount: float) -> bool:
	return current_mana >= amount

func spend(amount: float) -> void:

	current_mana = maxf(current_mana - amount, 0.0)

	regen_timer = regen_delay
	mana_changed.emit(current_mana, max_mana)

func restore(amount: float) -> void:
	current_mana = minf(current_mana + amount, max_mana)
	mana_changed.emit(current_mana, max_mana)
