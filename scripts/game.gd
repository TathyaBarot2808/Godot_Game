extends Node2D
# This is the master script for your Level/Scene.
# It acts as the manager that connects different parts of the game together.

# Grab references to the Player and the HUD that exist in the level
@onready var player = $Player
@onready var hud: CanvasLayer = $HUD

# _ready() runs the moment the level finishes loading
func _ready() -> void:
	# The HUD needs to know whose mana it should be displaying.
	# Here, the Game script essentially introduces the HUD to the Player's mana pool
	# so they can talk to each other without being directly tangled up.
	hud.setup(player.mana)
	hud.setup_loadout(player.abilities.get_node("LoadoutManager"))
