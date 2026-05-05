class_name VFX extends Effects

func _ready():
	await owner.ready
	var health = owner.health
	if not health: return
	health.health_changed.connect(func():
		play_effect("Slash")
	)

func play_effect(_name):
	super(_name)
