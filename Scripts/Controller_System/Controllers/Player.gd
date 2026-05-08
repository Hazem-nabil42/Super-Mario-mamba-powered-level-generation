@icon("res://Assets/Icons/player.svg")
class_name Player extends Character

const COYOTE_TIME = .3
const JUMP_CLOSURE_TIME = .1
var playerLevel = 0.2
var holdingJump := false
var coyote_timer : float = 0.0
var jumpTimer : float = 0.0
var Force = 0
var spawnLocation : Vector2
var endTime = 0
var deathTimes = 0
var dying = false
var is_transitioning = false

func _ready():
	spawnLocation = position
	is_transitioning = true
	get_parent().EnemyDeath.connect(func(enemy):
		Force = 120
	)

func estimateLevel():
	var max_expected_time = 120.0
	var max_expected_deaths = 2.0
	
	var deaths = float(deathTimes)
	var time_taken = float(endTime)
	
	var time_score = clamp(1.0 - (time_taken / max_expected_time), 0.0, 1.0)
	var death_score = clamp(1.0 - (deaths / max_expected_deaths), 0.0, 1.0)
	
	#playerLevel = time_score * death_score
	var performance = time_score * death_score

	# نزود الصعوبة تدريجياً لما اللاعب ينجح
	playerLevel = lerp(playerLevel, performance + 0.15, 0.6)
	playerLevel = clamp(playerLevel, 0.05, 0.95)
	
	print("player level estimation is ", playerLevel)
	endTime = 0
	deathTimes = 0
	

func _physics_process(delta: float) -> void:
	if is_transitioning: 
		velocity = Vector2.ZERO
		return
		
	endTime += delta
	if not is_transitioning and position.x > get_parent().rightmost_world + 300:
		win_level()
		
	if position.y > 100:
		die()
	moveDir = Input.get_vector("Left","Right","Up","Down")
	holdingJump = Input.is_action_pressed("Jump")
	jump = Input.is_action_just_pressed("Jump")
	moveDir = Vector2(moveDir.x,0)
	if moveDir.x:
		lookDir = moveDir
	else:
		lookDir = lookDir
	
	var target_x = moveDir.x * speed * delta * 60
	velocity.x = lerp(velocity.x, target_x, .5)
	if jump:
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if not is_on_floor():
		jumpTimer -= delta
	else:
		jumpTimer = JUMP_CLOSURE_TIME
	
	if Force > 0:
		velocity.y -= Force
		Force -= 30
	if coyote_timer > 0.0 and jumpTimer > 0.0:
		velocity.y = -jump_force * 3
		coyote_timer = 0.0
	if velocity.y > 0:
		velocity.y += GRAVITY * FALL_MULTIPLIER * delta
	elif velocity.y < 0 and not holdingJump:
		velocity.y += GRAVITY * LOW_JUMP_MULTIPLIER * delta
	else:
		velocity.y += GRAVITY * delta
	velocity.y = clamp(velocity.y, -500, 500)
	move_and_slide()

func win_level():
	if is_transitioning: return
	is_transitioning = true
	velocity = Vector2.ZERO
	estimateLevel()
	if get_parent().has_method("ChangeMap"):
		get_parent().ChangeMap(playerLevel)
	position = spawnLocation

func win():
	pass

func die():
	
	if dying == true: return
	dying = true
	deathTimes += 1
	# ⭐ لو اللاعب مات 3 مرات → غير الماب فوراً
	if deathTimes >= 3:
		var new_diff = get_adaptive_difficulty()
		deathTimes = 0
		get_parent().ChangeMap(new_diff)
	
	# Update HUD
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud:
		hud.update_deaths(deathTimes)
	get_node("CollisionShape2D").set_deferred("disabled",true)
	hurtbox.get_node("CollisionShape2D").set_deferred("disabled",true)
	flash = 1
	Force = 120
	sprite.play_anim("Death", 1)
	get_parent().restart()
	await get_tree().create_timer(1).timeout
	position = spawnLocation
	get_node("CollisionShape2D").set_deferred("disabled",false)
	hurtbox.get_node("CollisionShape2D").set_deferred("disabled",false)
	dying = false

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		die()
		
func freeze():
	is_transitioning = true
	velocity = Vector2.ZERO

func unfreeze():
	is_transitioning = false

# Adaptive level generation
func get_adaptive_difficulty() -> float:
	var death_factor = clamp(deathTimes / 3.0, 0.0, 1.0)
	var time_factor = clamp(endTime / 60.0, 0.0, 1.0)

	# لو بيموت كتير → نزود الصعوبة
	# لو الوقت بيطول → نقلل الصعوبة
	var adaptive = playerLevel + (death_factor * 0.3) - (time_factor * 0.2)

	adaptive = clamp(adaptive, 0.05, 0.95)
	print("Adaptive difficulty =", adaptive)
	return adaptive
