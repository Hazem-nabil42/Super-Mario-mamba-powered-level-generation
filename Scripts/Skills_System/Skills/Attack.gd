extends AttackSkill
class_name Attack

var hitboxes : Hitboxes

func use_skill() -> void:
	super()
	await get_tree().create_timer(.5).timeout
	sprite = actor.sprite as AnimatedSprite2D
	actor.push(Vector2.ZERO,momentum)
	hitboxes = actor.get_node("Hitboxes")
	if hitboxes:
		hitboxes.listen(sprite.sideDir,self,hitboxDuration)
