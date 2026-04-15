extends CharacterBody2D

@export var speed: float = 100.0
@export var detection_range: float = 100000.0
@export var shooting_range: float = 100000.0
@export var stop_distance: float = 8.0

@export_group("Hit Feedback")
@export var hit_shake_strength: float = 4.0
@export var hit_shake_duration: float = 0.12
@export var hit_flash_color: Color = Color(1.0, 0.35, 0.35, 1.0)
@export var hit_flash_duration: float = 0.08

@onready var shoot_point: Node2D = get_node_or_null("ShootPoint") as Node2D
@onready var health: HealthComponent = $HealthComponent
@onready var hit_particles: CPUParticles2D = $HitParticles

const GRAVITY: float = 980.0
const PROJECTILE_SCENE := preload("res://scenes/enemy_projectile_sc.tscn")

@export var shoot_cooldown: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var _dying: bool = false
var _shoot_timer: float = 0.0
var _hit_flash_tween: Tween = null

func _ready() -> void:
	add_to_group("enemy")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D
	if health != null:
		health.auto_destroy_owner = false
		if not health.damaged.is_connected(_on_damaged):
			health.damaged.connect(_on_damaged)
		if not health.died.is_connected(die):
			health.died.connect(die)

func _shoot() -> void:
	if player == null or shoot_point == null:
		return
	var projectile = PROJECTILE_SCENE.instantiate()

	get_parent().add_child(projectile)
	projectile.global_position = shoot_point.global_position
	projectile.direction = (player.global_position - shoot_point.global_position).normalized()
	projectile.rotation = projectile.direction.angle() + PI
	_shoot_timer = 0.0

func _find_player() -> void:
	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	animated_sprite.flip_h = to_player.x > 0

	if shoot_point != null:
		shoot_point.look_at(player.global_position)

	if distance > stop_distance and distance < detection_range:
		var direction: Vector2 = to_player.normalized()
		velocity.x = direction.x * speed
	else:
		velocity.x = 0.0

func _physics_process(delta: float) -> void:
	if player == null or _dying:
		return

	_find_player()
	move_and_slide()

	_shoot_timer += delta
	var dist: float = (player.global_position - global_position).length()
	if dist < shooting_range and _shoot_timer >= shoot_cooldown:
		_shoot()

func die() -> void:
	if _dying:
		return
	_dying = true
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	animated_sprite.play("Die")
	animated_sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)

func _on_damaged(amount: float, current: float, max_value: float) -> void:
	if _dying:
		return
	_play_hit_particles()
	_play_hit_flash()
	_shake_player_camera()

func _play_hit_particles() -> void:
	if hit_particles == null:
		return
	hit_particles.restart()
	hit_particles.emitting = true

func _play_hit_flash() -> void:
	if animated_sprite == null:
		return
	if is_instance_valid(_hit_flash_tween):
		_hit_flash_tween.kill()
	animated_sprite.modulate = hit_flash_color
	_hit_flash_tween = create_tween()
	_hit_flash_tween.tween_property(animated_sprite, "modulate", Color.WHITE, hit_flash_duration)

func _shake_player_camera() -> void:
	if player == null:
		return
	var player_camera := player.get_node_or_null("Camera2D") as Camera2D
	if player_camera != null and player_camera.has_method("shake"):
		player_camera.shake(hit_shake_strength, hit_shake_duration)
