extends CharacterBody2D

@export_group("Movement")
@export var SPEED: float = 600.0
@export var JUMP_VELOCITY: float = -1000.0

@export_group("Advanced Jump Mechanics")
@export var BASE_GRAVITY_MULTIPLIER: float = 1.5
@export var VARIABLE_JUMP_MULTIPLIER: float = 0.4
@export var JUMP_BUFFER_TIME: float = 0.1
@export var COYOTE_TIME: float = 0.1
@export var MAX_FALL_SPEED: float = 2000.0
@export var FALL_GRAVITY_MULTIPLIER: float = 5

@export_group("Apex Modifiers")
@export var APEX_THRESHOLD: float = 15.0
@export var APEX_GRAVITY_MULTIPLIER: float = 0.6
@export var APEX_SPEED_BOOST: float = 50.0

@export_group("Corner Correction")
@export var CORNER_CORRECTION_AMOUNT: float = 4.0

@export_group("Shotgun Recoil")
@export var RECOIL_SPEED: float = 1500.0
@export var RECOIL_DURATION: float = 0.2

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var recoil_timer: float = 0.0

@onready var left_raycast: RayCast2D = $RayCastLeft
@onready var right_raycast: RayCast2D = $RayCastRight

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer -= delta
		
	if recoil_timer > 0:
		recoil_timer -= delta
	
	var current_gravity := get_gravity() * BASE_GRAVITY_MULTIPLIER
	var current_speed := SPEED
	
	if not is_on_floor():
		if recoil_timer <= 0:
			# Only apply gravity and jump mechanics when NOT in recoil
			if Input.is_action_just_released("jump") and velocity.y < 0:
				velocity.y *= VARIABLE_JUMP_MULTIPLIER
				
			if abs(velocity.y) < APEX_THRESHOLD:
				current_gravity *= APEX_GRAVITY_MULTIPLIER
				current_speed += APEX_SPEED_BOOST
			elif velocity.y > 0:
				current_gravity *= FALL_GRAVITY_MULTIPLIER
				
			velocity += current_gravity * delta
		# During recoil: no gravity applied, let the full impulse carry the player

		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

		if velocity.y < 0 and is_on_ceiling():
			_handle_corner_correction()
	
	# Apply recoil AFTER gravity so the impulse isn't partially consumed on the trigger frame
	if Input.is_action_just_pressed("shoot"):
		var mouse_pos = get_global_mouse_position()
		var recoil_dir = (global_position - mouse_pos).normalized()
		if recoil_dir == Vector2.ZERO:
			recoil_dir = Vector2.UP
			
		velocity = recoil_dir * RECOIL_SPEED
		recoil_timer = RECOIL_DURATION

	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	var direction := Input.get_axis("move_left", "move_right")
	
	if recoil_timer <= 0:
		if direction:
			var target_speed := direction * current_speed
			# If faster than normal speed, gently decelerate to standard speed
			if abs(velocity.x) > current_speed and sign(velocity.x) == sign(direction):
				velocity.x = move_toward(velocity.x, target_speed, current_speed * 1.5 * delta)
			else:
				# Normal snappy acceleration
				velocity.x = move_toward(velocity.x, target_speed, current_speed * 10.0 * delta)
		else:
			if abs(velocity.x) > current_speed:
				# Smooth deceleration if sliding from recoil
				velocity.x = move_toward(velocity.x, 0, current_speed * 1.5 * delta)
			else:
				# Snappy stop if walking normally
				velocity.x = move_toward(velocity.x, 0, current_speed * 10.0 * delta)

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
