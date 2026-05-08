extends Node
class_name AILevelGenerator

signal model_loaded(success: bool, response: Dictionary)
signal level_generated(grid_string: String, difficulty_label: String)
signal generation_failed(error: String, response: String)

@export var model_path: String  = "mario_model_mamba.pt"
@export var difficulty: float   = 0.3
@export var seed_number: int    = 0
@export var use_auto_path: bool = true

const BASE_URL: String = "https://hazem42-mario-backend.hf.space/api"

# ── HTTP nodes ──────────────────────────────────────────────────────────────
var http_load:     HTTPRequest = null
var http_generate: HTTPRequest = null
var http_poll:     HTTPRequest = null   # used for polling /result/{job_id}

# ── State ────────────────────────────────────────────────────────────────────
var current_job_id:   String = ""
var poll_timer:       Timer  = null
const POLL_INTERVAL:  float  = 2.0     # seconds between polls

var is_generating: bool = false

# ── Loading screen ───────────────────────────────────────────────────────────
const LoadingScreen = preload("res://Scenes/UI/LoadingScreen.tscn")
var loading_instance: Node = null


# ════════════════════════════════════════════════════════════════════════════
#  READY
# ════════════════════════════════════════════════════════════════════════════
func _ready():
	print("[AI_DEBUG] UI Generator Ready.")

	# Build the polling timer once
	poll_timer = Timer.new()
	poll_timer.wait_time  = POLL_INTERVAL
	poll_timer.one_shot   = false
	poll_timer.autostart  = false
	poll_timer.timeout.connect(_on_poll_tick)
	add_child(poll_timer)

	load_model()


# ════════════════════════════════════════════════════════════════════════════
#  LOADING SCREEN helpers
# ════════════════════════════════════════════════════════════════════════════
func show_loading(message: String = "Generating level…"):
	if loading_instance == null:
		loading_instance = LoadingScreen.instantiate()
		loading_instance.layer = 128
		get_tree().root.add_child(loading_instance)

	# If your LoadingScreen exposes a set_message() method, call it here:
	if loading_instance.has_method("set_message"):
		loading_instance.set_message(message)

	print("[AI_DEBUG] Loading Screen shown — ", message)


func hide_loading():
	if loading_instance != null:
		loading_instance.finish_loading()
		loading_instance = null
		print("[AI_DEBUG] Loading Screen hidden.")
	is_generating = false


# ════════════════════════════════════════════════════════════════════════════
#  LOAD MODEL
# ════════════════════════════════════════════════════════════════════════════
func load_model():
	if is_generating:
		return
	is_generating = true

	print("[AI_DEBUG] Initiating model load request…")
	show_loading("Loading AI model…")

	var url     = BASE_URL + "/load_model"
	var headers = ["Content-Type: application/json"]
	var body    = {"model_path": model_path, "slot_name": "A"}

	http_load = HTTPRequest.new()
	add_child(http_load)
	http_load.request_completed.connect(_on_load_completed)
	var err = http_load.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_error("[AI_ERROR] Failed to start load request: " + str(err))
		hide_loading()
		model_loaded.emit(false, {"error": "Request failed", "code": err})


func _on_load_completed(result: int, response_code: int, _headers: Array, body: PackedByteArray):
	var body_text = body.get_string_from_utf8()
	print("[AI_DEBUG] Load response code:", response_code)
	hide_loading()

	if response_code != 200:
		printerr("[AI_ERROR] Server returned error: ", body_text)
		model_loaded.emit(false, {"error": "HTTP error", "code": response_code, "body": body_text})
		return

	var parsed = JSON.parse_string(body_text)
	if parsed == null:
		printerr("[AI_ERROR] Failed to parse JSON: ", body_text)
		model_loaded.emit(false, {"error": "JSON parse failed", "body": body_text})
		return

	print("[AI_DEBUG] Model loaded successfully on backend.")
	model_loaded.emit(true, parsed)


# ════════════════════════════════════════════════════════════════════════════
#  GENERATE LEVEL  — Step 1: enqueue the job
# ════════════════════════════════════════════════════════════════════════════
func generate_level():
	if is_generating:
		print("[AI_DEBUG] Generation already in progress. Skipping.")
		return
	is_generating   = true
	current_job_id  = ""

	show_loading("Sending generation request…")

	var url     = BASE_URL + "/generate"
	var headers = ["Content-Type: application/json"]
	var body    = {
		"difficulty":       difficulty,
		"seed":             seed_number if seed_number > 0 else randi_range(1, 99999),
		"use_auto_path":    use_auto_path,
		"slot_name":        "A",
		"patch_enemy_bias": {}
	}

	print("[AI_DEBUG] Enqueue request → ", url)
	http_generate = HTTPRequest.new()
	add_child(http_generate)
	http_generate.request_completed.connect(_on_job_created)
	var err = http_generate.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if err != OK:
		push_error("[AI_ERROR] Request failed to start: " + str(err))
		hide_loading()
		generation_failed.emit("Request failed", "Error code: " + str(err))


