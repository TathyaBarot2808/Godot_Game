extends CanvasLayer

@onready var mana_bar: ProgressBar = $ManaContainer/ManaBar
@onready var mana_label: Label = $ManaContainer/ManaLabel
@onready var health_bar: ProgressBar = $HealthContainer/HealthBar
@onready var health_label: Label = $HealthContainer/HealthLabel

@onready var _slots: Array = [
	$LoadoutContainer/Slot0,
	$LoadoutContainer/Slot1,
	$LoadoutContainer/Slot2,
]

func setup(mana_node: Node) -> void:

	mana_node.mana_changed.connect(_on_mana_changed)

	_refresh(mana_node.current_mana, mana_node.max_mana)

func setup_health(health_node: Node) -> void:
	health_node.health_changed.connect(_on_health_changed)
	_refresh_health(health_node.current_health, health_node.max_health)

func _on_health_changed(current: float, max_value: float) -> void:
	_refresh_health(current, max_value)

func _on_mana_changed(current: float, max_value: float) -> void:
	_refresh(current, max_value)

func _refresh(current: float, max_value: float) -> void:
	mana_bar.max_value = max_value
	mana_bar.value = current

	mana_label.text = "Mana: %d / %d" % [current, max_value]

func _refresh_health(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current
	health_label.text = "Health: %d / %d" % [current, max_value]

func setup_loadout(loadout_node: Node) -> void:

	loadout_node.loadout_changed.connect(_on_loadout_changed.bind(loadout_node))

	_refresh_loadout(loadout_node)

func _on_loadout_changed(loadout_node: Node) -> void:
	_refresh_loadout(loadout_node)

func _refresh_loadout(loadout_node: Node) -> void:
	for i in 3:
		var slot_panel = _slots[i]
		var highlight: Panel = slot_panel.get_node("Highlight")
		var label: Label = slot_panel.get_node("AbilityLabel")

		var ability: String = loadout_node.loadout[i]
		label.text = ability if ability != "" else "---"

		highlight.visible = (i == loadout_node.active_slot)
