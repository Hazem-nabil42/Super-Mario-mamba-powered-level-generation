extends CanvasLayer

@onready var label = $Label

func _ready():
	add_to_group("HUD")
	update_deaths(0) # Initial display
	if OS.has_feature("web") or OS.has_feature("mobile"):
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

func _create_mobile_btn(action_name: String, btn_pos: Vector2, btn_size: Vector2, vis_pos: Vector2, vis_size: Vector2, txt: String) -> void:
	var btn = TouchScreenButton.new()
	var shape = RectangleShape2D.new()
	shape.size = btn_size
	
	# In TouchScreenButton, the position is the top-left if not passing passby, but RectangleShape2D uses origin at center for TouchScreenButton
	# Actually, TouchScreenButton with RectangleShape2D uses shape center relative to btn.position
	# So let's make it simpler: shape.size is the full width/height.
	# Usually TouchScreenButton expects the shape to define bounds around 0,0, but offset works differently based on shape.
	# Let's set position to exactly where the center of the shape should be.
	
	btn.shape = shape
	btn.position = btn_pos + btn_size / 2.0
	btn.action = action_name
	
	var vis = ColorRect.new()
	vis.size = vis_size
	vis.position = vis_pos
	vis.color = Color(0, 0, 0, 0.4)
	
	var lbl = Label.new()
	lbl.text = txt
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 80)
	lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	vis.add_child(lbl)
	
	add_child(btn)
	add_child(vis)

func _add_mobile_controls():
	# Screen size assumes ~ 1920x1080 scaling base
	# Left Button
	_create_mobile_btn("Left", Vector2(0, 580), Vector2(400, 500), Vector2(50, 780), Vector2(200, 200), "<")
	
	# Right Button
	_create_mobile_btn("Right", Vector2(400, 580), Vector2(400, 500), Vector2(350, 780), Vector2(200, 200), ">")
	
	# Jump Button
	_create_mobile_btn("Jump", Vector2(1320, 480), Vector2(600, 600), Vector2(1570, 730), Vector2(300, 300), "JUMP")
