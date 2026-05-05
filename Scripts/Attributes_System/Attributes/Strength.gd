extends Attribute
class_name Strength

@export var base_damage : float = 10

var damage : float

func _ready():
	damage = base_damage
