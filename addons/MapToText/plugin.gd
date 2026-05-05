@tool
extends EditorPlugin

var selecting = false
var start_pos
var end_pos
var tilemap

func _enter_tree():
	var button = Button.new()
	button.text = "Select & Convert"
	button.connect("pressed", Callable(self, "_on_button_pressed"))
	add_control_to_container(CONTAINER_TOOLBAR, button)

func _on_button_pressed():
	var editor = get_editor_interface()
	var scene = editor.get_edited_scene_root()
	if not scene:
		printerr("No scene loaded!")
		return

	# ✅ Get the TileMapLayer node
	tilemap = scene.get_node_or_null("Map") # <-- This was the error
	if not tilemap:
		printerr("No 'Map' TileMap node found!")
		return

	print("Click and drag in the 2D viewport to select an area...")

	selecting = true
	var viewport = editor.get_scene_root()
	viewport.connect("gui_input", Callable(self, "_on_gui_input"))

func _on_gui_input(event):
	if not selecting:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_pos = event.position
			else:
				end_pos = event.position
				selecting = false
				_process_selection()

func _process_selection():
	if not tilemap:
		return

	var start_cell = tilemap.local_to_map(start_pos)
	var end_cell = tilemap.local_to_map(end_pos)

	var min_x = min(start_cell.x, end_cell.x)
	var max_x = max(start_cell.x, end_cell.x)
	var min_y = min(start_cell.y, end_cell.y)
	var max_y = max(start_cell.y, end_cell.y)

	var result = ""
	for y in range(min_y, max_y + 1):
		var line = ""
		for x in range(min_x, max_x + 1):
			var cell = tilemap.get_cell_source_id(Vector2i(x, y))
			line += str(cell)
		result += line + "\n"

	print("Selected area:\n", result)
