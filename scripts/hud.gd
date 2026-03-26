extends CanvasLayer
# This script manages the user interface (heads-up display).
# It updates the blue mana bar on the screen whenever the player uses mana.

# @onready grabs these UI elements from the scene as soon as the HUD is created
@onready var mana_bar: ProgressBar = $ManaContainer/ManaBar
@onready var mana_label: Label = $ManaContainer/ManaLabel

# Array of the 3 slot Panel nodes for easy looping
@onready var _slots: Array = [
	$LoadoutContainer/Slot0,
	$LoadoutContainer/Slot1,
	$LoadoutContainer/Slot2,
]

# setup() is called by the Game script when the level starts.
# We pass it the player's internal 'mana_node' so the HUD knows what to listen to.
func setup(mana_node: Node) -> void:
	# Connect the "radio broadcast" (signal) from the mana script.
	# Whenever the player uses or regenerates mana, the mana_node yells "mana_changed!",
	# and this line tells the HUD to immediately run the _on_mana_changed() function below.
	mana_node.mana_changed.connect(_on_mana_changed)
	
	# We manually refresh the UI once at the very start so it doesn't appear empty
	_refresh(mana_node.current_mana, mana_node.max_mana)

# This function runs automatically every time the player's mana goes up or down
func _on_mana_changed(current: float, max_value: float) -> void:
	_refresh(current, max_value)

# This physically changes the pixels and text on your screen
func _refresh(current: float, max_value: float) -> void:
	mana_bar.max_value = max_value
	mana_bar.value = current
	
	# %d means "insert a whole number here". This writes e.g., "Mana: 85 / 100"
	mana_label.text = "Mana: %d / %d" % [current, max_value]

# --- Loadout Setup (Modular Ability System) ---

# setup_loadout() connects the HUD to the player's ability slots
func setup_loadout(loadout_node: Node) -> void:
	# Listen for any loadout change (slot switch OR equip/unequip)
	loadout_node.loadout_changed.connect(_on_loadout_changed.bind(loadout_node))
	# Set initial state so HUD isn't empty on first frame
	_refresh_loadout(loadout_node)

# This runs whenever the player switches their active slot or changes abilities
func _on_loadout_changed(loadout_node: Node) -> void:
	_refresh_loadout(loadout_node)

# This physically updates the high-light and labels for the 3 ability slots
func _refresh_loadout(loadout_node: Node) -> void:
	for i in 3:
		var slot_panel = _slots[i]
		var highlight: Panel = slot_panel.get_node("Highlight")
		var label: Label = slot_panel.get_node("AbilityLabel")

		# Show ability name or "---" if empty
		var ability: String = loadout_node.loadout[i]
		label.text = ability if ability != "" else "---"

		# Only the active slot gets the visual highlight
		highlight.visible = (i == loadout_node.active_slot)
