extends CharacterBody3D

# --- Physical Constants ---
@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var TURN_SPEED = 12.0
@export var MOUSE_SENSITIVITY = 0.001

# --- Zoom Constants ---
@export var ZOOM_SPEED = 0.5
@export var MIN_ZOOM = 1.5
@export var MAX_ZOOM = 6.0

# --- Node References ---
@onready var visual_model = $Knight
@onready var anim_player = $Knight/AnimationPlayer
@onready var pivot = $CameraPivot 
@onready var camera = $CameraPivot/Camera3D # Ensure Camera3D is a child of CameraPivot

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# 1. Handle Mouse Movement (Look)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# 2. Handle Mouse Scroll (Zoom)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z -= ZOOM_SPEED
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z += ZOOM_SPEED
		
		# Prevent camera from going inside head or too far away
		camera.position.z = clamp(camera.position.z, MIN_ZOOM, MAX_ZOOM)

	# 3. Unlock mouse (Press ESC)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# Add Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get Input Vector (WASD)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Character rotation relative to view
		var target_angle = atan2(input_dir.x, input_dir.y)
		visual_model.rotation.y = lerp_angle(visual_model.rotation.y, target_angle, TURN_SPEED * delta)
		
		if anim_player.current_animation != "Rig_Medium_MovementBasic/Running_A":
			anim_player.play("Rig_Medium_MovementBasic/Running_A")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		if anim_player.current_animation != "Rig_Medium_MovementBasic/Jump_Idle":
			anim_player.play("Rig_Medium_MovementBasic/Jump_Idle")

	move_and_slide()
