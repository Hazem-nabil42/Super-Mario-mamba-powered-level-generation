extends CanvasLayer

@onready var mini_map = $Panel/MiniMap

const TILE_SIZE = 4

# new variables
var cached_texture : ImageTexture
var map_width := 0
var map_height := 0

# player
@onready var player_dot = $Panel/MiniMapPlayer
@onready var camera = get_viewport().get_camera_2d()
@onready var player = get_tree().get_first_node_in_group("Player")

var colors = {
	"X": Color(0.55, 0.35, 0.15),  # ground warm
	"-": Color(0,0,0,0),
	"E": Color(1, 0.2, 0.2),       # enemy soft red
	"S": Color(1, 0.6, 0.2),       # breakable orange
	"?": Color(1, 0.9, 0.2),       # question glow
	"o": Color(1, 0.85, 0.1),      # coin gold
	"<": Color(0.3, 1, 0.3),
	">": Color(0.3, 1, 0.3),
	"[": Color(0.15, 0.6, 0.15),
	"]": Color(0.15, 0.6, 0.15)
}

func _ready():
	layer = 100 # High layer to be on top
	visible = true
	scale = Vector2(0,0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

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
	cached_texture = tex
	mini_map.texture = cached_texture
	map_width = width * TILE_SIZE
	map_height = height * TILE_SIZE
	
	# Apply styling to Panel to fix screen dimness and add professional border
	var panel = $Panel
	panel.anchor_right = 0
	panel.anchor_bottom = 0
	panel.size = Vector2(map_width, map_height)
	panel.position = Vector2(25, 25) # Top-left offset margin
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.border_color = Color(0.9, 0.7, 0.2, 1.0) # Professional Gold border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.anti_aliasing = true
	
	panel.add_theme_stylebox_override("panel", style)
	
	mini_map.position = Vector2(0, 0)
	mini_map.size = Vector2(map_width, map_height)
