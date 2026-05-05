@tool
extends Node

@export var GEMINI_API_KEY: String = ""
@export_multiline var system_prompt := ""
@export var Enabled : bool = false

var text := ""
var http_client := HTTPClient.new()
var is_streaming := false
var headers_received := false
var response_buffer := ""
var last_status := -1

func _ready():
	if not Enabled: return
	if GEMINI_API_KEY.is_empty():
		push_error("Gemini API key not set!")
		return
	http_client.close()
	set_process(true)
	call_gemini_stream()

func _process(_delta):
	# keep polling while streaming
	if not is_streaming:
		return

	http_client.poll()
	var status = http_client.get_status()
	if status != last_status:
		# This line is removed to avoid printing status updates:
		# print("HTTPClient status -> ", status)
		last_status = status

	match status:
		HTTPClient.STATUS_BODY:
			if not headers_received:
				headers_received = true
				var code = http_client.get_response_code()
				print("== HEADERS RECEIVED == Response code:", code)
				# Print response headers for diagnostics
				if http_client.has_method("get_response_headers"):
					var rh = http_client.get_response_headers()
					print("Response headers:\n", rh)
				if code != 200:
					printerr("Gemini API returned non-200:", code)
					var err_chunk = http_client.read_response_body_chunk()
					if err_chunk.size() > 0:
						printerr("Error chunk:\n", err_chunk.get_string_from_utf8())
					stop_stream()
					return

			# read all available chunks
			while true:
				var chunk = http_client.read_response_body_chunk()
				if chunk.size() <= 0:
					break
				var raw = chunk.get_string_from_utf8()
				# This is the line to remove so you no longer see the raw data:
				# print("--- raw chunk (truncated) ---\n", raw.substr(0, 300))
				response_buffer += raw
				_process_stream_buffer()

		HTTPClient.STATUS_DISCONNECTED:
			print("STATUS_DISCONNECTED")
			_process_stream_buffer()
			stop_stream()

		HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_TLS_HANDSHAKE_ERROR:
			printerr("Stream disconnected with an error. Status: ", status)
			stop_stream()

func call_gemini_stream():
	stop_stream()
	text = ""
	response_buffer = ""
	headers_received = false
	last_status = -1

	var host = "generativelanguage.googleapis.com"
	# model you said works for you
	var model = "gemini-2.5-pro"
	var url_path = "/v1beta/models/" + model + ":streamGenerateContent?alt=sse"

	var body = {
		"contents": [
			{
				"role": "user",
				"parts": [{"text": "Tell me a short, fun fact about the Godot Engine."}]
			}
		],
		"generationConfig": {
			"maxOutputTokens": 512,
			"temperature": 0.7
		}
	}
	if not system_prompt.is_empty():
		body["system_instruction"] = {"parts": [{"text": system_prompt}]}

	var json_body = JSON.stringify(body)
	var body_bytes = json_body.to_utf8_buffer()
	print("Connecting to Gemini...")

	var err = http_client.connect_to_host(host, 443, TLSOptions.client())
	if err != OK:
		push_error("Failed to connect: " + str(err))
		return

	# wait for connected
	while http_client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		http_client.poll()
		await get_tree().process_frame

	if http_client.get_status() != HTTPClient.STATUS_CONNECTED:
		push_error("Failed to connect to Gemini. Status: " + str(http_client.get_status()))
		return

	# NOTE: include X-Goog-Api-Key header — sometimes required
	var headers = [
		"Host: " + host,
		"Content-Type: application/json",
		"Accept: text/event-stream",
		"Cache-Control: no-cache",
		"Connection: keep-alive",
		"Content-Length: " + str(body_bytes.size()),
		"X-Goog-Api-Key: " + GEMINI_API_KEY
	]

	# request_raw sends the provided bytes directly
	err = http_client.request_raw(HTTPClient.METHOD_POST, url_path + "&key=" + GEMINI_API_KEY, headers, body_bytes)
	if err != OK:
		push_error("Request failed: " + str(err))
		return

	is_streaming = true
	print("\n=== STREAM STARTED ===\n(Waiting for response...)\n")

func _process_stream_buffer():
	# SSE events are separated by "\n\n". We loop while there's an event available.
	while true:
		var event_end_pos = response_buffer.find("\n\n")
		if event_end_pos == -1:
			break
		var event_str = response_buffer.substr(0, event_end_pos)
		response_buffer = response_buffer.substr(event_end_pos + 2)

		# Each event may have multiple lines. Parse each.
		for line in event_str.split("\n"):
			line = line.strip_edges()
			if line == "" or line.begins_with(":"):
				# heartbeat or comment
				continue
			var json_str
			# SSE data lines usually start with "data: "
			if line.begins_with("data: "):
				json_str = line.substr(6).strip_edges()
			else:
				# tolerant parsing: if line contains JSON braces, extract substring
				json_str = ""
				var start_i = line.find("{")
				var end_i = line.rfind("}")
				if start_i != -1 and end_i != -1 and end_i > start_i:
					json_str = line.substr(start_i, end_i - start_i + 1).strip_edges()
				else:
					# not a JSON payload — skip
					continue

			if json_str == "" or json_str == "[DONE]":
				continue

			var parsed = JSON.parse_string(json_str)
			if parsed == null:
				printerr("Failed to parse JSON: ", json_str.substr(0, 200))
				continue

			var parsed_obj = parsed
			# errors
			if parsed_obj.has("error"):
				printerr("Received error from API: ", parsed_obj["error"])
				stop_stream()
				return

			if parsed_obj.has("candidates"):
				var candidates = parsed_obj.get("candidates", [])
				if not candidates.is_empty():
					var content = candidates[0].get("content", {})
					var parts = content.get("parts", [])
					if not parts.is_empty():
						var delta_text = parts[0].get("text", "")
						if delta_text != "":
							text += delta_text
							print(delta_text, "")

func stop_stream():
	if is_streaming:
		print("\n=== STREAM ENDED ===\n")
	is_streaming = false
	headers_received = false
	response_buffer = ""
	http_client.close()
