extends CharacterBody2D

## How fast the enemy moves toward the player (pixels/second)
@export var speed: float = 100.0
## Enemy stops chasing beyond this distance
@export var detection_range: float = 100000.0
## Enemy stops moving when this close to the player
@export var stop_distance: float = 8.0

## Damage dealt to player on contact
@export var damage: float = 10.0

const GRAVITY: float = 980.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var ray_cast_2d7: RayCast2D = $RayCast2D7
@onready var ray_cast_2d5: RayCast2D = $RayCast2D5
@onready var ray_cast_2d2: RayCast2D = $RayCast2D2
@onready var ray_cast_2d8: RayCast2D = $RayCast2D8
@onready var ray_cast_2d6: RayCast2D = $RayCast2D6
@onready var ray_cast_2d4: RayCast2D = $RayCast2D4
@onready var ray_cast_2d3: RayCast2D = $RayCast2D3

var raycasts = [ray_cast_2d,ray_cast_2d2,ray_cast_2d3,ray_cast_2d4,ray_cast_2d5,ray_cast_2d6,ray_cast_2d7,ray_cast_2d8]


var player: Node2D = null
var _dying: bool = false

func _ready() -> void:
	add_to_group("enemy1")
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0] as Node2D

func _physics_process(delta: float) -> void:
	if player == null or _dying:
		return

	# Apply gravity
	#if not is_on_floor():
		#velocity.y += GRAVITY * delta

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	if distance > stop_distance and distance < detection_range:
		var direction: Vector2 = to_player.normalized()
		velocity.x = direction.x * speed
		animated_sprite.flip_h = direction.x > 0
		
	else:
		velocity.x = 0.0

	move_and_slide()
	_check_player_collision()




func die() -> void:
	if _dying:
		return
	_dying = true
	velocity = Vector2.ZERO
	animated_sprite.play("Die")
	animated_sprite.animation_finished.connect(queue_free)


func _check_player_collision() -> void:
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
