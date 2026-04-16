extends SceneTree

const SOURCE_SCENE_PATH := "res://scenes/game_sc.tscn"
const OUTPUT_SCENE_PATH := "res://scenes/level_training_ground.tscn"
const ENEMY_SCENE_PATH := "res://scenes/enemy_sc.tscn"

const TILE_SOURCE_ID := 0
const TOP_TILES := [
	Vector2i(1, 1),
	Vector2i(2, 1),
	Vector2i(3, 1),
	Vector2i(5, 1),
	Vector2i(6, 1),
	Vector2i(8, 1),
	Vector2i(9, 1)
]
const FILL_TILES := [
	Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(3, 2),
	Vector2i(5, 2),
	Vector2i(6, 2),
	Vector2i(8, 2),
	Vector2i(9, 2)
]

func _init() -> void:
	var source_scene := load(SOURCE_SCENE_PATH) as PackedScene
	var enemy_scene := load(ENEMY_SCENE_PATH) as PackedScene
	if source_scene == null or enemy_scene == null:
		push_error("Failed to load source scenes for training level generation.")
		quit(1)
		return

	var level_root := source_scene.instantiate()
	level_root.name = "TrainingGround"

	var tile_map := level_root.get_node("TileMapLayer") as TileMapLayer
	var player := level_root.get_node("Player") as Node2D
	if tile_map == null or player == null:
		push_error("Source scene is missing TileMapLayer or Player.")
		quit(1)
		return

	_clear_existing_enemies(level_root)
	tile_map.clear()

	_build_level_geometry(tile_map)
	_position_player(player, tile_map, 2, 4)

	_add_enemy(level_root, enemy_scene, tile_map, 19, 1)
	_add_enemy(level_root, enemy_scene, tile_map, 27, 3)
	_add_enemy(level_root, enemy_scene, tile_map, 48, 3)
	_add_enemy(level_root, enemy_scene, tile_map, 55, 0)

	var packed_scene := PackedScene.new()
	if packed_scene.pack(level_root) != OK:
		push_error("Failed to pack generated training level.")
		quit(1)
		return

	var save_result := ResourceSaver.save(packed_scene, OUTPUT_SCENE_PATH)
	if save_result != OK:
		push_error("Failed to save generated training level: %s" % save_result)
		quit(1)
		return

	level_root.free()
	print("Generated %s" % OUTPUT_SCENE_PATH)
	quit(0)

func _clear_existing_enemies(level_root: Node) -> void:
	for child in level_root.get_children():
		if child.name in ["Player", "HUD", "TileMapLayer"]:
			continue
		level_root.remove_child(child)
		child.free()

func _build_level_geometry(tile_map: TileMapLayer) -> void:
	# Act 1: safe runway, staircase, and first enemy perch.
	_draw_platform(tile_map, 0, 14, 4, 4)
	_draw_platform(tile_map, 8, 11, 2, 2)
	_draw_platform(tile_map, 15, 21, 1, 3)

	# Act 2: lower recovery basin plus rising ledges.
	_draw_platform(tile_map, 15, 25, 7, 2)
	_draw_platform(tile_map, 18, 22, 5, 2)
	_draw_platform(tile_map, 24, 29, 3, 2)
	_draw_platform(tile_map, 31, 35, 1, 2)
	_draw_platform(tile_map, 36, 43, 3, 3)

	# Act 3: layered combat path that resolves into a calm finish room.
	_draw_platform(tile_map, 44, 50, 6, 2)
	_draw_platform(tile_map, 47, 53, 3, 2)
	_draw_platform(tile_map, 54, 60, 0, 2)
	_draw_platform(tile_map, 60, 74, 3, 4)

	# Vertical anchors that make the ascent readable and help wall-jump recovery.
	_draw_column(tile_map, 15, 4, 7)
	_draw_column(tile_map, 24, 3, 7)
	_draw_column(tile_map, 31, 1, 7)
	_draw_column(tile_map, 44, 3, 6)
	_draw_column(tile_map, 60, 0, 3)
	_draw_column(tile_map, 74, 3, 7)

func _draw_platform(tile_map: TileMapLayer, start_x: int, end_x: int, top_y: int, height: int) -> void:
	for x in range(start_x, end_x + 1):
		for y in range(top_y, top_y + height):
			var options := TOP_TILES if y == top_y else FILL_TILES
			tile_map.set_cell(Vector2i(x, y), TILE_SOURCE_ID, _pick_tile(options, x, y))

func _draw_column(tile_map: TileMapLayer, x: int, start_y: int, end_y: int) -> void:
	for y in range(start_y, end_y + 1):
		var options := TOP_TILES if y == start_y else FILL_TILES
		tile_map.set_cell(Vector2i(x, y), TILE_SOURCE_ID, _pick_tile(options, x, y))

func _pick_tile(options: Array, x: int, y: int) -> Vector2i:
	return options[abs((x * 17) + (y * 31)) % options.size()]

func _position_player(player: Node2D, tile_map: TileMapLayer, cell_x: int, top_y: int) -> void:
	player.global_position = _cell_to_world(tile_map, cell_x, top_y) + Vector2(0, -72)

func _add_enemy(level_root: Node, enemy_scene: PackedScene, tile_map: TileMapLayer, cell_x: int, top_y: int) -> void:
	var enemy := enemy_scene.instantiate() as Node2D
	enemy.name = "Enemy_%d_%d" % [cell_x, top_y]
	level_root.add_child(enemy)
	enemy.owner = level_root
	enemy.global_position = _cell_to_world(tile_map, cell_x, top_y) + Vector2(0, -56)

func _cell_to_world(tile_map: TileMapLayer, cell_x: int, cell_y: int) -> Vector2:
	return tile_map.to_global(tile_map.map_to_local(Vector2i(cell_x, cell_y)))
