extends Node2D

var npc_scene: PackedScene = preload("res://scenes/wandering_npc.tscn") 

# --- NEW VARIABLES ---
@export var current_city: String = "City_A"
@export var max_safe_npcs: int = 15 # How many NPCs exist when danger is 0%

@export var spawn_boundary_min: Vector2 = Vector2(-300, -100)
@export var spawn_boundary_max: Vector2 = Vector2(300, 200)

var random_names: Array[String] = ["Kaelen", "Lyra", "Garrick", "Vanya", "Rowan"]
var random_professions: Array[String] = [
	"a traveling merchant",
	"a retired palace guard",
	"a suspicious alchemist",
	"a secretive scholar"
]
var random_quirks: Array[String] = [
	"who speaks in short sentences.",
	"who is overly friendly.",
	"who speaks in riddles.",
	"who gets easily distracted."
]

func _ready() -> void:
	print("--- NEW SCENE LOADED ---")
	
	# 1. Handle Teleportation (Your existing code)
	if SceneManager.target_spawn_tag != "":
		var spawn_point = find_child(SceneManager.target_spawn_tag, true, false)
		if spawn_point != null:
			$Player.global_position = spawn_point.global_position
			SceneManager.target_spawn_tag = ""
			
	# --- 2. DYNAMIC ML SPAWNING LOGIC ---
	# Ask the global DangerManager what the ML predicted for this specific city
	var current_danger: float = DangerManager.city_danger_levels[current_city]
	
	# Calculate the inverse multiplier
	# Example: If danger is 20%, multiplier is 0.8. (15 * 0.8 = 12 NPCs)
	# Example: If danger is 90%, multiplier is 0.1. (15 * 0.1 = 1.5 NPCs -> rounds to 2)
	var danger_multiplier: float = 1.0 - (current_danger / 100.0)
	
	# Calculate final count and use maxi() to ensure it never accidentally goes below 0
	var calculated_npcs: int = maxi(0, round(max_safe_npcs * danger_multiplier))
	
	print("🚨 ML Data -> City: ", current_city, " | Danger: ", current_danger, "%")
	print("🚶 Spawning ", calculated_npcs, " NPCs in the streets.")
	
	# 3. Spawn them!
	
