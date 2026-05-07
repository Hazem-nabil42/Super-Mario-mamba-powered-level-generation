extends CanvasLayer

@onready var bar = $ProgressBar
@onready var timer = $ProgressTimer
@onready var label = $Label

var fake_progress := 0.0
var pulse_tween : Tween

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	_start_pulse_animation()

func _start_pulse_animation():
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(label, "scale", Vector2(2.1, 2.1), 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_property(label, "scale", Vector2(1.9, 1.9), 0.6).set_trans(Tween.TRANS_SINE)
	pulse_tween.parallel().tween_property(label, "modulate:a", 0.7, 0.6)
	pulse_tween.tween_property(label, "modulate:a", 1.0, 0.6)
	
	# Bar "Energy" pulse
	if bar:
		var bar_tween = create_tween().set_loops()
		bar_tween.tween_property(bar, "modulate:v", 1.5, 0.4)
		bar_tween.tween_property(bar, "modulate:v", 1.0, 0.4)

func _on_timer_timeout():
	# loading وهمي لحد 90%
	fake_progress = min(fake_progress + 0.02, 0.9)
	set_progress(fake_progress)

func set_progress(value: float):
	if bar and is_inside_tree():
		var tween = create_tween().set_parallel(true)
		tween.tween_property(bar, "value", value * 100.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# Smooth color transition from Cyan to Bright Green
		var target_color = Color.CYAN.lerp(Color.GREEN, value)
		tween.tween_property(bar, "modulate", target_color, 0.4)

func finish_loading():
	set_progress(1.0)
	if pulse_tween: pulse_tween.kill()
	
	if label and is_inside_tree():
		var tween = create_tween()
		var t1 = tween.tween_property(label, "scale", Vector2(2.5, 2.5), 0.3)
		if t1: t1.set_trans(Tween.TRANS_ELASTIC)
		var t2 = tween.parallel().tween_property(label, "modulate:a", 0.0, 0.3)
		
		await get_tree().create_timer(0.4).timeout
	
	queue_free()
