extends Node
class_name AILevelGenerator

signal model_loaded(success: bool, response: Dictionary)
signal level_generated(grid_string: String, difficulty_label: String)
signal generation_failed(error: String, response: String)

@export var model_path: String = "https://mario_backend.hf.space/mario_model_mamba.pt"
@export var difficulty: float = 0.3
@export var seed_number: int = 0
@export var use_auto_path: bool = true

# ✅ المتغيرات الناقصة
const BASE_URL: String = "https://hazem42-mario-backend.hf.space/api"
var http_load: HTTPRequest = null
var http_generate: HTTPRequest = null

const LoadingScreen = preload("res://Scenes/UI/LoadingScreen.tscn")
var loading_instance : Node = null
var is_generating : bool = false

func _ready():
	print("[AI_DEBUG] UI Generator Ready.")
	load_model()

func show_loading():
	if loading_instance == null:
		loading_instance = LoadingScreen.instantiate()
		loading_instance.layer = 128 # Higher than MiniMap (100)
		get_tree().root.add_child(loading_instance)
		print("[AI_DEBUG] Loading Screen shown.")

func hide_loading():
	if loading_instance != null:
		loading_instance.finish_loading()
		loading_instance = null
		print("[AI_DEBUG] Loading Screen hidden.")
	is_generating = false

func load_model():
	if is_generating: return
	is_generating = true
	
	print("[AI_DEBUG] Initiating model load request...")
	show_loading()
	
	var url = BASE_URL + "/load_model"
	var headers = ["Content-Type: application/json"]
	var body = {
		"model_path": model_path,
		"slot_name": "A"
	}
	
	print("[AI_DEBUG] Target URL:", url)
	print("[AI_DEBUG] Payload:", JSON.stringify(body))
	
	http_load = HTTPRequest.new()
	add_child(http_load)
	http_load.request_completed.connect(_on_load_completed)
	var err = http_load.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_error("[AI_ERROR] Failed to start load request: " + str(err))
		hide_loading()
		model_loaded.emit(false, {"error": "Request failed", "code": err})

func _on_load_completed(result: int, response_code: int, headers: Array, body: PackedByteArray):
	var body_text = body.get_string_from_utf8()
	print("[AI_DEBUG] Load response code:", response_code)
	
	if response_code != 200:
		printerr("[AI_ERROR] Server returned error: ", body_text)
		hide_loading()
		model_loaded.emit(false, {"error": "HTTP error", "code": response_code, "body": body_text})
		return
	
	var parsed = JSON.parse_string(body_text)
	if parsed == null:
		printerr("[AI_ERROR] Failed to parse JSON: ", body_text)
		hide_loading()
		model_loaded.emit(false, {"error": "JSON parse failed", "body": body_text})
		return
	
	print("[AI_DEBUG] Model loaded successfully on backend.")
	hide_loading()
	model_loaded.emit(true, parsed)

func generate_level():
	if is_generating: 
		print("[AI_DEBUG] Generation already in progress. Skipping request.")
		return
	is_generating = true
	
	print("[AI_DEBUG] Initiating level generation request...")
	show_loading()
	
	var url = BASE_URL + "/generate"
	var headers = ["Content-Type: application/json"]
	var body = {
		"difficulty": difficulty,
		"seed": seed_number if seed_number > 0 else randi_range(1, 99999),
		"use_auto_path": use_auto_path,
		"slot_name": "A",
		"patch_enemy_bias": {}
	}

	print("[AI_DEBUG] Target URL:", url)
	print("[AI_DEBUG] Payload:", JSON.stringify(body))
	
	http_generate = HTTPRequest.new()
	add_child(http_generate)
	http_generate.request_completed.connect(_on_generate_completed)
	var err = http_generate.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_error("[AI_ERROR] Request failed to start: " + str(err))
		hide_loading()
		generation_failed.emit("Request failed", "Error code: " + str(err))

func _on_generate_completed(result: int, response_code: int, headers: Array, body: PackedByteArray):
	var body_text = body.get_string_from_utf8()
	print("[AI_DEBUG] Generate response code:", response_code)
	hide_loading()

	if response_code != 200:
		printerr("[AI_ERROR] Generation failed: ", body_text)
		generation_failed.emit("HTTP error", "Code: " + str(response_code))
		return

	var parsed = JSON.parse_string(body_text)
	if parsed == null:
		printerr("[AI_ERROR] JSON parse error in generation response.")
		generation_failed.emit("JSON parse failed", body_text)
		return

	if "grid_string" in parsed:
		var grid_string = parsed["grid_string"]
		var diff_label = parsed.get("difficulty_label", "Level")
		print("[AI_DEBUG] SUCCESS: Level generated.")
		level_generated.emit(grid_string, diff_label)
	else:
		printerr("[AI_ERROR] Invalid response format: missing grid_string")
		generation_failed.emit("Missing grid_string", body_text)
