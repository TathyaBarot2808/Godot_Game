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
var is_dashing: bool = false        # Simple True/False check to see if we are currently dashing

@onready var abilities: AbilitiesManager = $AbilitiesManager
@onready var loadout: LoadoutManager = $AbilitiesManager/LoadoutManager

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
@onready var _dash_comp: Node = $AbilitiesManager/dash       # Reference to the modular dash behavior
@onready var _recoil: Node = $AbilitiesManager/recoil        # Reference to the recoil ability

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
	# Connect to modular ability signals
	if _dash_comp:
		_dash_comp.dash_started.connect(_on_dash_started)
		_dash_comp.dash_ended.connect(_on_dash_ended)

	if shoot_effect != null:
		shoot_effect.frame_changed.connect(_on_shoot_effect_frame_changed)
		shoot_effect.animation_finished.connect(_on_shoot_effect_animation_finished)
		shoot_effect.hide()
	else:
		push_error("CRITICAL: ShootEffectSprite not found!")

func _physics_process(delta: float) -> void:
	# Tick down timers
	_tick_coyote(delta)
	_tick_jump_buffer(delta)
	_apply_gravity(delta)
	
	# --- INNATE ABILITIES (always available, not tied to loadout) ---
	_handle_innate_shoot()     # LMB → projectile with black hole effect
	
	# --- LOADOUT ABILITIES (future equippable skills) ---
	_handle_slot_switch()
	_handle_loadout_ability()

	# Standard Movement
	_handle_jump()
	_handle_movement(delta)
	_update_animation_and_sync()
	
	move_and_slide()

# --- INNATE ABILITY HANDLERS ---

# Shoot: Fires on LMB, always available regardless of loadout
# Blocked when recoil is the active loadout ability (it handles LMB instead)
func _handle_innate_shoot() -> void:
	if not Input.is_action_just_pressed("shoot"):
		return
	# if loadout.get_active_ability() == "recoil":
	# 	return  # recoil takes priority over innate shoot
	# if is_dashing or is_shooting_action_active:
	# 	return
	if not mana.can_spend(mana.shoot_cost):
		return

	mana.spend(mana.shoot_cost)
	is_shooting_action_active = true
	stored_shoot_direction = (get_global_mouse_position() - fire_point.global_position).normalized()

	if shoot_effect:
		shoot_effect.show()
		shoot_effect.play("default")
		shoot_effect.set_frame_and_progress(0, 0.0)

# --- LOADOUT ABILITY HANDLERS (for future equippable abilities) ---

func _handle_slot_switch() -> void:
	if Input.is_action_just_pressed("slot_1"):
		loadout.set_active_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		loadout.set_active_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		loadout.set_active_slot(2)

# This handles equippable abilities from the loadout (not innate dash or shoot)
func _handle_loadout_ability() -> void:
	var ability := loadout.get_active_ability()
	match ability:
		"recoil":
			if Input.is_action_just_pressed("recoil"):
				_execute_recoil()
		"dash":
			if Input.is_action_just_pressed("dash"):
				_execute_dash()

