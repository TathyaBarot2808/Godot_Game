extends CanvasLayer

@onready var mana_bar: ProgressBar = $ManaContainer/ManaBar
@onready var mana_label: Label = $ManaContainer/ManaLabel

# Array of the 3 slot Panel nodes for easy looping
@onready var _slots: Array = [
	$LoadoutContainer/Slot0,
	$LoadoutContainer/Slot1,
	$LoadoutContainer/Slot2,
]

# ── Mana setup (existing) ─────────────────────────────────

func setup(mana_node: Node) -> void:
	mana_node.mana_changed.connect(_on_mana_changed)
	_refresh_mana(mana_node.current_mana, mana_node.max_mana)

func _on_mana_changed(current: float, max: float) -> void:
	_refresh_mana(current, max)

func _refresh_mana(current: float, max: float) -> void:
	mana_bar.max_value = max
	mana_bar.value = current
	mana_label.text = "Mana: %d / %d" % [current, max]

# ── Loadout setup (new) ───────────────────────────────────

func setup_loadout(loadout_node: LoadoutManager) -> void:
	# Listen for any loadout change (slot switch OR equip/unequip)
	loadout_node.loadout_changed.connect(_on_loadout_changed.bind(loadout_node))
	# Set initial state so HUD isn't empty on first frame
	_refresh_loadout(loadout_node)

func _on_loadout_changed(loadout_node: LoadoutManager) -> void:
	_refresh_loadout(loadout_node)

func _refresh_loadout(loadout_node: LoadoutManager) -> void:
	for i in 3:
		var slot_panel = _slots[i]
		var highlight: Panel = slot_panel.get_node("Highlight")
		var label: Label = slot_panel.get_node("AbilityLabel")

		# Show ability name or "---" if empty
		var ability: String = loadout_node.loadout[i]
		label.text = ability if ability != "" else "---"

		# Only the active slot gets the highlight
		highlight.visible = (i == loadout_node.active_slot)
