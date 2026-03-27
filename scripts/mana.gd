extends Node2D
# This script manages the player's magical energy (Mana).
# It handles spending mana, regenerating it over time, and telling the HUD to update.

# Variables marked with "@export" show up in the Godot Editor Inspector
# so you can tweak them easily without opening the code!
@export_group("Mana Settings")
@export var max_mana: float = 100.0        # The absolute maximum mana the player can hold
@export var regen_rate: float = 20.0       # How much mana regenerates per second
@export var regen_delay: float = 2.0       # How many seconds to wait after spending before it regenerates
@export var shoot_cost: float = 5.0        # Mana consumed when firing a bullet (0 = free, shoot anytime)
@export var dash_cost: float = 15.0        # Mana consumed when dashing
@export var recoil_cost: float = 30.0      # Mana consumed when using recoil

# A "signal" is like a radio broadcast. When mana changes, this fires off a message.
# The HUD script is listening to this radio station, so it knows when to update the UI bar!
signal mana_changed(current: float, max: float) 

# These variables track the current state behind the scenes
var current_mana: float                    # How much mana we have exactly right now
var regen_timer: float = 0.0               # A countdown timer that blocks regeneration if > 0

# _ready() is called exactly once when the game starts
func _ready() -> void:
	current_mana = max_mana # Fill the mana bar instantly when spawning

# _process(delta) is called every single frame in the game.
# "delta" is the tiny fraction of a second since the last frame (like 0.016 seconds)
func _process(delta: float) -> void:
	# If the regen_timer is still ticking down (because we just used an ability)
	if regen_timer > 0:
		regen_timer -= delta # Subtract the time passed
		return               # Stop here, do not regenerate mana yet!
		
	# If we reach this point, the delay is over. Let's regenerate mana!
	if current_mana < max_mana:	
		# minf() picks the smallest number. This forces the mana to naturally refill, 
		# but strictly caps it at 'max_mana' so it never overflows above 100.
		current_mana = minf(current_mana + regen_rate * delta, max_mana) 
		
		# Broadcast the new amount to the HUD so the blue bar visually fills up
		mana_changed.emit(current_mana, max_mana) 

# A simple helper function to ask: "Do we have enough mana to do X?"
func can_spend(amount: float) -> bool:
	return current_mana >= amount

# Call this when an ability actually consumes mana
func spend(amount: float) -> void:
	# maxf() picks the largest number. This deducts the mana but prevents it from dropping below 0.
	current_mana = maxf(current_mana - amount, 0.0)
	
	regen_timer = regen_delay                 # Reset the delay timer to stop regeneration temporarily
	mana_changed.emit(current_mana, max_mana) # Broadcast the drop to the HUD

# Call this if the player picks up a mana potion
func restore(amount: float) -> void:
	current_mana = minf(current_mana + amount, max_mana)
	mana_changed.emit(current_mana, max_mana)
