extends Area2D
class_name ProjectileBase

@export_group("Projectile")
@export var speed: float = 800.0
@export var damage: float = 10.0
@export var target_groups: PackedStringArray = PackedStringArray()
@export var ignored_groups: PackedStringArray = PackedStringArray()
@export var projectile_group_name: String = ""
@export var rotate_to_direction: bool = true
@export var rotation_offset: float = 0.0
@export var despawn_on_hit: bool = true
@export var despawn_offscreen: bool = true

var _direction: Vector2 = Vector2.RIGHT
var direction: Vector2:
	get:
		return _direction
	set(value):
		_direction = value.normalized() if value != Vector2.ZERO else Vector2.RIGHT
		_update_rotation()

func _ready() -> void:
	if not projectile_group_name.is_empty():
		add_to_group(projectile_group_name)
	_update_rotation()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if _matches_any_group(body, ignored_groups):
		return

	if _is_target(body):
		_apply_damage(body)

	if despawn_on_hit:
		queue_free()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if despawn_offscreen:
		queue_free()

func _is_target(body: Node) -> bool:
	return target_groups.is_empty() or _matches_any_group(body, target_groups)

func _matches_any_group(node: Node, groups: PackedStringArray) -> bool:
	for group_name in groups:
		if node.is_in_group(group_name):
			return true
	return false

func _apply_damage(body: Node) -> void:
	var health := _find_health_component(body)
	if health != null:
		health.take_damage(damage)
	elif body.has_method("take_damage"):
		body.take_damage(damage)

func _find_health_component(start_node: Node) -> HealthComponent:
	var current: Node = start_node
	while current != null:
		if current is HealthComponent:
			return current as HealthComponent
		for child in current.get_children():
			if child is HealthComponent:
				return child as HealthComponent
		current = current.get_parent()
	return null

func _update_rotation() -> void:
	if rotate_to_direction:
		rotation = direction.angle() + rotation_offset
