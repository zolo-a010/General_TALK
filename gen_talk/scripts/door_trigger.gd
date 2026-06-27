extends Area2D

# Expose these to the Inspector so every door can be different
@export var target_scene_path: String
@export var destination_spawn_tag: String

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		# Make sure we don't try to load an empty path
		if target_scene_path != "":
			SceneManager.change_scene(target_scene_path, destination_spawn_tag)
