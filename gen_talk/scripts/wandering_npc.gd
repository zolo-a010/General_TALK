extends CharacterBody2D

@export var npc_name: String = "Wanderer"
@export_multiline var npc_persona: String = "A traveler exploring the wild map."
@export var movement_speed: float = 50.0

var player_nearby: bool = false
var interacting: bool = false
var current_velocity_direction: Vector2 = Vector2.ZERO

# Keep track of the current direction string
var facing_direction: String = "DOWN"

var max_health: int = 100
var current_health: int = 100
var personal_items_stolen: int = 0

var speed: float = 50.0
var current_city: String = "City_A"
var safe_city_coords: Vector2 = Vector2(5000, -2000) # Somewhere far away


@onready var interaction_area: Area2D = $InteractionArea
@onready var wander_timer: Timer = $WanderTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar = $HealthBar # Make sure this matches your scene tree!

func _ready() -> void:
	# Hide the health bar the moment the NPC spawns into the world
	health_bar.hide()
	
	# ... (your other _ready code, like setting up max health)
	health_bar.setup(100)
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_left)
	wander_timer.timeout.connect(_on_timer_cycle_complete)
	_calculate_new_heading()

func _physics_process(_delta: float) -> void:
	var current_danger = DangerManager.city_danger_levels[current_city]
	
	if current_danger > 75.0:
		# Calculate direction to the safe city
		var direction = (safe_city_coords - global_position).normalized()
		
		# Run 3x as fast!
		velocity = direction * (speed * 3.0) 
		
		# Optional: Change sprite color to red so you can visually see them panic
		modulate = Color(1, 0, 0) 
	else:
		# Standard wandering logic goes here
		velocity = Vector2.ZERO # Replace with your normal walk code
		modulate = Color(1, 1, 1) # Return to normal color
	
	
	if interacting:
		velocity = Vector2.ZERO
	else:
		velocity = current_velocity_direction * movement_speed
		
	move_and_slide()
	_handle_4_way_animation()

func _handle_4_way_animation() -> void:
	# Case A: NPC is stopped or talking to the player
	if velocity.is_zero_approx():
		# Plays e.g., "DOWN_IDLE"
		animated_sprite.play(facing_direction + "_IDLE")
	
	# Case B: NPC is actively walking
	else:
		# Determine if movement is primarily horizontal or vertical
		if abs(velocity.x) > abs(velocity.y):
			facing_direction = "RIGHT" if velocity.x > 0 else "LEFT"
		else:
			facing_direction = "DOWN" if velocity.y > 0 else "UP"
			
		# Plays e.g., "RIGHT_WALK"
		animated_sprite.play(facing_direction + "_WALK")

func _on_timer_cycle_complete() -> void:
	if not interacting:
		_calculate_new_heading()

func _calculate_new_heading() -> void:
	if randf() > 0.5:
		current_velocity_direction = Vector2.ZERO
	else:
		var random_radians: float = randf() * TAU
		current_velocity_direction = Vector2(cos(random_radians), sin(random_radians))
	
	wander_timer.start(randf_range(1.5, 4.0))

func _on_player_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = true
		health_bar.show()

func _on_player_left(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
		interacting = false
		health_bar.hide()
		
		# Call the exact Autoload name!
		NPC_Dialogue_UI.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_nearby:
			interacting = true
			_face_the_player()
			
			# Call the exact Autoload name!
			NPC_Dialogue_UI.show()
			NPC_Dialogue_UI.start_conversation(npc_name, npc_persona, personal_items_stolen)

func _face_the_player() -> void:
	var player_node = get_tree().get_first_node_in_group("Player")
	if not player_node:
		player_node = get_parent().get_node_or_null("Player")
		
	if player_node:
		var direction_to_player = (player_node.global_position - global_position).normalized()
		
		# Snaps facing target to one of your 4 specific directional paths
		if abs(direction_to_player.x) > abs(direction_to_player.y):
			facing_direction = "RIGHT" if direction_to_player.x > 0 else "LEFT"
		else:
			facing_direction = "DOWN" if direction_to_player.y > 0 else "UP"
			
		# Play the idle animation facing the player
		animated_sprite.play(facing_direction + "_IDLE")
		
# Add this method at the bottom of the script
func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
		
	print(npc_name, " took ", amount, " damage! Current HP: ", current_health)
	personal_items_stolen += 1
	print(npc_name, " was mugged! They have lost ", personal_items_stolen, " items to you.")
	
	# Pass the new value to the floating bar UI we created
	if health_bar:
		health_bar.update_health(current_health)
		
	# Force the health bar to show if they get hit from behind outside their normal vision circle
	health_bar.show()
	
	# Death check handling
	if current_health <= 0:
		_die()

func _die() -> void:
	print(npc_name, " has collapsed!")
	# You can play a death animation here before freeing the memory
	queue_free()
	
