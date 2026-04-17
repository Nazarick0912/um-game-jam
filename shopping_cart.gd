extends CharacterBody3D

@export_group("Settings")
@export var follow_distance: float = 1.8
@export var follow_speed: float = 12.0
@export var interaction_range: float = 2.5

var player: CharacterBody3D = null
var is_pushed: bool = false
var initial_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	add_to_group("carts")
	initial_scale = global_transform.basis.get_scale()
	_find_player()

func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func _input(event: InputEvent) -> void:
	# Toggle P logic
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		if not player:
			_find_player()
		
		if not player:
			return

		var dist = global_position.distance_to(player.global_position)
		if dist < interaction_range:
			is_pushed = !is_pushed
			if is_pushed:
				print("Attached to cart")
				add_collision_exception_with(player)
			else:
				print("Released cart")
				remove_collision_exception_with(player)
				velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not player:
		_find_player()
		return

	if is_pushed:
		_handle_movement(delta)
	else:
		if not is_on_floor():
			velocity += get_gravity() * delta
			move_and_slide()

func _handle_movement(delta: float) -> void:
	# Use Knight model if it exists for the orientation
	var player_visual = player.get_node_or_null("Knight")
	var target_basis = player_visual.global_transform.basis if player_visual else player.global_transform.basis
	
	var forward_dir = -target_basis.z.normalized()
	var target_pos = player.global_position + (forward_dir * follow_distance)
	target_pos.y = player.global_position.y 

	# Direct movement
	var move_vec = (target_pos - global_position) * follow_speed
	velocity = move_vec
	move_and_slide()

	# Rotation with Scale preservation
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var target_quat = target_basis.get_rotation_quaternion()
	var smooth_quat = current_quat.slerp(target_quat, follow_speed * delta)
	
	global_transform.basis = Basis(smooth_quat).scaled(initial_scale)
