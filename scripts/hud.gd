extends CanvasLayer

@onready var mana_bar: ProgressBar = $ManaContainer/ManaBar
@onready var mana_label: Label = $ManaContainer/ManaLabel

func setup(mana_node: Node) -> void:
	# Connect signal — whenever mana changes, _on_mana_changed is called
	mana_node.mana_changed.connect(_on_mana_changed)
	# Set initial values so UI isn't empty on first frame
	_refresh(mana_node.current_mana, mana_node.max_mana)

func _on_mana_changed(current: float, max: float) -> void:
	_refresh(current, max)

func _refresh(current: float, max: float) -> void:
	mana_bar.max_value = max
	mana_bar.value = current
	mana_label.text = "Mana: %d / %d" % [current, max]
