extends Node2D

@export var current_city: String = "City_A"
@export var max_safe_npcs: int = 15

# Instead of one fixed scene, we use an Array so you can add 
# merchants, guards, and monsters in the future!
@export var possible_npc_scenes: Array[PackedScene]

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
	# Safety check: Did you forget to add NPC scenes in the Inspector?
	if possible_npc_scenes.is_empty():
		print("⚠️ Spawner Error in ", current_city, ": No NPC scenes assigned!")
		return
		
	_calculate_and_spawn()

func _calculate_and_spawn() -> void:
	var current_danger: float = DangerManager.city_danger_levels.get(current_city, 0.0)
	var danger_multiplier: float = 1.0 - (current_danger / 100.0)
	var calculated_npcs: int = maxi(0, round(max_safe_npcs * danger_multiplier))
	
	print("🚨 ", current_city, " Spawner | Danger: ", current_danger, "% | Spawning: ", calculated_npcs)
	
	randomize()
	for i in range(calculated_npcs):
		_generate_single_npc()

func _generate_single_npc() -> void:
	# Pick a completely random NPC type from the ones you assigned in the Inspector
	var chosen_scene: PackedScene = possible_npc_scenes.pick_random()
	var new_npc = chosen_scene.instantiate()
	
	# Set a random position
	var random_x: float = randf_range(spawn_boundary_min.x, spawn_boundary_max.x)
	var random_y: float = randf_range(spawn_boundary_min.y, spawn_boundary_max.y)
	new_npc.position = Vector2(random_x, random_y)
	
	# Future-Proofing Check: Ensure the chosen NPC actually has these variables 
	# before trying to set them (in case you spawn a Monster that doesn't have a "persona")
	if "npc_name" in new_npc:
		new_npc.npc_name = random_names.pick_random()
	if "npc_persona" in new_npc:
		new_npc.npc_persona = "You are " + random_professions.pick_random() + " " + random_quirks.pick_random()
	if "current_city" in new_npc:
		new_npc.current_city = current_city
		
	# Add the NPC as a child of the spawner
	add_child(new_npc)
