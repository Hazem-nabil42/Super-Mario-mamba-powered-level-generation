class_name Enemy extends Character

@onready var Rays:= $Rays
var dead = false
signal death

func _physics_process(delta: float) -> void:
	if dead: return
	lookDir = Rays.MoveDir
	moveDir = lookDir
	velocity = moveDir*20
	velocity.y += GRAVITY * delta * 5
	move_and_slide()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		flash = 1
		death.emit()
		get_node("CollisionShape2D").set_deferred("disabled",true)
		hurtbox.get_node("CollisionShape2D").set_deferred("disabled",true)
		sprite.play_anim("Death", .5)
		dead = true
		await get_tree().create_timer(.5).timeout
		queue_free()
