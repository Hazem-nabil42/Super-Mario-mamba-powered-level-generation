extends CanvasLayer

@onready var bar = $ProgressBar
@onready var timer = $ProgressTimer
@onready var label = $Label
@onready var color_rect = $ColorRect

# new tween
var progress_tween : Tween

var fake_progress := 0.0
var pulse_tween : Tween

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer.timeout.connect(_on_timer_timeout)
	if color_rect:
		color_rect.modulate.a = 1.0 # Ensure it's visible at start
	
	_setup_font_for_emojis()
	_start_pulse_animation()

func _setup_font_for_emojis():
	var font = FontFile.new()
	font.load("res://assets/fonts/NotoColorEmoji-Regular.ttf")
	
	# مهم جداً للويب
	font.antialiasing = TextServer.FONT_ANTIALIASING_LCD
	font.generate_mipmaps = true
	font.msdf = false
	
	label.add_theme_font_override("font", font)


func _start_pulse_animation():
	pulse_tween = create_tween().set_loops()
	pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	pulse_tween.tween_property(label, "scale", Vector2(2.1, 2.1), 0.6)
	pulse_tween.tween_property(label, "scale", Vector2(1.9, 1.9), 0.6)
	pulse_tween.parallel().tween_property(label, "modulate:a", 0.7, 0.6)
	pulse_tween.tween_property(label, "modulate:a", 1.0, 0.6)

	if bar:
		var bar_tween = create_tween().set_loops()
		bar_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bar_tween.tween_property(bar, "modulate:v", 1.2, 0.5)
		bar_tween.tween_property(bar, "modulate:v", 1.0, 0.5)

func _on_timer_timeout():
	var speed = lerp(0.05, 0.01, fake_progress) # يبطأ مع الوقت
	fake_progress = min(fake_progress + speed, 0.9)
	set_progress(fake_progress)

func set_progress(value: float):
	if not bar or not is_inside_tree():
		return
	
	if progress_tween:
		progress_tween.kill()
	
	progress_tween = create_tween().set_parallel(true)
	progress_tween.tween_property(bar, "value", value * 100.0, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var target_color = Color.CYAN.lerp(Color.GREEN, value)
	progress_tween.tween_property(bar, "modulate", target_color, 0.35)

func finish_loading():
	set_progress(1.0)

	if pulse_tween:
		pulse_tween.kill()

	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	# Fade UI elements
	if label:
		tween.tween_property(label, "modulate:a", 0.0, 0.5)

	if bar:
		tween.tween_property(bar, "modulate:a", 0.0, 0.5)

	# Fade out the whole screen overlay smoothly
	if color_rect:
		tween.tween_property(color_rect, "modulate:a", 0.0, 0.5)

	await tween.finished
	queue_free()
