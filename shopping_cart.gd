extends CharacterBody3D

@export_group("Pushing Settings")
@export var follow_distance: float = 2.5 # Increased from 2.0 to prevent clipping into player
@export var follow_speed: float = 8.0   # Slightly slower for better stability
@export var interaction_range: float = 3.5

var player: CharacterBody3D = null
var initial_scale: Vector3 = Vector3.ONE
var is_pushed: bool = false
var has_interacted: bool = false

func _ready() -> void:
	add_to_group("carts")
	initial_scale = global_transform.basis.get_scale()
	_find_player()

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")


func _input(event: InputEvent) -> void:
	if not player:
		return
	
	# Check for P key press (Toggle logic)
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		if is_pushed:
			# Release the cart
			print("Released cart")
			is_pushed = false
			
			# Nudge the cart slightly forward so it doesn't overlap the player on release
			var forward = -global_transform.basis.z
			forward.y = 0
			forward = forward.normalized()
			global_position += forward * 0.5 
			
			# Stop all movement
			velocity = Vector3.ZERO
			if is_on_floor():
				velocity.y = -0.1
			
			# Remove collision exception so player can push the cart again
			remove_collision_exception_with(player)
			
		else:
			var dist = global_position.distance_to(player.global_position)
			if dist < interaction_range:
				# CHECK: Is this the CLOSEST cart to the player?
				var closest_cart = null
				var min_dist = 999.0
				for c in get_tree().get_nodes_in_group("carts"):
					var d = c.global_position.distance_to(player.global_position)
					if d < min_dist:
						min_dist = d
						closest_cart = c
				
				if closest_cart != self:
					return
				
				# ONE CART AT A TIME: Check if another cart is already being pushed
				var other_carts = get_tree().get_nodes_in_group("carts")
				for cart in other_carts:
					if cart != self and cart.get("is_pushed") == true:
						print("Already pushing another cart!")
						return
				
				# Successfully picked up the cart
				print("Started pushing " + name)
				is_pushed = true
				has_interacted = true
				add_collision_exception_with(player)

func _physics_process(delta: float) -> void:
	if not player:
		_find_player()
		return
	
	if is_pushed:
		# While being pushed: actively follow the player
		_handle_movement(delta)
	elif has_interacted:
		# After release: apply gravity to keep cart on floor
		if not is_on_floor():
			velocity.y += get_gravity().y * delta
		else:
			# Strong friction on the ground to stop sliding
			velocity.x = move_toward(velocity.x, 0, follow_speed * 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0, follow_speed * 4.0 * delta)
			velocity.y = 0.0  # Reset vertical velocity when on floor
			
			# If barely moving, stop completely
			if velocity.length() < 0.2:
				velocity = Vector3.ZERO
		
		# ALWAYS call move_and_slide to apply gravity and keep cart on floor
		move_and_slide()
	else:
		# Untouched cart: do nothing, stay static
		pass

func _handle_movement(delta: float) -> void:
	# Use player's basis for consistent forward direction
	var target_basis = player.global_transform.basis
	var forward_dir = -target_basis.z.normalized()
	
	# Position cart in front of the player
	var target_pos = player.global_position + (forward_dir * follow_distance)
	target_pos.y = player.global_position.y  # Keep at player height
	
	# Calculate error to the target position
	var distance_error = target_pos - global_position
	
	# Safety: if cart is extremely far away, teleport it back
	if distance_error.length() > 6.0:
		global_position = target_pos
		velocity = Vector3.ZERO
		return
	
	# Smooth velocity adjustment: cart has "weight" and takes time to accelerate/decelerate
	var desired_velocity = distance_error.normalized() * min(distance_error.length() * follow_speed, 10.0)
	velocity = velocity.move_toward(desired_velocity, 15.0 * delta)
	velocity = velocity.limit_length(10.0)
	
	move_and_slide()
	
	# Smooth rotation to avoid jitter
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var target_quat = target_basis.get_rotation_quaternion()
	var smooth_quat = current_quat.slerp(target_quat, 6.0 * delta)
	global_transform.basis = Basis(smooth_quat).scaled(initial_scale)
