extends CanvasLayer

# --- UI Node References ---
@onready var background = $BackGround
@onready var chat_display: RichTextLabel = $BackGround/ChatDisplay
@onready var input_field: LineEdit = $BackGround/InputField
@onready var http_request: HTTPRequest = $HTTPRequest

# --- Network Configuration ---
var server_url: String = "http://127.0.0.1:8000/chat"
var is_waiting_for_response: bool = false

# --- Active NPC Metadata ---
var current_npc_name: String = ""
var current_npc_persona: String = ""
var current_npc_stolen_count: int = 0 # <--- ADD THIS

# =====================================================================
# MACHINE LEARNING: PLAYER BEHAVIOR TRACKING VARIABLES
# =====================================================================
# Change these values in your game loop later to watch the NPC's mood shift!
var test_times_talked: int = 0
var test_weapon_equipped: int = 0 # 0 = Disarmed/Sheathed, 1 = Weapon Out


func _ready() -> void:
	hide() # Keeps it invisible until an NPC calls it
	# Clean up UI styling on boot
	input_field.placeholder_text = "Type your message and press Enter..."
	
	# Connect the InputField's submit signal via code as a safety fallback
	if not input_field.text_submitted.is_connected(_on_text_submitted):
		input_field.text_submitted.connect(_on_text_submitted)
		
	# Connect the Network Request completion signal
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(_on_request_completed)
	
	# Listen for screen size changes to keep it glued to the edge
	get_tree().get_root().size_changed.connect(_on_window_resize)
	
	# Force the position immediately when the game starts
	_on_window_resize()
		
	# Start hidden (the NPC interaction script will call show_ui later)
	hide()
	
func _on_window_resize() -> void:
	# 1. Get the exact width and height of the camera's view
	var screen_size = get_viewport().get_visible_rect().size
	var box_width = 400 # Change this if you want the chat box wider or thinner!
	
	# 2. Force the background to fill the screen vertically
	background.size = Vector2(box_width, screen_size.y)
	
	# 3. Mathematically push it to the extreme right edge!
	background.position = Vector2(screen_size.x - box_width, 0)


# --- Public Interface called by your NPCs when interacting ---
# Add 'stolen_count' to the parameters with a default value of 0
func start_conversation(npc_name: String, npc_persona: String, stolen_count: int = 0) -> void:
	current_npc_name = npc_name
	current_npc_persona = npc_persona
	current_npc_stolen_count = stolen_count # Save the clone's personal grudge
	
	chat_display.clear()
	show()
	input_field.grab_focus()
	
	chat_display.append_text("[color=yellow]System: You are now speaking with " + current_npc_name + ".[/color]\n")


# --- Triggered when Player Presses Enter ---
func _on_text_submitted(user_text: String) -> void:
	user_text = user_text.strip_edges()
	
	# Safety checks
	if user_text.is_empty() or is_waiting_for_response:
		return
		
	# Display player's message in the sidebar chat window
	chat_display.append_text("\n[color=lightblue]You:[/color] " + user_text)
	input_field.text = ""
	
	# Lock down inputs to prevent double-submitting while loading
	is_waiting_for_response = true
	input_field.editable = false
	
	# Increment the conversation count feature for our ML pipeline
	test_times_talked += 1
	
	
	
	# 1. BUILD THE JSON PAYLOAD CONTAINING OUR 3 ML FEATURES
	var payload = {
		"message": user_text,
		"npc_name": current_npc_name,
		"npc_persona": current_npc_persona,
		"times_talked": test_times_talked,
		"items_stolen": current_npc_stolen_count,
		"weapon_equipped": test_weapon_equipped
	}
	
	# 2. CONVERT DICTIONARY TO STRING STREAM
	var json_string = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	
	# 3. SHOOT IT ACROSS THE NETWORK TO FLASK
	var err = http_request.request(server_url, headers, HTTPClient.METHOD_POST, json_string)
	if err != OK:
		chat_display.append_text("\n[color=red]System: Failed to initialize network connection.[/color]")
		_unlock_input()


# --- Triggered when Flask Server sends data back ---
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_unlock_input()
	
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		chat_display.append_text("\n[color=red]System: No response from server backend.[/color]")
		return
		
	# Parse incoming raw byte text stream
	var raw_response = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_err = json.parse(raw_response)
	
	if parse_err == OK:
		var response_data = json.get_data()
		if typeof(response_data) == TYPE_DICTIONARY and response_data.has("response"):
			var npc_reply = str(response_data["response"])
			
			# A. READ THE PREDICTED ML MOOD RESULT
			var current_mood = response_data.get("npc_state", "Friendly")
			
			# Display reply alongside calculated mood context
			chat_display.append_text("\n[color=lightgreen]" + current_npc_name + " (" + current_mood + "):[/color] " + npc_reply)
			
			# B. HOOK GAME ACTIONS DIRECTLY TO THE ML OUTPUT
			if current_mood == "Friendly":
				print("Game State Update: NPC is standing in a relaxed pose.")
			elif current_mood == "Suspicious":
				print("Game State Update: NPC is locking doors or guarding chests.")
			elif current_mood == "Aggressive":
				print("Game State Update: TRIGGER COMBAT! DRAW WEAPONS!")
				
			# Force chat window to automatically scroll down to newest lines
			var scrollbar = chat_display.get_v_scroll_bar()
			if scrollbar:
				scrollbar.call_deferred("set_value", scrollbar.max_value)
	else:
		chat_display.append_text("\n[color=red]System: Failed to parse server response payload.[/color]")


func _unlock_input() -> void:
	is_waiting_for_response = false
	input_field.editable = true
	input_field.grab_focus()
