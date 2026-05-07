extends CanvasLayer

@onready var mini_map = $Panel/MiniMap

const TILE_SIZE = 4

var colors = {
	"X": Color(0.4, 0.25, 0.1),   # ground
	"-": Color(0, 0, 0, 0),       # air
	"E": Color.RED,              # enemy
	"S": Color.ORANGE,           # breakable
	"?": Color.YELLOW,           # question block
	"o": Color.GOLD,             # coin
	"<": Color.GREEN,
	">": Color.GREEN,
	"[": Color.DARK_GREEN,
	"]": Color.DARK_GREEN
}

func _ready():
	layer = 100 # High layer to be on top
	visible = true

func generate_preview(grid_string: String):
	if grid_string == "":
		print("[AI_DEBUG] MiniMap: Empty grid string received.")
		return
		
	var rows = grid_string.split("\n")
	if rows.size() == 0: return
	var height = rows.size()
	var width = rows[0].length()
	
	print("[AI_DEBUG] MiniMap: Generating preview for ", width, "x", height)
	visible = true

	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)

	for y in range(height):
		var row = rows[y]
		if row.length() == 0: continue
		for x in range(min(width, row.length())):
			var tile = row[x]
			var col = colors.get(tile, Color.GRAY)
			img.set_pixel(x, y, col)

	# تكبير الصورة عشان تبان
	img.resize(width * TILE_SIZE, height * TILE_SIZE, Image.INTERPOLATE_NEAREST)

	var tex = ImageTexture.create_from_image(img)
	mini_map.texture = tex