# ── Called when the server answers the /generate POST ───────────────────────
func _on_job_created(result: int, response_code: int, _headers: Array, body: PackedByteArray):
	var body_text = body.get_string_from_utf8()
	print("[AI_DEBUG] /generate response code:", response_code)

	if response_code != 200:
		printerr("[AI_ERROR] Enqueue failed: ", body_text)
		hide_loading()
		generation_failed.emit("HTTP error", "Code: " + str(response_code))
		return

	var parsed = JSON.parse_string(body_text)
	if parsed == null or not ("job_id" in parsed):
		printerr("[AI_ERROR] No job_id in response: ", body_text)
		hide_loading()
		generation_failed.emit("Missing job_id", body_text)
		return

	current_job_id  = parsed["job_id"]
	var position    = parsed.get("position", 1)
	print("[AI_DEBUG] Job enqueued — id=", current_job_id, "  position=", position)

	_update_loading_message(position, "queued")

	# Start polling
	poll_timer.start()


# ════════════════════════════════════════════════════════════════════════════
#  POLLING  — Step 2: ask the server for the result every POLL_INTERVAL s
# ════════════════════════════════════════════════════════════════════════════
func _on_poll_tick():
	if current_job_id == "":
		poll_timer.stop()
		return

	# Reuse the node if the previous request already finished
	if http_poll == null or not is_instance_valid(http_poll):
		http_poll = HTTPRequest.new()
		add_child(http_poll)
		http_poll.request_completed.connect(_on_poll_response)

	var url = BASE_URL + "/result/" + current_job_id
	var err = http_poll.request(url, [], HTTPClient.METHOD_GET, "")
	if err != OK:
		push_error("[AI_ERROR] Poll request failed: " + str(err))


# ── Called each time a poll response arrives ────────────────────────────────
func _on_poll_response(result: int, response_code: int, _headers: Array, body: PackedByteArray):
	if response_code != 200:
		# Network hiccup — keep polling, don't abort
		printerr("[AI_WARN] Poll returned code ", response_code, " — retrying…")
		return

	var body_text = body.get_string_from_utf8()
	var parsed    = JSON.parse_string(body_text)
	if parsed == null:
		printerr("[AI_ERROR] Poll JSON parse failed: ", body_text)
		return

	var status: String = parsed.get("status", "unknown")
	print("[AI_DEBUG] Poll — status=", status)

	match status:
		"queued":
			var pos = parsed.get("position", 0)
			_update_loading_message(pos, "queued")

		"processing":
			_update_loading_message(0, "processing")

		"done":
			_finish_generation(parsed)

		"failed":
			_fail_generation(parsed.get("error", "Unknown error"))

		_:
			printerr("[AI_ERROR] Unknown job status: ", status)


# ════════════════════════════════════════════════════════════════════════════
#  HELPERS
# ════════════════════════════════════════════════════════════════════════════
func _update_loading_message(position: int, status: String):
	var msg: String
	match status:
		"queued":
			if position <= 1:
				msg = "You're next — almost ready…"
			else:
				msg = "In queue — position #" + str(position) + ". Please wait…"
		"processing":
			msg = "Generating your level… 🍄"
		_:
			msg = "Please wait…"

	if loading_instance != null and loading_instance.has_method("set_message"):
		loading_instance.set_message(msg)
	print("[AI_DEBUG] Loading msg → ", msg)


func _finish_generation(parsed: Dictionary):
	poll_timer.stop()
	current_job_id = ""

	if "grid_string" in parsed:
		var grid_string = parsed["grid_string"]
		var diff_label  = parsed.get("difficulty_label", "Level")
		print("[AI_DEBUG] SUCCESS — Level generated.")
		hide_loading()
		level_generated.emit(grid_string, diff_label)
	else:
		printerr("[AI_ERROR] done but missing grid_string")
		_fail_generation("Missing grid_string in done response")


func _fail_generation(error_msg: String):
	poll_timer.stop()
	current_job_id = ""
	printerr("[AI_ERROR] Generation failed: ", error_msg)
	hide_loading()
	generation_failed.emit("Generation failed", error_msg)
