extends CharacterBody2D

@export var speed: float = 150.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var hitbox_shape: CollisionShape2D = $SwordHitbox/CollisionShape2D

var facing_direction: String = "DOWN" 
var is_attacking: bool = false 
var items_stolen: int = 0
func _ready() -> void:
	# Ensure the weapon hitbox is safely turned off on spawn
	hitbox_shape.disabled = true
	
	# Connect the hitbox signal to detect when it overlaps an enemy body
	sword_hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return 

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir != Vector2.ZERO:
		velocity = input_dir * speed
		_update_facing_direction(input_dir)
		animated_sprite.play("RUN_" + facing_direction)
	else:
		velocity = Vector2.ZERO
		animated_sprite.play("IDLE_" + facing_direction)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if is_attacking:
		return

	if event.is_action_pressed("attack_1"): 
		_perform_attack("ATTACK_1_")
	elif event.is_action_pressed("attack_2"):
		_perform_attack("ATTACK_2_")

func _update_facing_direction(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing_direction = "RIGHT" if dir.x > 0 else "LEFT"
	else:
		facing_direction = "DOWN" if dir.y > 0 else "UP"

# --- Melee Hitbox Attack Sequencing ---
func _perform_attack(attack_prefix: String) -> void:
	is_attacking = true
	velocity = Vector2.ZERO 
	
	# 1. Dynamically position the hitbox directly in front of where the player faces
	match facing_direction:
		"UP":
			sword_hitbox.position = Vector2(0, -24)
		"DOWN":
			sword_hitbox.position = Vector2(0, 24)
		"LEFT":
			sword_hitbox.position = Vector2(-24, 0)
		"RIGHT":
			sword_hitbox.position = Vector2(24, 0)
			
	# 2. Trigger the swing animation
	animated_sprite.play(attack_prefix + facing_direction)
	
	# 3. Wait a fraction of a second for the "sweet spot" frame where the sword hits
	await get_tree().create_timer(0.15).timeout
	
	# 4. Turn the invisible hitbox ON briefly
	hitbox_shape.disabled = false
	
	# 5. Keep it open for a tiny window (0.1 seconds) to capture collisions
	await get_tree().create_timer(0.1).timeout
	
	# 6. Shut it off immediately so it doesn't hit twice
	hitbox_shape.disabled = true
	
	# 7. Wait for the rest of the visual swing animation to finish tracking out
	if animated_sprite.is_playing():
		await animated_sprite.animation_finished
		
	is_attacking = false

# --- Signal Processing: What happens when the hitbox touches something ---
func _on_hitbox_body_entered(body: Node2D) -> void:
	
	print("SWORD TOUCHED: ", body.name)
	# Avoid hitting yourself
	if body == self:
		return
		
	# Check if the target body has a damage function ready to go
	if body.has_method("take_damage"):
		print("Hit landed on: ", body.name)
		body.take_damage(5) # Pass your desired weapon damage value here
		
