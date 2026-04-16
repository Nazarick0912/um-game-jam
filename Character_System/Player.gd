extends RigidBody3D

# --- Physical Constants ---
const PUSH_FORCE = 2400.0  # The strength of the shove
const TURN_SPEED = 12.0    # How fast the Knight turns to face movement

# --- Node References ---
# Ensure these names match your Scene Tree exactly
@onready var visual_model = $Knight
@onready var anim_player = $Knight/AnimationPlayer

func _physics_process(delta):
	# 1. Capture Input Vector (W, A, S, D)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Convert to 3D Space (X and Z coordinates)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		# 3. Apply Physical Movement
		# This pushes the character in any direction, including diagonals
		apply_central_force(direction * PUSH_FORCE * delta)
		
		# 4. Handle Rotation
		var target_angle = atan2(direction.x, direction.z)
		
		# Smoothly interpolate the Y rotation toward the target angle
		visual_model.rotation.y = lerp_angle(visual_model.rotation.y, target_angle, TURN_SPEED * delta)
		
		# 5. Play Running Animation
		if anim_player.current_animation != "Rig_Medium_MovementBasic/Running_A":
			anim_player.play("Rig_Medium_MovementBasic/Running_A")
			
	else:
		# 6. Play Idle Animation
		if anim_player.current_animation != "Rig_Medium_MovementBasic/Jump_Idle":
			anim_player.play("Rig_Medium_MovementBasic/Jump_Idle")

	# 7. Safety: Prevent the character from tipping over on X or Z
	rotation.x = 0
	rotation.z = 0
