extends Skill
class_name Dash

@export var dashIntensity : float = .7

func use_skill():
	super()
	actor.push(Vector2.ZERO,dashIntensity)
	actor.dodge(skillDuration)

	actor.vfx.get_node("Dash").emitting = true
	await get_tree().create_timer(skillDuration+.1).timeout
	actor.vfx.get_node("Dash").emitting = false
