class_name Slash extends AttackSkill

var hitboxes : Hitboxes
var key : String
@onready var ai = $"../../AIController2D"

func apply(target) -> void:
	actor.sfx.play_effect("Slash")
	super(target)
	ai.reward += 15
	#ai.reset()

func use_skill():
	super()
	hitboxes = actor.hitboxes
	actor.push(Vector2.ZERO,momentum)
	actor.sfx.play_effect("Swing")
	key = sprite.animDir+sprite.sideDir
	hitboxes.activate(key,self,hitboxDuration)
	ai.reward -= 5

func cancel():
	print("Canceled Slash")
	hitboxes.deactivate(key)
