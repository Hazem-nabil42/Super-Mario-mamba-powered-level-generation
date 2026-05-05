extends Node
class_name Skill

signal skill_used

@export var SkillName : String
@export_group("Duration")
@export_range(.1,40,.01,"or_greater") var cooldown : float = 1
@export_range(0,1,.01,"or_greater") var skillDuration : float = .4
@export_range(0,1,.01,"or_greater") var stunDuration : float = .4

@export_group("Main")
@export var animState : String
@export var inputListener: String = "skill"

@export_subgroup("Extra")
@export var cancelable : bool = true

@export_group("Forces")
@export var momentum : float = 1
@export var force : float = 1

@onready var actor : Character = owner
@onready var sprite = $"../../AnimatedSprite2D"

@onready var skills : Skills = get_parent()
var canUse = true
var timer : Timer = Timer.new()

func _ready():
	timer.name = "cooldown"
	timer.timeout.connect(reset_cooldown)
	timer.wait_time = cooldown
	add_child(timer)

#func _init():
	#name = SkillName

func use_skill():
	sprite.play_anim(animState, skillDuration)
	skill_used.emit(self)
	canUse = false
	timer.start()

func can_use_skill() -> bool:
	return (actor[inputListener] and canUse and skills.canUse)

func _process(_delta):
	if can_use_skill():
		use_skill()

func reset_cooldown():
	canUse = true
