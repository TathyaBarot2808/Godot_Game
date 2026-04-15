extends Node2D

@onready var player = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:

	hud.setup(player.mana)
	hud.setup_health(player.health)
	hud.setup_loadout(player.abilities.get_node("LoadoutManager"))
