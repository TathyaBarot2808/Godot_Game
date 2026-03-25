extends Node2D

@onready var player = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	# Connect HUD to the player's Mana node so the bar updates on mana_changed signal
	hud.setup(player.mana)
