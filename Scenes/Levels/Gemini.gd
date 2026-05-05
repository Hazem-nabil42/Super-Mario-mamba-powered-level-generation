@icon("res://Assets/Icons/gemini2.svg")
@tool
extends Node

@export var Enabled : bool = false
@export var GEMINI_API_KEY: String = ""
@export_multiline var system_prompt := ""
@export_range(0, 2, 0.01) var Temperature := 1.0
@export_range(0, 1, 0.01) var Top_P : float = 1
var text : String = ""

signal generation

func _ready():
	if not Enabled: return
	if GEMINI_API_KEY == "":
		push_error("Gemini API key not set!")
		return
	call_gemini()

func call_gemini():
	var url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=" + GEMINI_API_KEY
	var headers = ["Content-Type: application/json"]

	var body = {
		"system_instruction": {
			"parts": [
				{"text": system_prompt}
			]
		},
		"contents": [
			{
				"role": "user",
				"parts": [
					{"text": "make a super big map so the player can play the game freely"}
				]
			}
		],
		"generationConfig": {
			"temperature": Temperature,
			"top_p": Top_P,
		}
	}

	var json = JSON.stringify(body)

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	var err = http.request(url, headers, HTTPClient.METHOD_POST, json)
	if err != OK:
		push_error("Request failed to start: " + str(err))

func _on_request_completed(result, response_code, headers, body):
	if response_code != 200:
		printerr("Gemini API Error:", response_code, "\n", body.get_string_from_utf8())
		return

	var parsed = JSON.parse_string(body.get_string_from_utf8())
	if parsed == null:
		printerr("Failed to parse JSON response.")
		return

	if "candidates" in parsed and parsed["candidates"].size() > 0:
		text = parsed["candidates"][0]["content"]["parts"][0]["text"]
		print("\n=== GEMINI OUTPUT ===\n")
		print(text)
		generation.emit(text)
	else:
		printerr("No text found in response.")
