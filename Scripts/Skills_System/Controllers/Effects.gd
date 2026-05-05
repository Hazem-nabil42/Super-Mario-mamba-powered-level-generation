class_name Effects extends Node2D

func play_effect(_name):
	var node = get_node(_name)
	if not node: return
	if self is VFX:
		node.emitting = true
	else:
		node.play()
