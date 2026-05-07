extends Node
class_name LevelManagerAI

signal model_ready
signal model_load_failed(error, response)
signal generation_finished(grid_string:String, difficulty_label:String)
signal generation_failed(error, response)

const LLMClient = preload("res://AI_Level_Generation/llm_client.gd")
const LevelParser = preload("res://AI_Level_Generation/level_parser.gd")
var llm_client : LLMClient

func _ready() -> void:
	llm_client = LLMClient.new()
	add_child(llm_client)

	llm_client.model_loaded.connect(_on_model_loaded)
	llm_client.model_load_failed.connect(_on_model_load_failed)
	llm_client.level_generated.connect(_on_level_generated)
	llm_client.level_generation_failed.connect(_on_level_generation_failed)

func load_model(model_path:String, slot_name:String = "A") -> void:
	llm_client.load_model(model_path, slot_name)

func generate_level(difficulty: float, seed: int, use_auto_path: bool, slot_name:String = "A", patch_enemy_bias: Dictionary = {}) -> void:
	llm_client.generate_level(difficulty, seed, use_auto_path, slot_name, patch_enemy_bias)

func _on_model_loaded(response) -> void:
	emit_signal("model_ready", response)

func _on_model_load_failed(error, response) -> void:
	emit_signal("model_load_failed", error, response)

func _on_level_generated(response) -> void:
	if typeof(response) == TYPE_DICTIONARY:
		var grid_string = response.get("grid_string", "")
		var difficulty_label = str(response.get("difficulty_label", "0.0"))
		LevelParser.log_level_text(grid_string)
		emit_signal("generation_finished", grid_string, difficulty_label)
	else:
		printerr("[AI_LEVEL_MANAGER] Invalid generation response:", response)
		emit_signal("generation_failed", "Invalid generation response", str(response))

func _on_level_generation_failed(error, response) -> void:
	emit_signal("generation_failed", error, response)
