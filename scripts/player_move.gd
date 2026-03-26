extends CharacterBody2D

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

var _jump_buffer_timer: float = 0.0
var _coyote_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mana: Node = $Mana
@onready var abilities: AbilitiesManager = $AbilitiesManager
# Typed refs for helpers that need ability-specific methods beyond the base interface
@onready var _recoil: Node = $AbilitiesManager/recoil
@onready var _dash: Node = $AbilitiesManager/dash

func _ready() -> void:
	_dash.dash_started.connect(_on_dash_started)
	sprite.animation_finished.connect(_on_animation_finished)

func _on_dash_started() -> void:
	sprite.play("Dash")

func _on_animation_finished() -> void:
	if sprite.animation == &"Dash":
		sprite.play("Idle")

func _physics_process(delta: float) -> void:
	_tick_coyote(delta)
	_tick_jump_buffer(delta)
	_apply_gravity(delta)
	_handle_shoot()
	_handle_dash()
	_handle_jump()
	_handle_movement(delta)
	_update_animation(Input.get_axis("move_left", "move_right"))
	move_and_slide()

# ── Input Handlers ────────────────────────────────────────────────────────────

func _handle_shoot() -> void:
	if not Input.is_action_just_pressed("shoot"):
		return
	if abilities.is_active("dash"):
		return
	if not mana.can_spend(mana.shoot_cost):
		return
	var mouse_pos := get_global_mouse_position()
	var dir := (global_position - mouse_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	var result = abilities.execute("recoil", {"direction": dir})
	if result != null:
		mana.spend(mana.shoot_cost)
		velocity = result

func _handle_dash() -> void:
	if not Input.is_action_just_pressed("dash"):
		return
	if abilities.is_active("recoil"):
		return
	if not mana.can_spend(mana.dash_cost):
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir == 0.0:
		dir = -1.0 if sprite.flip_h else 1.0
	var result = abilities.execute("dash", {"direction": dir})
	if result != null:
		mana.spend(mana.dash_cost)
		velocity = result

func _handle_jump() -> void:
	if _jump_buffer_timer > 0 and _coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

# ── Movement & Gravity ────────────────────────────────────────────────────────

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	if abilities.is_active("recoil") or abilities.is_active("dash"):
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED
		if velocity.y < 0 and is_on_ceiling():
			_handle_corner_correction()
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

	if velocity.y > MAX_FALL_SPEED:
		velocity.y = MAX_FALL_SPEED

	if velocity.y < 0 and is_on_ceiling():
		_handle_corner_correction()

func _handle_movement(delta: float) -> void:
	if abilities.is_active("recoil") or abilities.is_active("dash"):
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
	# Let Dash animation play to completion — _on_animation_finished handles the transition
	if sprite.animation == &"Dash" and sprite.is_playing():
		return
	if abilities.is_active("dash"):
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
