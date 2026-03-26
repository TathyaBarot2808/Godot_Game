extends CharacterBody2D

# ── Constants ─────────────────────────────────────────────────────────────────

@export_group("Movement")
@export var SPEED: float = 600.0
@export var JUMP_VELOCITY: float = -1000.0
@export var ACCELERATION: float = 3000.0
@export var DECELERATION: float = 2500.0
@export var AIR_ACCELERATION: float = 1800.0
@export var AIR_DECELERATION: float = 800.0

@export_group("Advanced Jump Mechanics")
@export var BASE_GRAVITY_MULTIPLIER: float = 1.5
@export var VARIABLE_JUMP_MULTIPLIER: float = 0.4
@export var JUMP_BUFFER_TIME: float = 0.1
@export var COYOTE_TIME: float = 0.1
@export var MAX_FALL_SPEED: float = 2000.0
@export var FALL_GRAVITY_MULTIPLIER: float = 5.0

@export_group("Apex Modifiers")
@export var APEX_THRESHOLD: float = 15.0
@export var APEX_GRAVITY_MULTIPLIER: float = 0.6
@export var APEX_SPEED_BOOST: float = 50.0

@export_group("Corner Correction")
@export var CORNER_CORRECTION_AMOUNT: float = 4.0

# ── State ─────────────────────────────────────────────────────────────────────

var _jump_buffer_timer: float = 0.0
var _coyote_timer: float = 0.0

# ── Node Refs ─────────────────────────────────────────────────────────────────

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mana: Node = $Mana
@onready var abilities: AbilitiesManager = $AbilitiesManager
@onready var loadout: LoadoutManager = $AbilitiesManager/LoadoutManager
@onready var _recoil: Node = $AbilitiesManager/recoil
@onready var _dash: Node = $AbilitiesManager/dash
@onready var _vdash: Node = $AbilitiesManager/vdash

# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_dash.dash_started.connect(_on_dash_started)
	_vdash.vdash_started.connect(_on_dash_started)
	sprite.animation_finished.connect(_on_animation_finished)

func _on_dash_started() -> void:
	sprite.play("Dash")

func _on_animation_finished() -> void:
	if sprite.animation == &"Dash":
		sprite.play("Idle")

# ── Main Loop ─────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	_tick_coyote(delta)
	_tick_jump_buffer(delta)
	_apply_gravity(delta)
	_handle_slot_switch()
	if loadout.get_active_ability() == "dash":	
		_handle_dash()
	if loadout.get_active_ability()=="vdash":
		_handle_vdash()	
	_handle_shoot()
	_handle_jump()
	_handle_movement(delta)
	_update_animation(Input.get_axis("move_left", "move_right"))
	move_and_slide()

# ── Slot Switching ────────────────────────────────────────────────────────────

func _handle_slot_switch() -> void:
	if Input.is_action_just_pressed("slot_1"):
		loadout.set_active_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		loadout.set_active_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		loadout.set_active_slot(2)

# ── Shoot — routes to active loadout slot ─────────────────────────────────────

# ── Dash — dedicated Shift shortcut, bypasses loadout slot ──────────────────

func _handle_dash() -> void:
	if Input.is_action_just_pressed("dash"):
		_execute_dash()

func _handle_vdash() ->void:
	if Input.is_action_just_pressed("vdash"):
		_execute_vdash()
# ── Shoot — routes to active loadout slot ─────────────────────────────────────

func _handle_shoot() -> void:
	if not Input.is_action_just_pressed("shoot"):
		return

	var ability := loadout.get_active_ability()
	if ability == "":
		return

	if not abilities.can_use(ability):
		return

	match ability:
		"recoil":
			_execute_recoil()
		"dash":
			_execute_dash()
		"vdash":
			_execute_vdash()
		_:
			push_error("player_move: no handler for ability -> " + ability)

func _execute_recoil() -> void:
	if abilities.is_active("dash"):
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
	if abilities.is_active("recoil"):
		return
	if not mana.can_spend(mana.dash_cost):
		return

	var dir := Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		dir = -1.0 if sprite.flip_h else 1.0

	var result: Variant = abilities.execute("dash", {"direction": dir})
	if result != null:
		mana.spend(mana.dash_cost)
		velocity = result

func _execute_vdash() -> void:
	if abilities.is_active("recoil") or abilities.is_active("dash"):
		return
	if not mana.can_spend(mana.vdash_cost):
		return
	var mouse_pos := get_global_mouse_position()
	var dir := (mouse_pos - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var result: Variant = abilities.execute("vdash", {"direction": dir})
	if result != null:
		mana.spend(mana.vdash_cost)
		velocity = result
# ── Jump ──────────────────────────────────────────────────────────────────────

func _handle_jump() -> void:
	if _jump_buffer_timer > 0 and _coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

# ── Gravity ───────────────────────────────────────────────────────────────────

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	if abilities.is_active("recoil") or abilities.is_active("dash") or abilities.is_active("vdash"):
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
	if _vdash.is_recovering():
		current_gravity *= _vdash.get_recovery_factor()

	velocity += current_gravity * delta
	velocity.y = minf(velocity.y, MAX_FALL_SPEED)

	if velocity.y < 0 and is_on_ceiling():
		_handle_corner_correction()

# ── Movement ──────────────────────────────────────────────────────────────────

func _handle_movement(delta: float) -> void:
	if abilities.is_active("recoil") or abilities.is_active("dash") or abilities.is_active("vdash"):
		return

	var direction := Input.get_axis("move_left", "move_right")
	var on_ground := is_on_floor()
	var current_speed := SPEED + (APEX_SPEED_BOOST if abs(velocity.y) < APEX_THRESHOLD else 0.0)

	if direction != 0:
		var accel := ACCELERATION if on_ground else AIR_ACCELERATION
		velocity.x = move_toward(velocity.x, direction * current_speed, accel * delta)
	else:
		var decel := DECELERATION if on_ground else AIR_DECELERATION
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)

# ── Timers ────────────────────────────────────────────────────────────────────

func _tick_coyote(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta

func _tick_jump_buffer(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta

# ── Animation ─────────────────────────────────────────────────────────────────

func _update_animation(direction: float) -> void:
	if sprite.animation == &"Dash" and sprite.is_playing():
		return
	if abilities.is_active("recoil"):
		return
	if not is_on_floor():
		sprite.play("Jump" if velocity.y < 0 else "Fall")
		return
	if direction != 0:
		sprite.play("Walk")
		sprite.flip_h = direction < 0
	else:
		sprite.play("Idle")

# ── Corner Correction ─────────────────────────────────────────────────────────

func _handle_corner_correction() -> void:
	var left := $RayCastLeft
	var right := $RayCastRight
	if not left or not right:
		return
	var left_hit: bool = left.is_colliding()
	var right_hit: bool = right.is_colliding()
	if left_hit == right_hit:
		return
	global_position.x += CORNER_CORRECTION_AMOUNT * (-1.0 if left_hit else 1.0)
