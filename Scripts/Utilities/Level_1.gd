class_name Level extends Node2D

@export var Layer : TileMapLayer
@export var GenerateMap : bool = true
@export_file("*.txt") var map_path: String
var levels = get_all_levels_content("res://Resources/Dataset/Processed/")
var Map: String
var enemies := []
signal enemyDeath
var rightmost_world = 10000
var currentDifficulty = 0.1
var INDEX_SYMBOL = {
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
var SYMBOL_INDEX = reverse_dict(INDEX_SYMBOL)

func IndexToSymbol(index):
	return INDEX_SYMBOL[index]

func SymbolToIndex(index):
	return SYMBOL_INDEX[index]

var INDEX_COORDINATES = {
	-1: Vector2i(2,1),
	0: Vector2i(1,0),
	1: Vector2i(0,0),
	2: Vector2i(2,1),
	3: Vector2i(4,0),
	4: Vector2i(2,0),
	5: Vector2i(0,0),
	6: Vector2i(6,0),
	7: Vector2i(7,0),
	8: Vector2i(6,1),
	9: Vector2i(7,1)
}

func IndexToCoordinates(index):
	return INDEX_COORDINATES[index]

var INDEX_SHEET = {
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
	9: 0
}

func IndexToSheet(index):
	return INDEX_SHEET[index]

var TILE_SYMBOL = {
	[0, Vector2i(1, 0)]: "X",   # solid block
	[0, Vector2i(0, 0)]: "S",   # breakable block
	[0, Vector2i(4, 0)]: "?",   # mystery box
	[0, Vector2i(2, 0)]: "Q",   # hit box
	[2, Vector2i(0, 0)]: "E",   # enemy (different IndexToSheet, same coords)
	[0, Vector2i(6, 0)]: "<",   # pipe top left
	[0, Vector2i(7, 0)]: ">",   # pipe top right
	[0, Vector2i(6, 1)]: "[",   # pipe body left
	[0, Vector2i(7, 1)]: "]",   # pipe body right
}
func TileToSymbol(tile):
	return TILE_SYMBOL[tile]

var SYMBOL_OBJECT = {
	"E":preload("res://Scenes/Characters/Enemy.tscn"),
}

func SymbolToObject(Symbol):
	if SYMBOL_OBJECT.has(Symbol):
		return SYMBOL_OBJECT[Symbol]

var SYMBOL_COORDS = reverse_dict(INDEX_COORDINATES)
func ReverseCoords(symbol):
	return SYMBOL_COORDS[symbol]

signal EnemyDeath

func _ready():
	Map = levels[0]
	child_entered_tree.connect(func(child):
		if child is Enemy:
			enemies.append(child)
			child.death.connect(func():
				EnemyDeath.emit(child)
			)
	)
	if Map and GenerateMap:
		TextToMap()
	else:
		var terrain_map = MapToText()
		print(terrain_map)

func getId(tiledata):
	var Id = -1
	if tiledata:
		var terrain = tiledata.terrain
		if terrain:
			Id = int(terrain)
		else:
			Id = 0
	return Id

func restart():
	TextToMap()

func clear_enemies():
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	enemies.clear()

func TextToMap():
	Layer.clear()
	clear_enemies()
	print("loaded map with difficulty: ", currentDifficulty)
	var offset = Vector2i(8*2, 8) * 2
	var layer_data := []
	
	for line in Map.split("\n"):
		line = line.strip_edges()
		if line == "":
			continue
		var row := []
		for letter in line:
			if letter == " ":
				continue
			var index = SymbolToIndex(letter) if SYMBOL_INDEX.has(letter) else -1
			row.append(index)
		layer_data.append(row)
	
	var rightmost_bound := 0
	for row in layer_data:
		rightmost_bound = max(rightmost_bound, row.size())
	rightmost_world = (rightmost_bound - offset.x) * Layer.tile_set.tile_size.x
	for y in range(layer_data.size()):
		for x in range(layer_data[y].size()):
			var tileId = layer_data[y][x]
			var Coordinate = IndexToCoordinates(tileId)
			var SheetId = IndexToSheet(tileId)
			var symbol = IndexToSymbol(tileId)
			var object = SymbolToObject(symbol)
			if object:
				object = object.instantiate()
				add_child(object)
				object.position = (Vector2i(x, y) - offset) * Layer.tile_set.tile_size
			else:
				Layer.set_cell(Vector2i(x, y) - offset, SheetId, Coordinate)

	Layer.notify_runtime_tile_data_update()

func ChangeMap(playerLevel):
	var data = get_closest_level("res://Resources/Dataset/Processed/", playerLevel)
	Map = data["content"]
	currentDifficulty = data["difficulty"]
	TextToMap()

func MapToText() -> String:
	var used_rect = Layer.get_used_rect()
	var text := ""

	for y in range(used_rect.size.y):
		for x in range(used_rect.size.x):
			var cell_pos = Vector2i(x + used_rect.position.x, y + used_rect.position.y)
			var SheetId= Layer.get_cell_IndexToSheet_id(cell_pos)
			if SheetId< 0:
				text += "-"
				continue

			var atlas_coords = Layer.get_cell_atlas_coords(cell_pos)
			if atlas_coords == null:
				text += "-"
				continue

			var key = [SheetId, atlas_coords]
			if TILE_SYMBOL.has(key):
				text += TILE_SYMBOL[key]
			else:
				text += "-"
		text += "\n"

	return text

func reverse_dict(dict: Dictionary) -> Dictionary:
	var reversed = {}
	for key in dict.keys():
		reversed[dict[key]] = key
	return reversed

func _on_gemini_generation(text) -> void:
	Map = text
	TextToMap()
func get_all_levels_content(path: String) -> Array:
	var levels = []
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".txt"):
				var full_path = path + file_name
				
				var file = FileAccess.open(full_path, FileAccess.READ)
				if file:
					var content = file.get_as_text()
					levels.append(content)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return levels
	

func get_closest_level(path: String, player_level: float) -> Dictionary:
	var closest_level = null
	var closest_diff = INF
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".txt"):
				
				# 🔹 extract difficulty from filename
				var difficulty_str = file_name.replace(".txt", "")
				var difficulty = float(difficulty_str)
				
				var diff = abs(difficulty - player_level)
				
				if diff < closest_diff:
					closest_diff = diff
					
					var full_path = path + file_name
					var file = FileAccess.open(full_path, FileAccess.READ)
					
					if file:
						closest_level = {
							"name": file_name,
							"difficulty": difficulty,
							"content": file.get_as_text()
						}
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	return closest_level
