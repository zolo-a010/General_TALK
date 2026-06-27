extends Node2D

@export var total_npcs_to_spawn: int = 5
@export var npc_scene: PackedScene
@export var spawn_boundary_min: Vector2 = Vector2(0, 0)
@export var spawn_boundary_max: Vector2 = Vector2(800, 800)

func _ready() -> void:
	# 1. Teleportation logic
	print("--- MAIN WORLD READY ---")
	print("Autoload Tag is: '", SceneManager.target_spawn_tag, "'")
	
	if SceneManager.target_spawn_tag != "":
		# We look for the Marker2D in this specific scene
		var spawn_point = find_child(SceneManager.target_spawn_tag, true, false)
		
		if spawn_point != null:
			print("SUCCESS: Found the Marker2D!")
			# Ensure your player node in main_world is actually named "Player"
			$Player.global_position = spawn_point.global_position
			print("SUCCESS: Player teleported!")
			SceneManager.target_spawn_tag = ""
		else:
			print("CRITICAL ERROR: Failed to find Marker2D named: ", SceneManager.target_spawn_tag)
	else:
		print("Notice: No tag was passed. Spawning at default location.")

	# 2. Your existing NPC spawning logic
	
