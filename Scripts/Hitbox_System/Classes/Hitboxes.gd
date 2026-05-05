extends Node2D
class_name Hitboxes

func _ready():
	visible = true

func activate(key: String, receiver : Node, time : float = 0):
	var hitbox : Hitbox = get_node("Hitbox_"+key)
	hitbox.activate(receiver, time)

func deactivate(key : String):
	var hitbox : Hitbox = get_node("Hitbox_"+key)
	hitbox.deactivate()
