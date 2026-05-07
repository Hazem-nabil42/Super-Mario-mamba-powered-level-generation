extends CanvasLayer

@onready var label = $Label

func _ready():
	add_to_group("HUD")
	update_deaths(0) # Initial display

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
