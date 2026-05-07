extends Node
class_name LevelPromptBuilder

static func make_load_model_payload(model_path:String, slot_name:String = "A") -> Dictionary:
	return {
		"model_path": model_path,
		"slot_name": slot_name,
	}

static func make_generate_payload(difficulty: float, seed: int, use_auto_path: bool, slot_name:String = "A", patch_enemy_bias: Dictionary = {}) -> Dictionary:
	return {
		"difficulty": difficulty,
		"seed": seed,
		"use_auto_path": use_auto_path,
		"slot_name": slot_name,
		"patch_enemy_bias": patch_enemy_bias,
	}
