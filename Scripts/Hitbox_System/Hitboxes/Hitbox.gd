extends Area2D
class_name Hitbox

@onready var collisionShape : CollisionShape2D = $CollisionShape2D
var timer = Timer.new()
var sender : Node

func _ready() -> void:
	if not collisionShape: return
	timer.name = "Duration"
	deactivate()
	timer.timeout.connect(deactivate)
	area_entered.connect(areaEntered)
	add_child(timer)

func activate(skill : Node, time : float = 0):
	sender = skill
	collisionShape.disabled = false
	collisionShape.visible = true
	if time > 0:
		timer.start(time)
	
func deactivate() -> void:
	collisionShape.disabled = true
	collisionShape.visible = false

func areaEntered(hit):
	sender.apply(hit.get_parent())
