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

# --- Timer & Sway Settings ---
@export var TOTAL_TIME = 60.0
var play_time_passed: float = 0.0
var sway_phase: float = 0.0

# --- Node References ---
@onready var visual_model = $Knight
@onready var anim_player = $Knight/AnimationPlayer
@onready var pivot = $CameraPivot 
@onready var camera = $CameraPivot/Camera3D 

# Ensure this path matches your UI location in the Scene Tree
@onready var timer_text_edit = get_node_or_null("../TextEdit")

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
		
		camera.position.z = clamp(camera.position.z, MIN_ZOOM, MAX_ZOOM)

	# 3. Unlock mouse (Press ESC)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	# --- 1. Gravity & Physics ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# --- 2. Movement Logic ---
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Rotate Knight to face movement direction
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

	# --- 3. Timer & Sway Logic ---
	play_time_passed += delta
	
	# Handle Camera Sway Intensity
	var current_amplitude = 2.0
	var current_speed = 1.5
	
	if play_time_passed > 30.0:
		var progress = clamp((play_time_passed - 30.0) / 30.0, 0.0, 1.0)
		current_amplitude = lerp(2.0, 15.0, progress)
		current_speed = lerp(1.5, 2.5, progress)
		
	sway_phase += delta * current_speed
	var sway_angle = sin(sway_phase) * current_amplitude

	camera.rotation_degrees.y = sway_angle
	camera.rotation_degrees.z = sway_angle

	# --- 4. UI Update & Game Over ---
	var time_left = max(TOTAL_TIME - play_time_passed, 0.0)
	
	if timer_text_edit:
		# int(ceil()) ensures the timer shows "1" until the last millisecond
		timer_text_edit.text = "Time Left: " + str(int(ceil(time_left))) + "s"
	
	if time_left <= 0.0:
		handle_game_over()

func handle_game_over():
	# Stops the game and makes the mouse visible
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if timer_text_edit:
		timer_text_edit.text = "MISSION FAILED"
	# Notify the new game mode manager so the shopping HUD shows the result
	var gm := get_node_or_null("/root/GameModeManager")
	if gm:
		gm.notify_time_up()
