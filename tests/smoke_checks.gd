extends SceneTree

const PLAYER_PROJECTILE_SCENE := "res://scenes/player_projectile_sc.tscn"
const ENEMY_PROJECTILE_SCENE := "res://scenes/enemy_projectile_sc.tscn"
const ENEMY_SCENE := "res://scenes/enemy_sc.tscn"
const LEVEL_SCENE := "res://scenes/level_training_ground.tscn"

var _failures: Array[String] = []

func _init() -> void:
	_check_projectile_scene(
		PLAYER_PROJECTILE_SCENE,
		"player_projectile",
		PackedStringArray(["enemy"]),
		PackedStringArray(["player"]),
		0.0
	)
	_check_projectile_scene(
		ENEMY_PROJECTILE_SCENE,
		"enemy_projectile",
		PackedStringArray(["player"]),
		PackedStringArray(["enemy"]),
		PI
	)
	_check_enemy_scene()
	_check_level_scene()
	_finish()

func _check_projectile_scene(
	scene_path: String,
	expected_group: String,
	expected_targets: PackedStringArray,
	expected_ignored: PackedStringArray,
	expected_rotation_offset: float
) -> void:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		_failures.append("Missing projectile scene: %s" % scene_path)
		return

	var instance := packed_scene.instantiate()
	var script_path: String = instance.get_script().resource_path if instance.get_script() != null else ""
	if script_path != "res://scripts/projectile_base.gd":
		_failures.append("%s is using an unexpected script: %s" % [scene_path, script_path])
		return

	if instance.projectile_group_name != expected_group:
		_failures.append("%s has wrong projectile group" % scene_path)
	if instance.target_groups != expected_targets:
		_failures.append("%s has wrong target groups" % scene_path)
	if instance.ignored_groups != expected_ignored:
		_failures.append("%s has wrong ignored groups" % scene_path)
	if not is_equal_approx(instance.rotation_offset, expected_rotation_offset):
		_failures.append("%s has wrong rotation offset" % scene_path)

	instance.free()

func _check_enemy_scene() -> void:
	var packed_scene := load(ENEMY_SCENE) as PackedScene
	if packed_scene == null:
		_failures.append("Missing enemy scene")
		return

	var instance := packed_scene.instantiate()
	var script_path: String = instance.get_script().resource_path if instance.get_script() != null else ""
	if script_path != "res://scripts/enemy_base.gd":
		_failures.append("Enemy scene is using an unexpected script: %s" % script_path)
	if instance.projectile_scene == null:
		_failures.append("Enemy scene is missing its projectile scene")

	instance.free()

func _check_level_scene() -> void:
	var packed_scene := load(LEVEL_SCENE) as PackedScene
	if packed_scene == null:
		_failures.append("Missing new level scene")
		return

	var level := packed_scene.instantiate()
	var tile_map := level.get_node_or_null("TileMapLayer") as TileMapLayer
	var player := level.get_node_or_null("Player")
	var hud := level.get_node_or_null("HUD")
	if tile_map == null:
		_failures.append("New level is missing TileMapLayer")
	if player == null:
		_failures.append("New level is missing Player")
	if hud == null:
		_failures.append("New level is missing HUD")

	var enemy_count := 0
	for child in level.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://scripts/enemy_base.gd":
			enemy_count += 1

	if enemy_count < 3:
		_failures.append("New level should contain at least 3 enemies, found %d" % enemy_count)

	level.free()

func _finish() -> void:
	if _failures.is_empty():
		print("Smoke checks passed.")
		quit(0)
		return

	push_error("Smoke checks failed:\n- %s" % "\n- ".join(_failures))
	quit(1)
