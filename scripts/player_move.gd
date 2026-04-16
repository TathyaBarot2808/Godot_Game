extends CharacterBody2D

@export_group("Movement")
@export var SPEED: float = 400.0
@export var JUMP_VELOCITY: float = -1000.0
@export var ACCELERATION: float = 3000.0
@export var DECELERATION: float = 2500.0
@export var AIR_ACCELERATION: float = 1800.0
@export var AIR_DECELERATION: float = 800.0

@export_group("Wall Slide")
@export var WALL_SLIDE_MAX_FALL_SPEED: float = 260.0
@export var WALL_SLIDE_GRAVITY_MULTIPLIER: float = 0.35

@export_group("Advanced Jump Mechanics")
@export var BASE_GRAVITY_MULTIPLIER: float = 1.5
@export var VARIABLE_JUMP_MULTIPLIER: float = 0.1
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
@export var ENABLE_CORNER_CORRECTION: bool = false

@export_group("Animation")
@export var WALK_ANIMATION_BASE_SPEED: float = 240.0
@export var WALK_ANIMATION_MIN_SCALE: float = 0.85
@export var WALK_ANIMATION_MAX_SCALE: float = 2.2

@export_group("Hit Feedback")
@export var player_hit_flash_color: Color = Color(1.0, 0.45, 0.45, 1.0)
@export var player_hit_flash_duration: float = 0.08
@export var player_hit_shake_strength: float = 6.0
@export var player_hit_shake_duration: float = 0.14

var jump_buffer_timer: float = 0.0
var coyote_timer: float = 0.0
var is_dashing: bool = false
var is_wall_sliding: bool = false
var _hit_flash_tween: Tween = null

@onready var abilities: AbilitiesManager = $AbilitiesManager
@onready var loadout: LoadoutManager = $AbilitiesManager/LoadoutManager

@onready var left_raycast: RayCast2D = $RayCastLeft
@onready var right_raycast: RayCast2D = $RayCastRight
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mana: Node2D = $Mana
@onready var health: HealthComponent = $Health
@onready var camera_follow: Camera2D = $Camera2D
@onready var hit_particles: CPUParticles2D = $HitParticles
@onready var fire_point: Node2D = $FirePoint
@onready var shoot_controller: Node = $ShootController
@onready var _dash_comp: Node = $AbilitiesManager/dash
@onready var _recoil: Node = $AbilitiesManager/recoil

