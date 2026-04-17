extends CharacterBody3D # Changed from Node3D for collision support

@export_group("Settings")
@export var follow_distance: float = 1.8  # Closer feel
@export var follow_speed: float = 12.0     # Snappier movement
@export var interaction_range: float = 2.5

var player: CharacterBody3D = null
var is_pushed: bool = false
var has_interacted: bool = false
var initial_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	# Ensure the cart is in the group for easier interaction if needed
	add_to_group("carts")
	_find_player()
	initial_scale = global_transform.basis.get_scale()

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _input(event: InputEvent) -> void:
	# Use 'P' as a toggle switch
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		# If we are already pushing THIS cart, we want to release it
		if is_pushed:
			is_pushed = false
			print("Released cart")
			remove_collision_exception_with(player)
			return

		# If we are NOT pushing this cart, check if we can pick it up
		var dist = global_position.distance_to(player.global_position)
		if dist < interaction_range:
			# ONE CART AT A TIME CONSTRAINT
			# Check if the player is already pushing any other cart in the scene
			var other_carts = get_tree().get_nodes_in_group("carts")
			for cart in other_carts:
				if cart != self and cart.get("is_pushed") == true:
					print("Player is already pushing another cart!")
					return # Prevent picking up this one
			
			is_pushed = true
			has_interacted = true
			print("Attached to cart")
			# Disable collision between player and cart so they don't jitter
			add_collision_exception_with(player)

func _physics_process(delta: float) -> void:
	if not player:
		_find_player()
		return

	if is_pushed:
		_handle_movement(delta)
	elif has_interacted:
		# Apply gravity only after the player has moved the cart at least once
		if not is_on_floor():
			velocity += get_gravity() * delta
			move_and_slide()

func _handle_movement(delta: float) -> void:
	# 1. Determine Target Position (Always in front of player model)
	var player_visual = player.get_node_or_null("Knight")
	var target_basis = player_visual.global_transform.basis if player_visual else player.global_transform.basis
	
	# Calculate the front offset based on player rotation
	var forward_dir = -target_basis.z.normalized()
	var target_pos = player.global_position + (forward_dir * follow_distance)
	
	# Match player's Y height (crucial for ramps/uneven supermarket floors)
	target_pos.y = player.global_position.y 

	# 2. Smooth Movement using Velocity (Perfect for CharacterBody3D)
	# This ensures the cart stops when hitting a wall instead of phasing through
	var move_vec = (target_pos - global_position) * follow_speed
	velocity = move_vec
	move_and_slide()

	# 3. Smooth Rotation (Slerp)
	# Use the cached scale to prevent sizing issues
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var target_quat = target_basis.get_rotation_quaternion()
	var smooth_quat = current_quat.slerp(target_quat, follow_speed * delta)
	
	# Apply rotation and restore cached scale
	global_transform.basis = Basis(smooth_quat).scaled(initial_scale)
