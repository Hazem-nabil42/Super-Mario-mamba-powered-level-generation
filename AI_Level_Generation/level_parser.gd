extends Node
class_name LevelParser

static func clean_grid_string(raw:String) -> String:
	var cleaned = raw.strip_edges()
	cleaned = cleaned.replace("\r", "")
	return cleaned

static func parse_grid_string(raw:String) -> Array:
	var grid := []
	for line in clean_grid_string(raw).split("\n"):
		var row = []
		var trimmed = line.strip_edges()
		if trimmed == "":
			continue
		for char in trimmed:
			row.append(char)
		grid.append(row)
	return grid

static func summarize_grid(grid:Array) -> Dictionary:
	var counts = {}
	var width = 0
	var height = grid.size()
	for row in grid:
		width = max(width, row.size())
		for symbol in row:
			counts[symbol] = counts.get(symbol, 0) + 1
	return {
		"width": width,
		"height": height,
		"counts": counts,
	}

static func log_level_text(raw:String) -> void:
	var grid_string = clean_grid_string(raw)
	print("[AI_LEVEL_PARSER] Generated level text:\n", grid_string)
	var grid = parse_grid_string(grid_string)
	var summary = summarize_grid(grid)
	print("[AI_LEVEL_PARSER] Parsed level dimensions: ", summary["width"], "x", summary["height"])
	print("[AI_LEVEL_PARSER] Symbol counts: ", summary["counts"])
	if grid.size() > 0:
		print("[AI_LEVEL_PARSER] First row: ", String(grid[0]))
		print("[AI_LEVEL_PARSER] Last row: ", String(grid[grid.size() - 1]))
