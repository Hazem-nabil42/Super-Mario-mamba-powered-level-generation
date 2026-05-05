class_name AnimationController extends AnimatedSprite2D

@export var canLean : bool = false
@export var inflection : float = .3
@onready var actor : Character = owner

var MovementAnim : bool = true
var animState : String = ""
var animDir : String = ""
var sideDir : String = ""
var animTime : float = 0

func _ready() -> void:
	if not inflection: inflection = .707

func _process(_delta) -> void:
	var lookDir = actor.lookDir
	var moveDir = Vector2(actor.moveDir.x, 0)
	if MovementAnim:
		_detectanimState(moveDir)
		_adjustH(lookDir, true)
		if actor.is_on_floor():
			play(animState)
		else:
			play("Jump")
	else:
		play(animState)
	if animTime == 0 and MovementAnim == false:
		await animation_finished
		MovementAnim = true

func play_anim(state, time : float = 0):
	animTime = time
	animState = state
	MovementAnim = false
	if animTime != 0:
		await get_tree().create_timer(time).timeout
		MovementAnim = true

func _leanToward():
	if canLean:
		if MovementAnim:
			rotation = lerp(rotation,actor.velocity.x*.002,.2)
		else:
			rotation = lerp(rotation,0.0,.2)

func _detectanimState(dir) -> void:
	if dir == Vector2.ZERO:
		animState = "Idle"
	else:
		animState = "Run"

func _adjustH(dir: Vector2, isRight: bool) -> int:
	if dir.x >= 0:
		flip_h = not isRight
		return 1
	else:
		flip_h = isRight
		return -1
	
func _adjustV(dir: Vector2, isRight: bool)-> void:
	if dir.y >= 0:
		flip_v = not isRight
	else:
		flip_v = isRight
