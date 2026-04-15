extends CharacterBody2D

## How fast the enemy moves toward the player (pixels/second)
@export var speed: float = 100.0
## Enemy stops chasing beyond this distance
@export var detection_range: float = 100000.0
@export var shooting_range: float = 100000.0
## Enemy stops moving when this close to the player
@export var stop_distance: float = 8.0
@onready var shoot_point: Node2D = get_node_or_null("ShootPoint") as Node2D

## Damage dealt to player on contact
@export var damage: float = 10.0

const GRAVITY: float = 980.0
const PROJECTILE_SCENE := preload("res://scenes/enemy_projectile_sc.tscn")

@export var shoot_cooldown: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var player: Node2D = null
var _dying: bool = false
var _shoot_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy1")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D




func _shoot() -> void:
	if player == null or shoot_point == null:
		return
	var projectile = PROJECTILE_SCENE.instantiate()
	# Place it in the scene tree at the same level as the enemy
	get_parent().add_child(projectile)
	projectile.global_position = shoot_point.global_position
	projectile.direction = (player.global_position - shoot_point.global_position).normalized()
	projectile.rotation = projectile.direction.angle() + PI
	_shoot_timer = 0.0



func _find_player() -> void:
	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	# Face the player regardless of behavior
	animated_sprite.flip_h = to_player.x > 0

	# Rotate ShootPoint to always aim at the player
	if shoot_point != null:
		shoot_point.look_at(player.global_position)
#
	#if distance < shooting_range:
		## In shooting range — stop and shoot
		#velocity.x = 0.0
	if distance > stop_distance and distance < detection_range:
		# Chase the player
		var direction: Vector2 = to_player.normalized()
		velocity.x = direction.x * speed
	else:
		velocity.x = 0.0



func _physics_process(delta: float) -> void:
	if player == null or _dying:
		return

	# Apply gravity
	#if not is_on_floor():
		#velocity.y += GRAVITY * delta

	_find_player()
	move_and_slide()
	_check_bullet_collision()

	# Shoot cooldown & fire when in range
	_shoot_timer += delta
	var dist: float = (player.global_position - global_position).length()
	if dist < shooting_range and _shoot_timer >= shoot_cooldown:
		_shoot()




func die() -> void:
	if _dying:
		return
	_dying = true
	velocity = Vector2.ZERO
	animated_sprite.play("Die")
	animated_sprite.animation_finished.connect(queue_free)


func _check_bullet_collision() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider == null or not (collider is PhysicsBody2D):
			continue
		if collider.is_in_group("bullet"):
			var health :Node = collider.get_node_or_null("Health")
			if health != null:
				health.damage(damage)
			die()
			return
