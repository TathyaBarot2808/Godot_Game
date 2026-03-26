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

# --- timers ---
var _jump_buffer_timer: float = 0.0
var _coyote_timer: float = 0.0

# --- node refs ---
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mana: Node = $Mana
@onready var recoil: Node = $RecoilComponent
@onready var dash: Node = $DashComponent

func _ready() -> void:
	# Connect dash signals directly to animation functions
	dash.dash_started.connect(_on_dash_started)
	sprite.animation_finished.connect(_on_animation_finished)

# Called instantly when dash begins — plays the full Dash animation
func _on_dash_started() -> void:
	sprite.play("Dash")

# Called when any non-looping animation finishes
func _on_animation_finished() -> void:
	if sprite.animation == &"Dash":
		sprite.play("Idle")

func _physics_process(delta: float) -> void:
	# --- coyote time ---
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta

	# --- jump buffer ---
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta

	# --- gravity ---
	var current_gravity := get_gravity() * BASE_GRAVITY_MULTIPLIER
	var current_speed := SPEED

	if not is_on_floor():
		if not recoil.is_active() and not dash.is_active():
			if Input.is_action_just_released("jump") and velocity.y < 0:
				velocity.y *= VARIABLE_JUMP_MULTIPLIER

			if abs(velocity.y) < APEX_THRESHOLD:
				current_gravity *= APEX_GRAVITY_MULTIPLIER
				current_speed += APEX_SPEED_BOOST
			elif velocity.y > 0:
				current_gravity *= FALL_GRAVITY_MULTIPLIER

			if recoil.is_recovering():
				current_gravity *= recoil.get_recovery_factor()

			velocity += current_gravity * delta

		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

		if velocity.y < 0 and is_on_ceiling():
			_handle_corner_correction()

	# --- shoot (right click recoil) ---
	if Input.is_action_just_pressed("shoot"):
		if not dash.is_active() and mana.can_spend(mana.shoot_cost):
			mana.spend(mana.shoot_cost)
			var mouse_pos := get_global_mouse_position()
			var recoil_dir := (global_position - mouse_pos).normalized()
			if recoil_dir == Vector2.ZERO:
				recoil_dir = Vector2.UP
			velocity = recoil.trigger(recoil_dir)

	# --- dash ---
	if Input.is_action_just_pressed("dash"):
		if dash.can_dash() and not recoil.is_active() and mana.can_spend(mana.dash_cost):
			mana.spend(mana.dash_cost)
			var dir := Input.get_axis("move_left", "move_right")
			if dir == 0.0:
				dir = -1.0 if sprite.flip_h else 1.0
			velocity = dash.trigger(dir)

	# --- jump ---
	if _jump_buffer_timer > 0 and _coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0

	# --- horizontal movement ---
	var direction := Input.get_axis("move_left", "move_right")
	var on_ground := is_on_floor()

	if not recoil.is_active() and not dash.is_active():
		if direction != 0:
			var accel := ACCELERATION if on_ground else AIR_ACCELERATION
			velocity.x = move_toward(velocity.x, direction * current_speed, accel * delta)
		else:
			var decel := DECELERATION if on_ground else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)

	# --- animations ---
	_update_animation(direction)

	move_and_slide()

func _update_animation(direction: float) -> void:
	# Don't interrupt Dash animation — let it complete naturally (_on_animation_finished handles the transition)
	if sprite.animation == &"Dash" and sprite.is_playing():
		return

	# Dash active but animation already finished (safety guard)
	if dash.is_active():
		return

	# Recoil — freeze animation
	if recoil.is_active():
		return

	# Air animations
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("Jump")
		else:
			sprite.play("Fall")
		return

	# Ground animations
	if direction != 0:
		sprite.play("Walk")
		sprite.flip_h = direction < 0
	else:
		sprite.play("Idle")

func _handle_corner_correction() -> void:
	if not $RayCastLeft or not $RayCastRight:
		return
	var left_hitting: bool = $RayCastLeft.is_colliding()
	var right_hitting: bool = $RayCastRight.is_colliding()

	if left_hitting and right_hitting:
		return
	if not left_hitting and not right_hitting:
		return

	if left_hitting and not right_hitting:
		global_position.x += CORNER_CORRECTION_AMOUNT
	elif right_hitting and not left_hitting:
		global_position.x -= CORNER_CORRECTION_AMOUNT
