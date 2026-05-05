extends Node2D

@onready var leftRay = $Left
@onready var rightRay = $Right
@onready var leftRay2 = $Left2
@onready var rightRay2 = $Right2

var MoveDir = Vector2(1,0)

func _physics_process(_delta):
	if not leftRay.is_colliding() or leftRay2.is_colliding():
		MoveDir = Vector2(1,0)
	elif not rightRay.is_colliding() or rightRay2.is_colliding():
		MoveDir = Vector2(-1,0)
