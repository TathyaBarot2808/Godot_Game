extends CharacterBody2D
# This is the main brain of your Player! 
# It handles movement, jumping, falling, dashing, and triggering animations.
# CharacterBody2D is a special Godot node made specifically for moving characters.

# -------------------------------------------------------------------------
# EDITOR SETTINGS
# @export lets us see and change these numbers directly in the Godot Inspector!
# -------------------------------------------------------------------------
@export_group("Movement")
@export var SPEED: float = 600.0             # How fast the player runs left and right
@export var JUMP_VELOCITY: float = -1000.0   # How much upward force is applied when jumping (negative is UP in 2D)
@export var ACCELERATION: float = 3000.0     # How quickly the player reaches top speed on the ground
@export var DECELERATION: float = 2500.0     # How quickly the player stops when letting go of the keys
@export var AIR_ACCELERATION: float = 1800.0 # How quickly the player can change direction in the air
@export var AIR_DECELERATION: float = 800.0  # How quickly the player stops in the air

@export_group("Advanced Jump Mechanics")
@export var BASE_GRAVITY_MULTIPLIER: float = 1.5      # Normal gravity pulling the player down
@export var VARIABLE_JUMP_MULTIPLIER: float = 0.4      # Slices upward speed if the player lets go of jump early (short hop!)
@export var JUMP_BUFFER_TIME: float = 0.1             # Time window to remember a jump press before hitting the ground
@export var COYOTE_TIME: float = 0.1                  # Time window to allow a jump AFTER walking off a ledge
@export var MAX_FALL_SPEED: float = 2000.0            # Terminal velocity (stops the player from falling infinitely fast)
@export var FALL_GRAVITY_MULTIPLIER: float = 5.0      # How heavy gravity feels when falling downward (makes falls feel snappy)

@export_group("Dash")
@export var DASH_SPEED: float = 1800.0                # How fast the dash propels the player
@export var DASH_DURATION: float = 0.12               # How long the dash lasts in seconds
@export var DASH_COOLDOWN: float = 0.5                # How long before the player can dash again

@export_group("Apex Modifiers")
@export var APEX_THRESHOLD: float = 15.0              # The tiny window of vertical speed at the very peak of a jump
@export var APEX_GRAVITY_MULTIPLIER: float = 0.6      # Lowers gravity at the peak to create a "hang time" floaty effect
@export var APEX_SPEED_BOOST: float = 50.0            # Gives a tiny horizontal speed boost at the peak of the jump

@export_group("Corner Correction")
@export var CORNER_CORRECTION_AMOUNT: float = 4.0     # How many pixels to nudge the player if they barely hit their head on a ceiling corner

# -------------------------------------------------------------------------
# INTERNAL STATE VARIABLES (Hidden from the Inspector)
# -------------------------------------------------------------------------
var jump_buffer_timer: float = 0.0  # Counts down the jump buffer
var coyote_timer: float = 0.0       # Counts down coyote time
var dash_timer: float = 0.0         # Counts down the active dash string
var dash_cooldown_timer: float = 0.0# Counts down until dash is ready again
var dash_direction: float = 0.0     # Remembers which way we dashed (-1 is Left, 1 is Right)
var is_dashing: bool = false        # Simple True/False check to see if we are currently dashing

const PROJECTILE_SCENE := preload("res://scenes/player_projectile_sc.tscn") # Loads the bullet into memory so we can spawn it instantly

# -------------------------------------------------------------------------
# COMPONENT REFERENCES
# @onready fetches these nodes the instant the game starts so we can talk to them!
# -------------------------------------------------------------------------
@onready var left_raycast: RayCast2D = $RayCastLeft          # Invisible laser pointing up-left to detect ceiling corners
@onready var right_raycast: RayCast2D = $RayCastRight        # Invisible laser pointing up-right to detect ceiling corners
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D # The main body visual art
@onready var mana: Node2D = $Mana                            # The script managing our magical energy
@onready var fire_point: Node2D = $FirePoint                 # The physical point where bullets spawn
@onready var shoot_effect: AnimatedSprite2D = $ShootEffectSprite # The visual black hole overlay

var is_shooting_action_active: bool = false                  # True if the user pressed shoot and we are waiting for frame 4
var stored_shoot_direction: Vector2 = Vector2.ZERO           # Remembers exactly where the mouse was when the trigger was pulled

# -------------------------------------------------------------------------
# ANIMATION SYNC DICTIONARY
# This tells the script how many pixels to shove the black hole (and bullet spawn) 
# up or down so it matches the bouncy breathing of the base pixel art frame by frame!
# -------------------------------------------------------------------------
var chest_y_offsets: Dictionary = {
	"Idle": [0, 1, 4, 5, 4, 1, 0], # 7 frames
	"Walk": [0, 1, 0, 0, 0, 1, 0, 0, 0, 0], # 10 frames
	"Jump": [-3, -2, -1, 1, 2, 3], # 6 frames
	"Fall": [-5, -6], # 2 frames
	"Dash": [0, 0, 0, 0, 0] # 5 frames
}

