extends CanvasLayer

@onready var label = $Label

func _ready():
	add_to_group("HUD")
	update_deaths(0) # Initial display
	if OS.has_feature("mobile") or DisplayServer.is_touchscreen_available():
		_add_mobile_controls()

func update_deaths(death_count: int):
	# User wants 3/3 -> 2/3 -> 1/3
	var total = 3
	var remaining = max(0, total - death_count)
	label.text = "LIVES: " + str(remaining) + "/" + str(total)
	
	# Visual feedback if low
	if remaining <= 1:
		label.modulate = Color.RED
	else:
		label.modulate = Color.WHITE

func _create_mobile_btn(action_name: String, pos: Vector2, size: Vector2, txt: String) -> void:
	var btn = TouchScreenButton.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	
	btn.shape = shape
	btn.position = pos + size / 2.0 # Center the interaction area
	btn.action = action_name
	
	var vis = ColorRect.new()
	vis.size = size
	vis.position = pos
	vis.color = Color(0, 0, 0, 0.45) # Slightly darker for visibility
	
	# Rounded appearance using StyleBoxFlat override isn't easy on ColorRect, 
	# but we can at least ensure it's positioned well.
	
	var lbl = Label.new()
	lbl.text = txt
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size.x * 0.4) # Dynamic font size
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	vis.add_child(lbl)
	
	add_child(btn)
	add_child(vis)

func _add_mobile_controls():
	var screen = get_viewport().get_visible_rect().size
	print("[AI_DEBUG] Adding mobile controls for screen size: ", screen)
	
	# Responsive sizing: 15% of screen width (with limits)
	var btn_size_val = clamp(screen.x * 0.12, 100.0, 250.0)
	var btn_v_size = Vector2(btn_size_val, btn_size_val)
	var jump_size = Vector2(btn_size_val * 1.3, btn_size_val * 1.3)
	
	var margin_x = screen.x * 0.05
	var margin_y = screen.y * 0.20 # 20% margin from bottom to avoid home bars and stay fully visible
	
	var bottom_y = screen.y - btn_v_size.y - margin_y
	
	# Left Button
	_create_mobile_btn("Left", Vector2(margin_x, bottom_y), btn_v_size, "<")
	
	# Right Button
	_create_mobile_btn("Right", Vector2(margin_x + btn_v_size.x + (screen.x * 0.05), bottom_y), btn_v_size, ">")
	
	# Jump Button
	_create_mobile_btn("Jump", Vector2(screen.x - jump_size.x - margin_x, screen.y - jump_size.y - margin_y), jump_size, "UP")
