extends CharacterBody2D

@export var speed: float = 75.0
@export var attack_range: float = 30.0
@export var tree_perch_offset: Vector2 = Vector2(0, -60) 

enum State { SLEEP, CHASE, ATTACK, SEARCH, RETURN }
var current_state: State = State.SLEEP

var home_pos: Vector2
var player: Node2D = null
var stuck_timer: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var search_timer: Timer = $SearchTimer
@onready var detection_zone: Area2D = $DetectionZone
@onready var main_collider: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	home_pos = global_position
	set_state(State.SLEEP)


func set_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.SLEEP:
			sprite.play("BAT_SLEEP")
			velocity = Vector2.ZERO
			main_collider.set_deferred("disabled", true)
			
		State.CHASE:
			sprite.play("BAT_RUN")
			main_collider.set_deferred("disabled", false)
			
		State.ATTACK:
			velocity = Vector2.ZERO
			main_collider.set_deferred("disabled", false)
			if randf() < 0.5:
				sprite.play("BAT_ATTACK_1")
			else:
				sprite.play("BAT_ATTACK_2")
				
		State.SEARCH:
			velocity = Vector2.ZERO
			sprite.play("BAT_IDLE")
			main_collider.set_deferred("disabled", false)
			search_timer.start(2.5) 
			
		State.RETURN:
			sprite.play("BAT_RUN")
			stuck_timer = 0.0 
			main_collider.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	match current_state:
		State.SLEEP:
			# RULE 2 (Upgraded): Asleep, but player is standing in the bubble. 
			# Do not wake up unless there is open air between us!
			if is_instance_valid(player) and detection_zone.overlaps_body(player):
				if _can_see_player():
					set_state(State.CHASE)
			
		State.CHASE:
			if is_instance_valid(player):
				# RULE 4 (Upgraded): They ducked behind a house/tree! 
				if not _can_see_player():
					set_state(State.SEARCH)
					return
					
				# RULE 3: When near player start attacking
				if global_position.distance_to(player.global_position) <= attack_range:
					set_state(State.ATTACK)
					return
					
				velocity = global_position.direction_to(player.global_position) * speed
			else:
				set_state(State.SEARCH)
				
		State.ATTACK:
			pass 
				
		State.SEARCH:
			if randf() < 0.05:
				velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * (speed * 0.4)
				
		State.RETURN:
			# RULE 5 (Upgraded): Flying home. Radar detects player. 
			# Ignore them completely unless our laser eye passes past the tree branches!
			if is_instance_valid(player) and detection_zone.overlaps_body(player):
				if _can_see_player():
					set_state(State.CHASE)
					return
				
			if global_position.distance_to(home_pos) <= 15.0:
				global_position = home_pos
				set_state(State.SLEEP)
				return
				
			# RULE 6: Failsafe adoption
			stuck_timer += delta
			if stuck_timer >= 5.0:
				adopt_nearest_tree()
				return
				
			velocity = global_position.direction_to(home_pos) * speed

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

	move_and_slide()


# ====================================================================
# --- THE VISION GATEKEEPER (Prevents all infinite time loops) ---
# ====================================================================
# ====================================================================
# --- THE KERNEL RAY (Zero nodes required, impossible to desync) ---
# ====================================================================
func _can_see_player() -> bool:
	if not is_instance_valid(player):
		return false
		
	# 1. Tap directly into Godot's C++ physics master-server
	var space_state = get_world_2d().direct_space_state
	
	# 2. Forge a pure math vector from our exact center to the player's center
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self] # Tell the beam to phase through our own bat body
	
	# 3. Fire it instantly at the speed of light
	var result = space_state.intersect_ray(query)
	
	# 4. If the beam hit a solid object, was that object the Player?
	if result:
		return result.collider == player
		
	return false


func _on_search_timer_timeout() -> void:
	if current_state == State.SEARCH:
		set_state(State.RETURN)


func _on_detection_zone_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body
		# RULE 2: Check eyes before waking up
		if _can_see_player():
			set_state(State.CHASE)


func _on_detection_zone_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
		if current_state == State.CHASE or current_state == State.ATTACK:
			set_state(State.SEARCH)


func _on_animated_sprite_2d_animation_finished() -> void:
	if current_state == State.ATTACK:
		if is_instance_valid(player) and global_position.distance_to(player.global_position) <= attack_range:
			set_state(State.ATTACK) 
		else:
			set_state(State.CHASE)  


func adopt_nearest_tree() -> void:
	var trees = get_tree().get_nodes_in_group("trees")
	var closest_tree: Node2D = null
	var min_dist: float = INF
	
	for t in trees:
		var d = global_position.distance_to(t.global_position)
		if d < min_dist:
			min_dist = d
			closest_tree = t
			
	if closest_tree:
		home_pos = closest_tree.global_position + tree_perch_offset
		stuck_timer = 0.0
