extends Node
class_name LevelRenderer

const INDEX_SYMBOL = {
	-1: "-",
	0: "X",
	1: "S",
	2: "-",
	3: "?",
	4: "Q",
	5: "E",
	6: "<",
	7: ">",
	8: "[",
	9: "]",
}
#const SYMBOL_INDEX = reverse_dict(INDEX_SYMBOL)

const INDEX_COORDINATES = {
	-1: Vector2i(2, 1),
	0: Vector2i(1, 0),
	1: Vector2i(0, 0),
	2: Vector2i(2, 1),
	3: Vector2i(4, 0),
	4: Vector2i(2, 0),
	5: Vector2i(0, 0),
	6: Vector2i(6, 0),
	7: Vector2i(7, 0),
	8: Vector2i(6, 1),
	9: Vector2i(7, 1),
}

const INDEX_SHEET = {
	-1: 0,
	0: 0,
	1: 0,
	2: 0,
	3: 0,
	4: 0,
	5: 2,
	6: 0,
	7: 0,
	8: 0,
	9: 0,
}

const TILE_SYMBOL = {
	[0, Vector2i(1, 0)]: "X",
	[0, Vector2i(0, 0)]: "S",
	[0, Vector2i(4, 0)]: "?",
	[0, Vector2i(2, 0)]: "Q",
	[2, Vector2i(0, 0)]: "E",
	[0, Vector2i(6, 0)]: "<",
	[0, Vector2i(7, 0)]: ">",
	[0, Vector2i(6, 1)]: "[",
	[0, Vector2i(7, 1)]: "]",
}

const SYMBOL_OBJECT = {
	"E": preload("res://Scenes/Characters/Enemy.tscn"),
}

#const SYMBOL_COORDS = reverse_dict(INDEX_COORDINATES)

static func reverse_dict(dict: Dictionary) -> Dictionary:
	var reversed = {}
	for key in dict.keys():
		reversed[dict[key]] = key
	return reversed

#static func symbol_to_index(symbol: String) -> int:
	#return SYMBOL_INDEX.get(symbol, -1)

static func index_to_coordinates(index: int) -> Vector2i:
	return INDEX_COORDINATES.get(index, Vector2i(2, 1))

static func index_to_sheet(index: int) -> int:
	return INDEX_SHEET.get(index, 0)

static func symbol_to_object(symbol: String) -> PackedScene:
	return SYMBOL_OBJECT.get(symbol, null)

static func render_text_map(parent_node: Node2D, layer: TileMapLayer, map_text: String) -> int:
	print("[LEVEL_RENDERER] Starting render_text_map")
	layer.clear()
	if parent_node.has_method("clear_enemies"):
		parent_node.clear_enemies()

	var offset = Vector2i(8 * 2, 8) * 2
	var layer_data := []
	for line in map_text.split("\n"):
		var trimmed = line.strip_edges()
		if trimmed == "":
			continue
		var row := []
		for char in trimmed:
			if char == " ":
				continue
			#row.append(symbol_to_index(char))
		layer_data.append(row)

	var rightmost_bound := 0
	for row in layer_data:
		rightmost_bound = max(rightmost_bound, row.size())

	var tile_size_x = 0
	if layer.tile_set:
		tile_size_x = layer.tile_set.tile_size.x

	var new_rightmost = (rightmost_bound - offset.x) * tile_size_x

	for y in range(layer_data.size()):
		for x in range(layer_data[y].size()):
			var tile_id = layer_data[y][x]
			var coordinate = index_to_coordinates(tile_id)
			var sheet_id = index_to_sheet(tile_id)
			var symbol = INDEX_SYMBOL.get(tile_id, "-")
			var object_scene = symbol_to_object(symbol)
			if object_scene:
				var object = object_scene.instantiate()
				parent_node.add_child(object)
				object.position = (Vector2i(x, y) - offset) * layer.tile_set.tile_size
			else:
				layer.set_cell(Vector2i(x, y) - offset, sheet_id, coordinate)

	layer.notify_runtime_tile_data_update()
	print("[LEVEL_RENDERER] Render complete. rightmost_world=", new_rightmost)
	
	# Spawn Point Calculation
	var found_spawn = false
	var spawn_pos = Vector2.ZERO
	for x in range(min(4, rightmost_bound)):
		for y in range(layer_data.size()):
			if x < layer_data[y].size():
				var tile_id = layer_data[y][x]
				var symbol = INDEX_SYMBOL.get(tile_id, "-")
				if symbol in ["X", "S", "?", "Q", "<", ">", "[", "]"]:
					spawn_pos = (Vector2(x, y - 2) - Vector2(offset)) * Vector2(layer.tile_set.tile_size)
					found_spawn = true
					break
		if found_spawn:
			break
	
	if found_spawn:
		var players = parent_node.get_tree().get_nodes_in_group("Player")
		for pl in players:
			pl.spawnLocation = spawn_pos
			pl.position = spawn_pos
	
	# End Flag Creation
	for old in parent_node.get_tree().get_nodes_in_group("EndFlagGroup"):
		old.queue_free()
		
	var flag_area = Area2D.new()
	flag_area.add_to_group("EndFlagGroup")
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 2000) # Tall trigger area
	col.shape = shape
	flag_area.add_child(col)
	
	var vis = ColorRect.new()
	vis.size = Vector2(8, 200)
	vis.color = Color.GOLD
	vis.position = Vector2(-4, -100)
	
	var pennant = ColorRect.new()
	pennant.size = Vector2(60, 40)
	pennant.color = Color.RED
	pennant.position = Vector2(4, -100)
	vis.add_child(pennant)
	
	flag_area.add_child(vis)
	
	# Place the flag a bit before the structural edge to be safe
	flag_area.position = Vector2(new_rightmost - tile_size_x * 2, 0)
	flag_area.collision_mask = 1 # Player collision layer
	
	flag_area.body_entered.connect(func(body):
		if body.is_in_group("Player") and body.has_method("win_level"):
			body.win_level()
	)
	
	parent_node.add_child(flag_area)
	
	return new_rightmost
