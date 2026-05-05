class_name SFX extends Effects

func _ready():
	await owner.ready
	var health = owner.health
	health = owner.health
	health.health_changed.connect(func():
		play_effect("Hit")
	)

func play_effect(_name):
	super(_name)
