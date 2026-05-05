extends Skill
class_name AttackSkill

@export_range(0,4,.05,"or_greater","or_less") var hitboxDuration : float = .2
@export_range(0,10,.1,"or_greater","or_less") var baseDamage = 0
@export_range(.5,10,.01,"or_greater","or_less") var damageMultiplier = 1

func apply(target):
	var damage = actor.strength.damage
	var direction = ((target.position-actor.position).normalized()+actor.lookDir).normalized()
	target.take_damage(baseDamage+damageMultiplier*damage)
	target.push(direction, force)

func cancel():
	print("This skill can't be canceled")
