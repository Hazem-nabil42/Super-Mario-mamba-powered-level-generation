extends CharacterBody2D
class_name Character

const GRAVITY = 800

@onready var hurtbox : Area2D = $HurtBox
@onready var sprite : AnimatedSprite2D = $AnimatedSprite2D
@export var NPC : bool = false

var moveDir : Vector2 = Vector2.ZERO
var lookDir : Vector2 = Vector2(0,1)
var jump : bool = false
var inAir : bool = false
@export var speed : float = 170
@export var acceleration : float = .5
@export var jump_force : float = 110

var flash = 0

const FALL_MULTIPLIER = 1
const LOW_JUMP_MULTIPLIER = 2

func _process(delta : float) -> void:
	flash_fadeout(delta)

func flash_fadeout(delta: float) -> void:
	if flash > 0:
		flash = clamp(flash-(delta*2), 0,1)
		sprite.material.set_shader_parameter("intensity", flash)

func dodge(time: float) -> void:
	hurtbox.get_node("CollisionShape2D").disabled = true
	await get_tree().create_timer(time).timeout
	hurtbox.get_node("CollisionShape2D").disabled = false
