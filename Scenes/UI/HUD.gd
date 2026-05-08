extends CanvasLayer

@onready var label = $Label

func _ready():
	add_to_group("HUD")
	update_deaths(0)
	# ✅ OS.has_feature("mobile") هو الطريقة الصح في Godot 4
	# بيرجع true على Android و iOS فقط، مش على PC
	if OS.has_feature("mobile"):
		call_deferred("_add_mobile_controls")

func update_deaths(death_count: int):
	var total = 3
	var remaining = max(0, total - death_count)
	label.text = "LIVES: " + str(remaining) + "/" + str(total)
	
	if remaining <= 1:
		label.modulate = Color.RED
	else:
		label.modulate = Color.WHITE

func _create_mobile_btn(action_name: String, pos: Vector2, size: Vector2, txt: String) -> void:
	var btn = TouchScreenButton.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	btn.shape = shape
	btn.position = pos + size / 2.0
	btn.action = action_name
	
	var vis = ColorRect.new()
	vis.size = size
	vis.position = pos
	vis.color = Color(0, 0, 0, 0.45)
	
	var lbl = Label.new()
	lbl.text = txt
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", size.x * 0.4)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	vis.add_child(lbl)
	
	add_child(btn)
	add_child(vis)

func _add_mobile_controls():
	var screen = get_viewport().get_visible_rect().size
	print("[HUD] Mobile detected! Screen: ", screen)
	
	var btn_size_val = clamp(screen.x * 0.12, 80.0, 200.0)
	var btn_v_size = Vector2(btn_size_val, btn_size_val)
	var jump_size = Vector2(btn_size_val * 1.3, btn_size_val * 1.3)
	
	var margin_x = screen.x * 0.04
	var margin_bottom = 20.0
	
	var left_right_y = screen.y - btn_v_size.y - margin_bottom
	_create_mobile_btn("Left",  Vector2(margin_x, left_right_y), btn_v_size, "<")
	_create_mobile_btn("Right", Vector2(margin_x + btn_v_size.x + margin_x, left_right_y), btn_v_size, ">")
	
	var jump_x = screen.x - jump_size.x - margin_x
	var jump_y = screen.y - jump_size.y - margin_bottom
	_create_mobile_btn("Jump", Vector2(jump_x, jump_y), jump_size, "UP")
