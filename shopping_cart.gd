extends RigidBody3D

@onready var hint = $InteractionHint
@onready var area = $InteractionArea

var _player_near: bool = false

func _ready():
	# Configure physical parameters for the shopping cart
	linear_damp = 0.2
	angular_damp = 1.0
	
	# Only allow the specific node named "shopping-cart" to be pushed
	# Any other instances (shopping-cart2, etc.) stay frozen and silent
	if name == "shopping-cart":
		freeze = false
		if is_instance_valid(area):
			area.body_entered.connect(_on_body_entered)
			area.body_exited.connect(_on_body_exited)
	else:
		# Remove interaction elements from decorative carts
		freeze = true
		if is_instance_valid(hint): hint.queue_free()
		if is_instance_valid(area): area.queue_free()
	
	# Initial state
	if is_instance_valid(hint):
		hint.visible = false

func _process(_delta: float):
	if is_instance_valid(hint):
		# Only show hint if player is near AND NOT currently pushing
		if _player_near and not Input.is_key_pressed(KEY_P):
			hint.visible = true
		else:
			hint.visible = false

func _on_body_entered(body: Node3D):
	if body is CharacterBody3D:
		_player_near = true

func _on_body_exited(body: Node3D):
	if body is CharacterBody3D:
		_player_near = false