func _execute_recoil() -> void:
	if is_dashing:
		return
	if not mana.can_spend(mana.shoot_cost):
		return
	var mouse_pos := get_global_mouse_position()
	var dir := (global_position - mouse_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var result: Variant = abilities.execute("recoil", {"direction": dir})
	if result != null:
		mana.spend(mana.shoot_cost)
		velocity = result

func _execute_dash() -> void:
	if not abilities.can_use("dash"):
		return
	if not mana.can_spend(mana.dash_cost):
		return
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = Vector2.LEFT if animated_sprite.flip_h else Vector2.RIGHT
	var result: Variant = abilities.execute("dash", {"direction": dir})
	if result is Vector2:
		velocity = result
	mana.spend(mana.dash_cost)

func _on_dash_started() -> void:
	is_dashing = true
	animated_sprite.play("Dash")

func _on_dash_ended() -> void:
	# Velocity is done — player stops zooming.
	# We do NOT interrupt the animation here; we let it finish naturally.
	# is_dashing stays true until the animation itself ends.
	pass

# --- MOVEMENT HELPERS ---

func _tick_coyote(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

func _tick_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta

func _apply_gravity(delta: float) -> void:
	if is_on_floor() or is_dashing or abilities.is_active("recoil"):
		return

	var current_gravity := get_gravity() * BASE_GRAVITY_MULTIPLIER
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= VARIABLE_JUMP_MULTIPLIER

	if abs(velocity.y) < APEX_THRESHOLD:
		current_gravity *= APEX_GRAVITY_MULTIPLIER
	elif velocity.y > 0:
		current_gravity *= FALL_GRAVITY_MULTIPLIER

	if _recoil.is_recovering():
		current_gravity *= _recoil.get_recovery_factor()

	velocity += current_gravity * delta
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)

	if velocity.y < 0 and (left_raycast.is_colliding() or right_raycast.is_colliding()):
		_handle_corner_correction()

func _handle_jump() -> void:
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

func _handle_movement(delta: float) -> void:
	if is_dashing or abilities.is_active("recoil"):
		return

	var direction := Input.get_axis("move_left", "move_right")
	var current_speed := SPEED + (APEX_SPEED_BOOST if abs(velocity.y) < APEX_THRESHOLD else 0.0)

	if direction != 0:
		var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction * current_speed, accel * delta)
		animated_sprite.flip_h = direction < 0
	else:
		var decel := DECELERATION if is_on_floor() else AIR_DECELERATION
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# Side Flipping for utility nodes
	if animated_sprite.flip_h:
		fire_point.position.x = -abs(fire_point.position.x)
		if shoot_effect: shoot_effect.flip_h = true
	else:
		fire_point.position.x = abs(fire_point.position.x)
		if shoot_effect: shoot_effect.flip_h = false

func _update_animation_and_sync() -> void:
	# If the Dash animation is still playing, don't override it.
	# We also listen for when it finishes to clear the is_dashing flag.
	if animated_sprite.animation == "Dash":
		if animated_sprite.is_playing():
			return  # Let it finish
		else:
			is_dashing = false  # Animation done — now we can switch states
		
	if not is_on_floor():
		animated_sprite.play("Jump" if velocity.y < 0 else "Fall")
	elif abs(velocity.x) > 0.1:
		animated_sprite.play("Walk")
	else:
		animated_sprite.play("Idle")

	# Physical Syncing
	var anim := animated_sprite.animation
	var frame := animated_sprite.frame
	var y_off := 0.0
	if chest_y_offsets.has(anim) and frame < chest_y_offsets[anim].size():
		y_off = float(chest_y_offsets[anim][frame])
		
	fire_point.position.y = FIRE_POINT_BASE_Y + y_off
	if shoot_effect:
		shoot_effect.position.y = SHOOT_EFFECT_BASE_Y + y_off

func _handle_corner_correction() -> void:
	if left_raycast.is_colliding() and not right_raycast.is_colliding():
		global_position.x += CORNER_CORRECTION_AMOUNT
	elif right_raycast.is_colliding() and not left_raycast.is_colliding():
		global_position.x -= CORNER_CORRECTION_AMOUNT

# --- SHOOT EFFECT HANDLERS ---

func _on_shoot_effect_frame_changed() -> void:
	if shoot_effect.animation == "default" and shoot_effect.frame == 4:
		_fire_projectile()
		is_shooting_action_active = false  # Reset so the player can shoot again
	elif shoot_effect.frame == 7:
		shoot_effect.hide()
		shoot_effect.stop()

func _on_shoot_effect_animation_finished() -> void:
	shoot_effect.hide()

func _fire_projectile() -> void:
	var proj = PROJECTILE_SCENE.instantiate()
	var dir = stored_shoot_direction
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT if not animated_sprite.flip_h else Vector2.LEFT
		
	proj.global_position = fire_point.global_position
	proj.direction = dir
	proj.rotation = dir.angle()
	get_tree().current_scene.add_child(proj)