var chest_y_offsets: Dictionary = {
	"Idle": [0, 1, 4, 5, 4, 1, 0],
	"Walk": [0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
	"Jump": [-3, -2, -1, 1, 2, 3],
	"Fall": [-5, -6],
	"Dash": [0, 0, 0, 0, 0]
}

var is_shooting_action_active: bool:
	get:
		return shoot_controller != null and shoot_controller.is_shooting()

func _ready() -> void:
	add_to_group("player")
	if _dash_comp:
		_dash_comp.dash_started.connect(_on_dash_started)
		_dash_comp.dash_ended.connect(_on_dash_ended)
	if health != null:
		health.damaged.connect(_on_player_damaged)

func _physics_process(delta: float) -> void:
	_tick_coyote(delta)
	_tick_jump_buffer(delta)
	_apply_gravity(delta)

	_handle_innate_shoot()
	_handle_slot_switch()
	_handle_loadout_ability()

	_handle_jump()
	_handle_movement(delta)
	_update_animation_and_sync()

	move_and_slide()

func _handle_innate_shoot() -> void:
	if not Input.is_action_just_pressed("shoot"):
		return
	if not abilities.can_use("shoot"):
		return
	if not mana.can_spend(mana.shoot_cost):
		return

	var direction := (get_global_mouse_position() - fire_point.global_position).normalized()
	var started: Variant = abilities.execute("shoot", {"direction": direction})
	if started == true:
		mana.spend(mana.shoot_cost)

func _handle_slot_switch() -> void:
	if Input.is_action_just_pressed("slot_1"):
		loadout.set_active_slot(0)
	elif Input.is_action_just_pressed("slot_2"):
		loadout.set_active_slot(1)
	elif Input.is_action_just_pressed("slot_3"):
		loadout.set_active_slot(2)

func _handle_loadout_ability() -> void:
	var ability := loadout.get_active_ability()
	match ability:
		"recoil":
			if Input.is_action_just_pressed("recoil"):
				_execute_recoil()
		"dash":
			if Input.is_action_just_pressed("dash"):
				_execute_dash()
		"walljump":
			if Input.is_action_just_pressed("jump"):
				_execute_walljump()

func _execute_recoil() -> void:
	if abilities.is_active("dash"):
		return
	if not mana.can_spend(mana.recoil_cost):
		return

	var mouse_pos := get_global_mouse_position()
	var dir := (global_position - mouse_pos).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP

	var result: Variant = abilities.execute("recoil", {"direction": dir})
	if result != null:
		mana.spend(mana.recoil_cost)
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

func _execute_walljump() -> void:
	if not abilities.can_use("walljump"):
		return
	if not mana.can_spend(mana.walljump_cost):
		return

	var result: Variant = abilities.execute("walljump")
	if result is Vector2:
		velocity = result
		jump_buffer_timer = 0.0
		coyote_timer = 0.0
		mana.spend(mana.walljump_cost)

func _on_dash_started() -> void:
	is_dashing = true
	animated_sprite.play("Dash")

func _on_dash_ended() -> void:
	pass

func _on_player_damaged(amount: float, current: float, max_value: float) -> void:
	if hit_particles != null:
		hit_particles.restart()
		hit_particles.emitting = true
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	animated_sprite.modulate = player_hit_flash_color
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, player_hit_flash_duration)
	if camera_follow != null and camera_follow.has_method("shake"):
		camera_follow.shake(player_hit_shake_strength, player_hit_shake_duration)

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
		is_wall_sliding = false
		return

	is_wall_sliding = _should_wall_slide()

	var current_gravity := get_gravity() * BASE_GRAVITY_MULTIPLIER
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= VARIABLE_JUMP_MULTIPLIER

	if abs(velocity.y) < APEX_THRESHOLD:
		current_gravity *= APEX_GRAVITY_MULTIPLIER
	elif velocity.y > 0:
		current_gravity *= FALL_GRAVITY_MULTIPLIER

	if is_wall_sliding:
		current_gravity *= WALL_SLIDE_GRAVITY_MULTIPLIER

	if _recoil.is_recovering():
		current_gravity *= _recoil.get_recovery_factor()

	velocity += current_gravity * delta
	var max_fall_speed := WALL_SLIDE_MAX_FALL_SPEED if is_wall_sliding else MAX_FALL_SPEED
	velocity.y = minf(velocity.y, max_fall_speed)

	if ENABLE_CORNER_CORRECTION and velocity.y < 0 and (left_raycast.is_colliding() or right_raycast.is_colliding()):
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

	if shoot_controller != null:
		shoot_controller.sync_facing(animated_sprite.flip_h)

func _should_wall_slide() -> bool:
	if is_on_floor():
		return false
	if not is_on_wall():
		return false
	if velocity.y <= 0.0:
		return false
	return _is_pressing_towards_wall()

func _is_pressing_towards_wall() -> bool:
	var input_x := Input.get_axis("move_left", "move_right")
	if abs(input_x) < 0.1:
		return false

	var wall_normal := get_wall_normal()
	if wall_normal.x > 0.1:

		return input_x < 0.0
	if wall_normal.x < -0.1:

		return input_x > 0.0
	return false

func _handle_corner_correction() -> void:
	if is_on_wall():
		return

	var left_hit := left_raycast.is_colliding()
	var right_hit := right_raycast.is_colliding()
	if left_hit == right_hit:
		return

	var nudge := CORNER_CORRECTION_AMOUNT if left_hit else -CORNER_CORRECTION_AMOUNT
	if not test_move(global_transform, Vector2(nudge, 0.0)):
		global_position.x += nudge

func _update_animation_and_sync() -> void:
	if animated_sprite.animation == "Dash":
		if animated_sprite.is_playing():
			return
		is_dashing = false

	if not is_on_floor():
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("Jump" if velocity.y < 0 else "Fall")
	elif abs(velocity.x) > 0.1:
		animated_sprite.play("Walk")
		var walk_speed := absf(velocity.x)
		var walk_scale := walk_speed / maxf(WALK_ANIMATION_BASE_SPEED, 1.0)
		animated_sprite.speed_scale = clampf(walk_scale, WALK_ANIMATION_MIN_SCALE, WALK_ANIMATION_MAX_SCALE)
	else:
		animated_sprite.speed_scale = 1.0
		animated_sprite.play("Idle")

	var anim := animated_sprite.animation
	var frame := animated_sprite.frame
	var y_off := 0.0
	if chest_y_offsets.has(anim) and frame < chest_y_offsets[anim].size():
		y_off = float(chest_y_offsets[anim][frame])

	if shoot_controller != null:
		shoot_controller.sync_height_offset(y_off)

func start_shooting(direction: Vector2) -> bool:
	if shoot_controller == null:
		return false
	return shoot_controller.request_shot(direction, animated_sprite.flip_h)
