extends AIController2D

var enemies := []
var move := Vector2.ZERO
var attack := false
var initPosition : Vector2
var resetCounter = 0

func _ready():
	super()
	enemies = get_tree().get_nodes_in_group("Enemy")
	initPosition = get_parent().position

func reset():
	super()
	resetCounter += 1
	if resetCounter < 10: return;
	get_parent().position = initPosition
	resetCounter = 0

func get_reward() -> float:
	return reward

func get_nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := INF
	
	for e in enemies:
		if e == null or not e.is_inside_tree():
			continue
		var d = global_position.distance_to(e.global_position)
		if d < nearest_dist:
			nearest = e
			nearest_dist = d
	return nearest

func get_obs() -> Dictionary:
	var enemy = get_nearest_enemy()
	var direction := Vector2.ZERO
	var distance := 0.0

	if enemy != null:
		var to_enemy = enemy.global_position - global_position
		distance = to_enemy.length()
		direction = to_enemy.normalized()
	else:
		return {"obs": [0.0, 0.0, 0.0, 0.0]}
	
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
		"move": {
			"size": 2,
			"action_type": "continuous"
		},
		"attack": {
			"size": 1,
			"action_type": "discrete"
		}
	}

func set_action(action: Dictionary) -> void:
	move.x = clamp(action["move"][0], -1, 1)
	move.y = clamp(action["move"][1], -1, 1)
	attack = int(action["attack"]) == 1
