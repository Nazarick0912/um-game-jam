extends CharacterBody3D

# --- Physical Constants ---
@export var SPEED = 5.0
@export var SPRINT_SPEED = 8.5
@export var JUMP_VELOCITY = 6.5
@export var TURN_SPEED = 12.0
@export var MOUSE_SENSITIVITY = 0.001

# Double-tap to sprint variables
var last_press_times = {
	"ui_up": 0.0,
	"ui_down": 0.0,
	"ui_left": 0.0,
	"ui_right": 0.0
}
var is_sprinting = false
const DOUBLE_TAP_TIME = 0.3 # seconds

# --- Zoom Constants ---
@export var ZOOM_SPEED = 0.5
@export var MIN_ZOOM = 1.5
@export var MAX_ZOOM = 6.0

# --- Timer & Sway Settings ---
@export var TOTAL_TIME = 60.0
var play_time_passed: float = 0.0
var sway_phase: float = 0.0
var _was_moving: bool = false
var _hey_played: bool = false

var move_sfx_player: AudioStreamPlayer
var attached_cart: RigidBody3D = null
var _orig_parent: Node = null

# --- Node References ---
@onready var visual_model = $Knight
@onready var anim_player = $Knight/AnimationPlayer
@onready var pivot = $CameraPivot 
@onready var camera = $CameraPivot/Camera3D 
@onready var timer_text_edit = get_node_or_null("%TimerText")

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	move_sfx_player = AudioStreamPlayer.new()
	move_sfx_player.stream = load("res://Assets 1/KayKit_Prototype_Bits_1.1_FREE/Music/Hey watch it.ogg")
	add_child(move_sfx_player)

func _input(event):
	# 1. Look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		pivot.rotation.x = clamp(pivot.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# 2. Zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z -= ZOOM_SPEED
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z += ZOOM_SPEED
		camera.position.z = clamp(camera.position.z, MIN_ZOOM, MAX_ZOOM)

	# 3. Toggle Grab (P key)
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if attached_cart:
			_detach_cart()
		else:
			_try_grab_nearest_cart()

	# 4. Escape to unlock
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# 5. Handle Double-Tap Sprint Detection
	if event is InputEventKey and event.pressed and not event.is_echo():
		for action in ["ui_up", "ui_down", "ui_left", "ui_right"]:
			if event.is_action_pressed(action):
				var current_time = Time.get_ticks_msec() / 1000.0
				if (current_time - last_press_times[action]) < DOUBLE_TAP_TIME:
					is_sprinting = true
				last_press_times[action] = current_time

func _try_grab_nearest_cart():
	# Find the closest cart within 3 meters
	var carts = get_tree().get_nodes_in_group("shopping_cart")
	var closest_cart = null
	var min_dist = 3.5
	
	for cart in carts:
		if cart is RigidBody3D and "shopping-cart" in cart.name.to_lower():
			var dist = global_position.distance_to(cart.global_position)
			if dist < min_dist:
				min_dist = dist
				closest_cart = cart
	
	if closest_cart:
		_attach_cart(closest_cart)

func _attach_cart(cart: RigidBody3D):
	attached_cart = cart
	_orig_parent = attached_cart.get_parent()
	
	if attached_cart.has_method("set_sleeping"):
		attached_cart.sleeping = false
	attached_cart.freeze = true
	
	# Prevent the cart from pushing the player away (physics feedback loop)
	add_collision_exception_with(attached_cart)
	
	# Reparent to the Knight (so it rotates when the Knight turns)
	attached_cart.reparent(visual_model, true)
	
	# Position in front of the Knight
	# Note: Knight model forward might be different, adjusting Z and rotation
	attached_cart.position = Vector3(0, -0.3, 1.1) 
	attached_cart.rotation_degrees = Vector3(0, 0, 0)

func _detach_cart():
	if is_instance_valid(attached_cart):
		# Restore collisions
		remove_collision_exception_with(attached_cart)
		if is_instance_valid(_orig_parent):
			attached_cart.reparent(_orig_parent, true)
		else:
			attached_cart.reparent(get_parent(), true)
		attached_cart.freeze = false
	attached_cart = null

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if is_instance_valid(visual_model):
			var target_angle = atan2(input_dir.x, input_dir.y)
			visual_model.rotation.y = lerp_angle(visual_model.rotation.y, target_angle, TURN_SPEED * delta)
		if is_instance_valid(anim_player) and anim_player.current_animation != "Rig_Medium_MovementBasic/Running_A":
			anim_player.play("Rig_Medium_MovementBasic/Running_A")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		is_sprinting = false # Reset sprint when movement stops
		if is_instance_valid(anim_player) and anim_player.current_animation != "Rig_Medium_MovementBasic/Jump_Idle":
			anim_player.play("Rig_Medium_MovementBasic/Jump_Idle")

	move_and_slide()

	play_time_passed += delta
	var time_left = max(TOTAL_TIME - play_time_passed, 0.0)
	if timer_text_edit:
		timer_text_edit.text = "Time Left: " + str(int(ceil(time_left))) + "s"
	if time_left <= 0.0:
		handle_game_over()

func handle_game_over():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var gm := get_node_or_null("/root/GameModeManager")
	if gm:
		gm.notify_time_up()
