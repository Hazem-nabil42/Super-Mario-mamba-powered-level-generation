extends Attribute
class_name Health

@export var maxHealth : float = 100
@export var health : float = 100
@onready var bar : TextureProgressBar = get_node("../../HealthBar")

signal health_changed
signal died
var counter = 0
var init_position
func _ready():
	init_position = owner.position
	bar.value = (health/maxHealth)*100
	bar.max_value = 100
	if owner.NPC:
		bar.hide()

func add_to_health(healthToAdd : float) -> void:
	health = clamp(health+healthToAdd,0,maxHealth)

func take_damage(damage) -> void:
	counter += 1
	if counter > 10:
		counter = 0
		#owner.position = init_position
	add_to_health(-damage)
	health_changed.emit()
	if health == 0:
		died.emit()

func _on_health_changed() -> void:
	bar.value = (health/maxHealth)*100
