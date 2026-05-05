extends Node
class_name Skills

signal skill_acquired

@export var cooldown = .1
@onready var actor = get_parent()

var canUse = true

var skills : Array[Node]
var activeSkill : Skill

func _ready() -> void:
	skills = get_children()
	for skill in skills:
		skill.skill_used.connect(_activate_skills)

func _on_skill_acquired(node : Node) -> void:
	if not node is Skill: return
	if not node in skills:
		skills.append(node)
		skill_acquired.emit(node)

func _activate_skills(skill : Skill) -> void:
	if canUse == false: return
	activeSkill = skill
	canUse = false
	await get_tree().create_timer(cooldown+skill.skillDuration).timeout
	canUse = true

func cancelSkill(skill : Skill) -> void:
	if skill == activeSkill and activeSkill.cancelable:
		activeSkill.cancel()
