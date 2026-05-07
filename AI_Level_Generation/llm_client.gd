extends Node
class_name LLMClient

signal model_loaded(response)
signal model_load_failed(error, response)
signal level_generated(response)
signal level_generation_failed(error, response)

const BASE_URL : String = "http://127.0.0.1:8000/api"
const LOAD_MODEL_ENDPOINT : String = "/load_model"
const GENERATE_ENDPOINT : String = "/generate"
const LevelPromptBuilder = preload("res://AI_Level_Generation/level_prompt_builder.gd")

func load_model(model_path:String, slot_name:String = "A") -> void:
	var payload = LevelPromptBuilder.make_load_model_payload(model_path, slot_name)
	_send_request(LOAD_MODEL_ENDPOINT, payload, "load_model")

func generate_level(difficulty: float, seed: int, use_auto_path: bool, slot_name: String = "A", patch_enemy_bias: Dictionary = {}) -> void:
	var payload = LevelPromptBuilder.make_generate_payload(difficulty, seed, use_auto_path, slot_name, patch_enemy_bias)
	_send_request(GENERATE_ENDPOINT, payload, "generate_level")

func _send_request(endpoint:String, payload:Dictionary, request_type:String) -> void:
	var url = BASE_URL + endpoint
	print("[AI_LLM_CLIENT] Sending request to:", url)
	print("[AI_LLM_CLIENT] Request payload:", JSON.stringify(payload))

	var request = HTTPRequest.new()
	request.set_meta("request_type", request_type)
	request.set_meta("request_url", url)
	add_child(request)
	request.request_completed.connect(_on_request_completed)
	var err = request.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		_emit_request_failed(request_type, "failed to start", "HTTP request start error: %d" % err)
		request.queue_free()

func _on_request_completed(result:Int, response_code:int, headers:Array, body:PackedByteArray) -> void:
	var request = sender() as HTTPRequest
	if not request:
		return
	var request_type = request.get_meta("request_type")
	var url = request.get_meta("request_url")
	var body_text = body.get_string_from_utf8()
	print("[AI_LLM_CLIENT] Response from:", url)
	print("[AI_LLM_CLIENT] Status:", response_code)
	print("[AI_LLM_CLIENT] Body:\n", body_text)
	if result != OK or response_code != 200:
		_emit_request_failed(request_type, "HTTP error %d" % result, "URL: %s\nResponse code: %d\nBody: %s" % [url, response_code, body_text])
		request.queue_free()
		return
	var parsed = JSON.parse_string(body_text)
	if parsed.error != OK:
		_emit_request_failed(request_type, "JSON parse failed", body_text)
		request.queue_free()
		return
	if request_type == "load_model":
		emit_signal("model_loaded", parsed.result)
	else:
		emit_signal("level_generated", parsed.result)
	request.queue_free()

func _emit_request_failed(request_type:String, error, response) -> void:
	if request_type == "load_model":
		emit_signal("model_load_failed", error, response)
	else:
		emit_signal("level_generation_failed", error, response)
