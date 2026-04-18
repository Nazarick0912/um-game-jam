extends Area3D

# ──────────────────────────────────────────────────────────
#  CollectibleItem – A floating, glowing pick-up item.
#  When the player walks into it the item is removed and
#  GameModeManager is notified.
# ──────────────────────────────────────────────────────────

## Must match a key in GameModeManager.shopping_list ("milk" or "box")
@export var item_id: String = "milk"
## Human-readable label shown above the item
@export var item_display_name: String = "Milk"

@onready var _label:  Label3D = $Label3D

var _collected: bool  = false
var _bob_time:  float = 0.0

# Starting Y so we can bob relative to spawn position
var _base_y: float = 0.0

# 3D Mesh asset paths
const ASSET_PATHS = {
	"milk": "res://Christmas Asset/KayKit_Holiday_Bits_1.0_FREE/Assets/gltf/milk.gltf",
	"cookie": "res://Christmas Asset/KayKit_Holiday_Bits_1.0_FREE/Assets/gltf/cookie.gltf",
	"mustard": "res://Kitchen Asset/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/mustard.gltf",
	"ketchup": "res://Kitchen Asset/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/ketchup.gltf",
	"jar": "res://Kitchen Asset/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/jar_A_medium.gltf",
	"pot": "res://Kitchen Asset/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/pot_A.gltf",
	"bowl": "res://Kitchen Asset/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/bowl.gltf",
	"knife": "res://Kitchen Asset/KayKit_Restaurant_Bits_1.0_FREE/Assets/gltf/knife.gltf",
	"box": "res://Mart Asset/Models/FBX format/shelf-boxes.fbx", # Generic fallback since individual boxes don't exist
	"bread": "res://Mart Asset/Models/FBX format/display-bread.fbx" # Fallback
}

var _model: Node3D = null

var skip_asset_load: bool = false
var external_mesh_to_steal: Node3D = null

var use_spawn_pos: bool = false
var spawn_global_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	# Force Global Scale of (1, 1, 1) and break away from parent scales
	top_level = true
	
	if use_spawn_pos:
		global_position = spawn_global_pos

	body_entered.connect(_on_body_entered)
	add_to_group("collectible_item")

	_base_y = global_position.y

	# Clean out the old sphere placeholder if it exists
	var old_mesh = get_node_or_null("MeshInstance3D")
	if old_mesh:
		old_mesh.queue_free()

	if external_mesh_to_steal:
		# Extract model gracefully from its map node parent and inject it into self
		external_mesh_to_steal.reparent(self, true)
		_model = external_mesh_to_steal
		
		# Extend the trigger radius drastically since physical table bodies block entry
		var col_shape = get_node_or_null("CollisionShape3D")
		if col_shape and col_shape.shape is SphereShape3D:
			var large_sphere = SphereShape3D.new()
			large_sphere.radius = 2.0
			col_shape.shape = large_sphere
			
	elif item_id in ASSET_PATHS:
		# Load dynamic 3D asset
		var scene_path = ASSET_PATHS[item_id]
		# Special handling: Since shelf-boxes.fbx and display-bread.fbx are massive shelves,
		# and not single items, we should safely fall back to something small if Box/Bread is used.
		# However, they might not be picked randomly anymore, but if they are, load a generic shape.
		var packed_scene = load(scene_path)
		if packed_scene:
			_model = packed_scene.instantiate()
			# Scale it up slightly for visibility and center it
			_model.scale = Vector3(1.5, 1.5, 1.5)
			# Lift it slightly to hover smoothly
			_model.position.y += 0.3
			add_child(_model)
	
	_label.text = item_display_name

func _process(delta: float) -> void:
	if _collected:
		return
	# Gentle bobbing + slow spin
	_bob_time += delta
	global_position.y = _base_y + sin(_bob_time * 2.2) * 0.12
	
	# Only spin dynamically generated assets models. Statically hand-placed meshes 
	# should retain their level designer's fixed orientation layout natively.
	if _model and external_mesh_to_steal == null:
		_model.rotation_degrees.y += delta * 60.0

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
		
	# The Player is a CharacterBody3D
	if body is CharacterBody3D:
		# 1. Check if the player is currently pushing a cart
		if body.attached_cart == null:
			# Player must be pushing a cart to shop
			return
			
		# 2. Check if the item is actually on the shopping list
		var gm := get_node_or_null("/root/GameModeManager")
		if gm:
			if not (item_id in gm.shopping_list):
				# Item not on the list
				return
			
			# Check if we still need more of this item
			var entry = gm.shopping_list[item_id]
			if entry["collected"] >= entry["required"]:
				# Already have enough of this item
				return
				
		# All conditions met, collect it!
		_do_collect()

func _do_collect() -> void:
	_collected = true
	set_deferred("monitoring", false)

	# Notify game manager
	var gm := get_node_or_null("/root/GameModeManager")
	if gm:
		gm.collect_item(item_id)

	# Pop animation removed: Disable physics and processing immediately to avoid singular transforms
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	queue_free()
