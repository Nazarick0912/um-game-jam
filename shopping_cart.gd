extends RigidBody3D

@onready var hint = $InteractionHint

var _player: Node3D = null

func _ready():
	add_to_group("shopping_cart")
	# Configure physical parameters
	linear_damp = 0.2
	angular_damp = 1.0
	
	# Only the main cart unfreezes
	if name == "shopping-cart":
		freeze = false
	else:
		freeze = true
		if is_instance_valid(hint): hint.queue_free()

	# Find the player in the scene
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		# Fallback detection
		_player = get_node_or_null("/root/main/Player")

func _physics_process(_delta: float):
	if freeze:
		return
		
	# Handle hint visibility based on distance
	if is_instance_valid(hint) and is_instance_valid(_player):
		var dist = global_position.distance_to(_player.global_position)
		# Only show if close AND not already holding it
		var is_grabbing = get_parent() == _player
		
		if dist < 3.0 and not is_grabbing and not Input.is_key_pressed(KEY_P):
			hint.visible = true
		else:
			hint.visible = false
