extends Node2D

@onready var flag_sprite = $Flag
@onready var pole_sprite = $Pole
@onready var area = $Area2D

signal player_reached_flag
var activated = false

func _ready():
	add_to_group("EndFlagGroup")
	area.body_entered.connect(_on_body_entered)
	
	# Fallback visual generation in case user hasn't set textures
	if flag_sprite.texture == null:
		_create_fallback_visuals()

func _create_fallback_visuals():
	# Create a simple pole
	var pole_rect = ColorRect.new()
	pole_rect.size = Vector2(16, 250)
	pole_rect.color = Color.GOLD
	pole_rect.position = Vector2(-8, -200)
	pole_sprite.add_child(pole_rect)
	
	var pennant = ColorRect.new()
	pennant.size = Vector2(60, 40)
	pennant.color = Color.RED
	pennant.position = Vector2(8, -190)
	pennant.z_index = 10
	flag_sprite.add_child(pennant)
	
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 2000)
	col.shape = shape
	area.add_child(col)
	area.collision_layer = 0
	area.collision_mask = 1 # Collide with player on layer 1

func _on_body_entered(body):
	if activated: return
	if body.is_in_group("Player"):
		activated = true
		
		# Animate the flag dropping
		var tween = create_tween()
		var drop_y = 150 # How much to drop
		# If we added custom visuals, slide them
		tween.tween_property(flag_sprite, "position:y", flag_sprite.position.y + drop_y, 0.5)\
			.set_trans(Tween.TRANS_BOUNCE)\
			.set_ease(Tween.EASE_OUT)
			
		tween.tween_callback(func():
			if body.has_method("win_level"):
				body.win_level()
			player_reached_flag.emit()
		)
