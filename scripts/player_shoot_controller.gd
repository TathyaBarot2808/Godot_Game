extends Node
class_name PlayerShootController

@export_group("Projectile")
@export var projectile_scene: PackedScene = preload("res://scenes/player_projectile_sc.tscn")

@export_group("Node References")
@export var fire_point_path: NodePath = ^"../FirePoint"
@export var shoot_effect_path: NodePath = ^"../ShootEffectSprite"

@export_group("Offsets")
@export var fire_point_base_y: float = -5.0
@export var shoot_effect_base_y: float = 3.0

@onready var fire_point: Node2D = get_node_or_null(fire_point_path) as Node2D
@onready var shoot_effect: AnimatedSprite2D = get_node_or_null(shoot_effect_path) as AnimatedSprite2D

var stored_shoot_direction: Vector2 = Vector2.RIGHT
var _is_shooting: bool = false

func _ready() -> void:
	if shoot_effect == null:
		push_error("PlayerShootController: ShootEffectSprite not found")
		return

	if not shoot_effect.frame_changed.is_connected(_on_shoot_effect_frame_changed):
		shoot_effect.frame_changed.connect(_on_shoot_effect_frame_changed)
	if not shoot_effect.animation_finished.is_connected(_on_shoot_effect_animation_finished):
		shoot_effect.animation_finished.connect(_on_shoot_effect_animation_finished)
	shoot_effect.hide()

func request_shot(direction: Vector2, facing_left: bool) -> bool:
	if _is_shooting or shoot_effect == null:
		return false

	if direction == Vector2.ZERO:
		direction = Vector2.LEFT if facing_left else Vector2.RIGHT
	stored_shoot_direction = direction.normalized()

	_is_shooting = true
	shoot_effect.show()
	shoot_effect.play("default")
	shoot_effect.set_frame_and_progress(0, 0.0)
	return true

func sync_facing(facing_left: bool) -> void:
	if fire_point != null:
		fire_point.position.x = -absf(fire_point.position.x) if facing_left else absf(fire_point.position.x)
	if shoot_effect != null:
		shoot_effect.flip_h = facing_left

func sync_height_offset(offset_y: float) -> void:
	if fire_point != null:
		fire_point.position.y = fire_point_base_y + offset_y
	if shoot_effect != null:
		shoot_effect.position.y = shoot_effect_base_y + offset_y

func is_shooting() -> bool:
	return _is_shooting

func _on_shoot_effect_frame_changed() -> void:
	if shoot_effect == null or shoot_effect.animation != "default":
		return

	if shoot_effect.frame == 4:
		_fire_projectile()
		_is_shooting = false
	elif shoot_effect.frame == 7:
		shoot_effect.hide()
		shoot_effect.stop()

func _on_shoot_effect_animation_finished() -> void:
	if shoot_effect == null:
		return
	shoot_effect.hide()
	_is_shooting = false

func _fire_projectile() -> void:
	if fire_point == null or projectile_scene == null:
		return

	var projectile := projectile_scene.instantiate()
	if not projectile is Area2D:
		push_error("PlayerShootController: projectile_scene must instance an Area2D projectile")
		return

	var launch_direction := stored_shoot_direction
	if launch_direction == Vector2.ZERO:
		launch_direction = Vector2.RIGHT

	projectile.global_position = fire_point.global_position
	projectile.direction = launch_direction
	get_tree().current_scene.add_child(projectile)
