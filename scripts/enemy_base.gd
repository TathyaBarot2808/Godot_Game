extends CharacterBody2D
class_name EnemyBase

@export_group("Movement")
@export var move_speed: float = 100.0
@export var detection_range: float = 100000.0
@export var shooting_range: float = 100000.0
@export var stop_distance: float = 8.0
@export var shoot_cooldown: float = 1.5

@export_group("Combat")
@export var projectile_scene: PackedScene
@export var player_group: String = "player"
@export var enemy_group: String = "enemy"

@export_group("Node References")
@export var shoot_point_path: NodePath = ^"ShootPoint"
@export var animated_sprite_path: NodePath = ^"AnimatedSprite2D"
@export var health_path: NodePath = ^"HealthComponent"
@export var hit_particles_path: NodePath = ^"HitParticles"

@export_group("Hit Feedback")
@export var hit_shake_strength: float = 4.0
@export var hit_shake_duration: float = 0.12
@export var hit_flash_color: Color = Color(1.0, 0.35, 0.35, 1.0)
@export var hit_flash_duration: float = 0.08

@onready var shoot_point: Node2D = get_node_or_null(shoot_point_path) as Node2D
@onready var animated_sprite: AnimatedSprite2D = get_node_or_null(animated_sprite_path) as AnimatedSprite2D
@onready var health: HealthComponent = get_node_or_null(health_path) as HealthComponent
@onready var hit_particles: CPUParticles2D = get_node_or_null(hit_particles_path) as CPUParticles2D

var player: Node2D = null
var _dying: bool = false
var _shoot_timer: float = 0.0
var _hit_flash_tween: Tween = null

func _ready() -> void:
	add_to_group(enemy_group)
	_assign_player()
	_setup_health()

func _physics_process(delta: float) -> void:
	if _dying:
		return

	if not is_instance_valid(player):
		_assign_player()
		if player == null:
			return

	_update_facing_and_aim()
	_update_horizontal_movement()
	move_and_slide()

	_shoot_timer += delta
	if _can_shoot_player():
		_fire_projectile()

func _assign_player() -> void:
	var players := get_tree().get_nodes_in_group(player_group)
	player = players[0] as Node2D if not players.is_empty() else null

func _setup_health() -> void:
	if health == null:
		return

	health.auto_destroy_owner = false
	if not health.damaged.is_connected(_on_damaged):
		health.damaged.connect(_on_damaged)
	if not health.died.is_connected(die):
		health.died.connect(die)

func _update_facing_and_aim() -> void:
	if player == null:
		return

	var to_player := player.global_position - global_position
	if animated_sprite != null:
		animated_sprite.flip_h = to_player.x > 0
	if shoot_point != null:
		shoot_point.look_at(player.global_position)

func _update_horizontal_movement() -> void:
	if player == null:
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()
	if distance > stop_distance and distance < detection_range:
		velocity.x = to_player.normalized().x * move_speed
	else:
		velocity.x = 0.0

func _can_shoot_player() -> bool:
	if player == null or shoot_point == null or projectile_scene == null:
		return false
	if _shoot_timer < shoot_cooldown:
		return false
	return global_position.distance_to(player.global_position) <= shooting_range

func _fire_projectile() -> void:
	var projectile := projectile_scene.instantiate()
	if not projectile is Area2D:
		push_error("EnemyBase: projectile_scene must instance an Area2D projectile")
		return

	var launch_direction := (player.global_position - shoot_point.global_position).normalized()
	var parent_node := get_parent() if get_parent() != null else get_tree().current_scene
	parent_node.add_child(projectile)
	projectile.global_position = shoot_point.global_position
	projectile.direction = launch_direction
	_shoot_timer = 0.0

func die() -> void:
	if _dying:
		return

	_dying = true
	remove_from_group(enemy_group)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO

	if animated_sprite == null or not animated_sprite.sprite_frames.has_animation("Die"):
		queue_free()
		return

	animated_sprite.play("Die")
	animated_sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)

func _on_damaged(_amount: float, _current: float, _max_value: float) -> void:
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
