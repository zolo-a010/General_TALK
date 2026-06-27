extends ProgressBar

# Initializes the health bar when the character spawns
func setup(max_hp: int) -> void:
	max_value = max_hp
	value = max_hp

# Call this function whenever the character takes damage
func update_health(new_hp: int) -> void:
	# Godot 4's built-in way to smoothly animate a value over time (0.2 seconds)
	var tween = create_tween()
	tween.tween_property(self, "value", new_hp, 0.2).set_trans(Tween.TRANS_SINE)
