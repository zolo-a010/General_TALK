extends CanvasLayer

@onready var color_rect = $ColorRect
@onready var animation_player = $AnimationPlayer

# This holds the name of the marker we want to spawn at
var target_spawn_tag: String = "" 

func change_scene(target_path: String, spawn_tag: String) -> void:
	target_spawn_tag = spawn_tag # Save the tag for the new scene
	
	animation_player.play("fade_to_black")
	await animation_player.animation_finished
	
	get_tree().change_scene_to_file(target_path)
	
	animation_player.play("fade_to_normal")
