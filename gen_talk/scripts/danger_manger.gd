extends Node

@onready var http_request = $HTTPRequest
@onready var poll_timer = $Timer

@export var citizen_scene: PackedScene
@export var max_citizens: int = 10
@export var spawn_folder: Node2D
@export var player_camera: Camera2D

var city_danger_levels: Dictionary = {"City_A": 0.0, "City_B": 0.0}
var is_balancing_census: bool = false

func _ready() -> void:
	http_request.request_completed.connect(_on_request_completed)
	poll_timer.wait_time = 5.0
	poll_timer.autostart = true
	poll_timer.timeout.connect(poll_server)
	poll_timer.start()

func poll_server() -> void:
	var url = "http://127.0.0.1:5000/get_danger" 
	var live_bat_count = get_tree().get_nodes_in_group("enemies").size()
	
	var payload = {
		"city": "City_A",
		"damage": 0, 
		"enemies": live_bat_count,
		"structures_destroyed": 0
	}
	
	var json_string = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	http_request.request(url, headers, HTTPClient.METHOD_POST, json_string)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		var raw_danger: float = float(response["danger_percent"])
		var danger_ratio: float = raw_danger / 100.0 if raw_danger > 1.0 else raw_danger
		
		city_danger_levels[response["city"]] = danger_ratio
		
		if response["city"] == "City_A":
			_adjust_citizen_population(danger_ratio)

func _adjust_citizen_population(danger: float) -> void:
	if is_balancing_census or not is_instance_valid(spawn_folder):
		return
		
	is_balancing_census = true 
		
	var ideal_citizen_count: int = round(max_citizens * (1.0 - danger))
	var active_citizens = get_tree().get_nodes_in_group("npcs")
	var headcount_difference = ideal_citizen_count - active_citizens.size()
	
	if headcount_difference > 0:
		for i in range(headcount_difference):
			var random_delay = randf_range(0.1, 4.0)
			_schedule_spawn(random_delay)
			
	elif headcount_difference < 0:
		var excess_to_remove = abs(headcount_difference)
		for i in range(excess_to_remove):
			var victim = active_citizens[active_citizens.size() - 1 - i]
			_fade_and_destroy(victim)

	await get_tree().process_frame 
	is_balancing_census = false

func _schedule_spawn(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(spawn_folder): 
		return
		
	var markers = spawn_folder.get_children().filter(func(c): return c is Marker2D)
	
	# GTA Rule: Only use markers that are truly off-screen
	var target_marker = null
	if is_instance_valid(player_camera):
		var cam_rect = player_camera.get_viewport_rect()
		var zoom = player_camera.zoom
		var view_size = cam_rect.size / zoom
		cam_rect.position = player_camera.get_screen_center_position() - (view_size / 2.0)
		cam_rect.size = view_size
		cam_rect = cam_rect.grow(200) # The Buffer
		
		var offscreen = markers.filter(func(m): return not cam_rect.has_point(m.global_position))
		if not offscreen.is_empty():
			target_marker = offscreen.pick_random()
	else:
		# If no camera, just pick any marker
		target_marker = markers.pick_random() if not markers.is_empty() else null
	
	# If we couldn't find an off-screen spot, just stop. Do NOT spawn on-screen.
	if not target_marker:
		return
	
	# Instantiate and setup
	var new_person = citizen_scene.instantiate()
	spawn_folder.add_child(new_person)
	new_person.global_position = target_marker.global_position
	new_person.add_to_group("npcs")
	
	# Ghost Fade
	new_person.modulate.a = 0.0
	var tween = get_tree().create_tween()
	tween.tween_property(new_person, "modulate:a", 1.0, 1.5)

func _fade_and_destroy(victim: Node) -> void:
	if not is_instance_valid(victim):
		return
	victim.remove_from_group("npcs")
	var tween = get_tree().create_tween()
	tween.tween_property(victim, "modulate:a", 0.0, 1.5)
	tween.tween_callback(victim.queue_free)
