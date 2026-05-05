extends AIController2D

var move := Vector2.ZERO
var attack := false
var enemies := []

func _ready():
	enemies = get_tree().get_nodes_in_group("Enemy")

func get_obs() -> Dictionary:
	var enemy = null
	var nearest_dist := INF
	for e in enemies:
		if e == null or not e.is_inside_tree():
			continue
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest_dist = d
			enemy = e

	var direction := Vector2.ZERO
	var distance := 0.0
	if enemy != null:
		var to_enemy = enemy.global_position - global_position
		distance = to_enemy.length()
		direction = to_enemy.normalized()

	return {
		"obs": [
			direction.x,
			direction.y,
			distance / 500.0,
			1.0 if attack else 0.0
		]
	}

func get_action_space() -> Dictionary:
	return {
		"move": {"size": 2, "action_type": "continuous"},
		"attack": {"size": 1, "action_type": "discrete"}
	}

func set_action(action: Dictionary) -> void:
	move.x = clamp(action["move"][0], -1, 1)
	move.y = clamp(action["move"][1], -1, 1)
	attack = int(action["attack"]) == 1