const FIRE_POINT_BASE_Y: float = -5.0
const SHOOT_EFFECT_BASE_Y: float = 3.0

# -------------------------------------------------------------------------
# SYSTEM FUNCTIONS
# -------------------------------------------------------------------------
func _ready() -> void:
	# A safety net! If the Godot editor hasn't loaded the ShootEffectSprite properly, try fetching it manually.
	if shoot_effect == null:
		shoot_effect = get_node_or_null("ShootEffectSprite")
		
	# If we found the node successfully...
	if shoot_effect != null:
		# Wire up the "radio signals"! When the frame changes, or the animation ends, run these specific functions.
		shoot_effect.frame_changed.connect(_on_shoot_effect_frame_changed)
		shoot_effect.animation_finished.connect(_on_shoot_effect_animation_finished)
		shoot_effect.hide() # Make sure the black hole is invisible when the game starts
	else:
		push_error("CRITICAL: ShootEffectSprite not found in scene tree!")

# This runs exactly 60 times a second, handling all game physics and movement!
func _physics_process(delta: float) -> void:
	
	# --- TIMER COUNTDOWNS ---
	
	# COYOTE TIME: If on the floor, keep the timer full. If falling, tick it down!
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	# JUMP BUFFER: If we hit jump, fill the timer. Otherwise, tick it down.
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

	# DASH COOLDOWN
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	# --- INPUT HANDLING ---
	
	# DASH INPUT: If they press Dash, and it's cooled down, and they have 15 mana...
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		if mana.can_spend(mana.dash_cost):
			mana.spend(mana.dash_cost) # Deduct mana
			
			# Figure out what direction to dash
			var dir := Input.get_axis("move_left", "move_right")
			if dir == 0: # If not pressing any keys, dash the way we are facing
				dir = -1.0 if animated_sprite.flip_h else 1.0
				
			dash_direction = sign(dir)
			dash_timer = DASH_DURATION
			dash_cooldown_timer = DASH_COOLDOWN
			is_dashing = true
			
			velocity.y = 0.0 # Stop falling while dashing
			velocity.x = dash_direction * DASH_SPEED # Zoom horizontally

	# SHOOT INPUT: If they press Shoot...
	if Input.is_action_just_pressed("shoot") and not is_dashing:
		# Check if they have enough mana
		if mana.can_spend(mana.shoot_cost):
			mana.spend(mana.shoot_cost)
			is_shooting_action_active = true
			
			if shoot_effect != null:
				shoot_effect.show()          # Reveal the black hole
				shoot_effect.play("default") # Start the animation
				shoot_effect.set_frame_and_progress(0, 0.0) # Force it to frame zero instantly
			
			# Snapshot the exact position of the mouse RIGHT NOW so the bullet points exactly where we clicked
			var mouse_pos = get_global_mouse_position()
			stored_shoot_direction = (mouse_pos - fire_point.global_position).normalized()

	# --- DASH EXECUTION ---
	if is_dashing:
		dash_timer -= delta # Count down how long the dash has been active
		if dash_timer <= 0:
			is_dashing = false # Stop dashing when time runs out

	# --- GRAVITY AND JUMP LOGIC ---
	# Fetch natural gravity from the project settings and multiply it by our custom tweak
	var current_gravity := get_gravity() * BASE_GRAVITY_MULTIPLIER

	# Only apply gravity if we are airborne and NOT dashing
	if not is_on_floor() and not is_dashing:
		
		# VARIABLE JUMP HEIGHT: If they let go of the jump button while going up, slash their upward speed!
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= VARIABLE_JUMP_MULTIPLIER

		# APEX HANG-TIME: If they are at the exact top of the jump arc (moving very slowly up or down)
		if abs(velocity.y) < APEX_THRESHOLD:
			current_gravity *= APEX_GRAVITY_MULTIPLIER # Less gravity = floating
			current_speed += APEX_SPEED_BOOST          # More speed = horizontal leap capability
		# FAST FALL: If they pass the apex and start falling down, crank up gravity!
		elif velocity.y > 0:
			current_gravity *= FALL_GRAVITY_MULTIPLIER

		# Actually apply the calculated gravity to the vertical speed
		velocity += current_gravity * delta

		# CAP FALL SPEED: Don't let them fall faster than terminal velocity
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

		# CORNER CORRECTION: If moving upward and we bonk our head, try to nudge around the corner
		if velocity.y < 0 and is_on_ceiling():
			_handle_corner_correction()


	# JUMP EXECUTION: If they hit jump recently (buffer) AND walked off a ledge recently (coyote)... JUMP!
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0 # Reset timers so they don't double jump
		coyote_timer = 0.0

	# --- MOVEMENT CALCULATION ---
	# Gets -1 (Left), 1 (Right), or 0 (Nothing)
	var direction := Input.get_axis("move_left", "move_right")
	var on_ground := is_on_floor()
	var current_speed := SPEED + (APEX_SPEED_BOOST if abs(velocity.y) < APEX_THRESHOLD else 0.0)

	# Sprite Flipping: Make the art face Left or Right based on input
	if direction != 0:
		animated_sprite.flip_h = direction < 0

	# If the character faces Left, physically move the FirePoint and Black hole to the left side!
	if animated_sprite.flip_h:
		fire_point.position.x = -abs(fire_point.position.x)
		if shoot_effect != null:
			shoot_effect.flip_h = true
	else:
		fire_point.position.x = abs(fire_point.position.x)
		if shoot_effect != null:
			shoot_effect.flip_h = false

	# --- ANIMATION STATE MACHINE ---
	# This priority list decides exactly what the Base Sprite should look like right now.
	if is_dashing or (animated_sprite.animation == "Dash" and animated_sprite.is_playing()):
		if animated_sprite.animation != "Dash":
			animated_sprite.play("Dash")
	elif not on_ground:
		if velocity.y < 0:
			if animated_sprite.animation != "Jump":
				animated_sprite.play("Jump")
		elif velocity.y > 0:
			if animated_sprite.animation != "Fall":
				animated_sprite.play("Fall")
	elif direction != 0:
		if animated_sprite.animation != "Walk":
			animated_sprite.play("Walk")
	else:
		var decel := DECELERATION if on_ground else AIR_DECELERATION
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# --- HORIZONTAL MOVEMENT ---
	if not is_dashing:
		if direction != 0:
			# Accelerate towards top speed smoothly
			var accel := ACCELERATION if on_ground else AIR_ACCELERATION
			velocity.x = move_toward(velocity.x, direction * current_speed, accel * delta)
		else:
			# Brake towards zero smoothly (skidding/sliding to a halt)
			var decel := DECELERATION if on_ground else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# --- DYNAMIC CHEST SYNCING ---
	# Grabs exactly what animation/frame the code above just settled on.
	var current_anim := animated_sprite.animation
	var current_frame := animated_sprite.frame
	
	var y_offset := 0.0
	# Reads our dictionary mapping to see how many pixels to shove everything up/down
	if chest_y_offsets.has(current_anim) and current_frame < chest_y_offsets[current_anim].size():
		y_offset = float(chest_y_offsets[current_anim][current_frame])
		
	# Apply that offset!
	fire_point.position.y = FIRE_POINT_BASE_Y + y_offset
	if shoot_effect != null:
		shoot_effect.position.y = SHOOT_EFFECT_BASE_Y + y_offset
	# -----------------------------

	# Godot's built-in magic function that physically moves the character based on all the `velocity` changes above
	move_and_slide()

