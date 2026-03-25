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
@export var FALL_GRAVITY_MULTIPLIER: float = 5

@export_group("Dash")
@export var DASH_SPEED: float = 1800.0
@export var DASH_DURATION: float = 0.12
@export var DASH_COOLDOWN: float = 0.5

@export_group("Apex Modifiers")
@export var APEX_THRESHOLD: float = 15.0
@export var APEX_GRAVITY_MULTIPLIER: float = 0.6
@export var APEX_SPEED_BOOST: float = 50.0

@export_group("Corner Correction")
@export var CORNER_CORRECTION_AMOUNT: float = 4.0

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: float = 0.0
var is_dashing: bool = false

@onready var left_raycast: RayCast2D = $RayCastLeft
@onready var right_raycast: RayCast2D = $RayCastRight
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		var dir := Input.get_axis("move_left", "move_right")
		if dir == 0:
			dir = -1.0 if animated_sprite.flip_h else 1.0
		dash_direction = sign(dir)
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		is_dashing = true
		velocity.y = 0.0
		velocity.x = dash_direction * DASH_SPEED
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	var current_gravity := get_gravity() * BASE_GRAVITY_MULTIPLIER
	var current_speed := SPEED
	
	if not is_on_floor() and not is_dashing:
		if Input.is_action_just_released("jump") and velocity.y < 0:
			velocity.y *= VARIABLE_JUMP_MULTIPLIER
			
		if abs(velocity.y) < APEX_THRESHOLD:
			current_gravity *= APEX_GRAVITY_MULTIPLIER
			current_speed += APEX_SPEED_BOOST
		elif velocity.y > 0:
			current_gravity *= FALL_GRAVITY_MULTIPLIER
			
		velocity += current_gravity * delta

		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

		if velocity.y < 0 and is_on_ceiling():
			_handle_corner_correction()

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	var direction := Input.get_axis("move_left", "move_right")
	var on_ground := is_on_floor()
	
	# Animation & sprite flip
	if direction != 0:
		animated_sprite.flip_h = direction < 0
	
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
		if animated_sprite.animation != "Idle":
			animated_sprite.play("Idle")
	
	if not is_dashing:
		if direction:
			var target_speed := direction * current_speed
			var accel := ACCELERATION if on_ground else AIR_ACCELERATION
			velocity.x = move_toward(velocity.x, target_speed, accel * delta)
		else:
			var decel := DECELERATION if on_ground else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0, decel * delta)

	move_and_slide()

func _handle_corner_correction() -> void:
	if not left_raycast or not right_raycast:
		return
		
	var left_hitting: bool = left_raycast.is_colliding()
	var right_hitting: bool = right_raycast.is_colliding()

	if left_hitting and right_hitting:
		return
	if not left_hitting and not right_hitting:
		return

	if left_hitting and not right_hitting:
		global_position.x += CORNER_CORRECTION_AMOUNT
	elif right_hitting and not left_hitting:
		global_position.x -= CORNER_CORRECTION_AMOUNT