# Checks if the player's head barely clips a ceiling block, and gently shoves them left/right to slide past it smoothly.
func _handle_corner_correction() -> void:
	var left := $RayCastLeft
	var right := $RayCastRight
	if not left or not right:
		return
	var left_hit: bool = left.is_colliding()
	var right_hit: bool = right.is_colliding()
	if left_hit == right_hit:
		return
	if not left_hitting and not right_hitting:
		return

	if left_hitting and not right_hitting:
		global_position.x += CORNER_CORRECTION_AMOUNT
	elif right_hitting and not left_hitting:
		global_position.x -= CORNER_CORRECTION_AMOUNT

# -------------------------------------------------------------------------
# EFFECT SIGNAL HANDLERS
# -------------------------------------------------------------------------

# This triggers every time the black hole's image updates to the next frame
func _on_shoot_effect_frame_changed() -> void:
	if shoot_effect.animation == "default":
		# When it hits frame 4 exactly, pull the trigger!
		if shoot_effect.frame == 4:
			if is_shooting_action_active:
				_fire_projectile()
				is_shooting_action_active = false
		# When it hits the last frame (7), kill the animation so it vanishes.
		elif shoot_effect.frame == 7:
			shoot_effect.hide()
			shoot_effect.stop()

# A failsafe just in case the animation naturally ends
func _on_shoot_effect_animation_finished() -> void:
	if shoot_effect.animation == "default":
		shoot_effect.hide()

# The actual function that puts the bullet into the world
func _fire_projectile() -> void:
	# 'instantiate' clones the bullet scene into reality
	var proj = PROJECTILE_SCENE.instantiate()
	
	# Fetch our snapshotted target direction from back when the player first clicked
	var dir = stored_shoot_direction
	
	# If they literally clicked perfectly on themselves (dir length 0), default to facing forward
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT
		
	# Configure the newly born bullet's starting state
	proj.global_position = fire_point.global_position
	proj.direction = dir
	proj.rotation = dir.angle() # Turn the visual artwork so it points forward
	
	# Toss the bullet into the actual Level's node tree so the physics engine can see it!
	get_tree().current_scene.add_child(proj)
