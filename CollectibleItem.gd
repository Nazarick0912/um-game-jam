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

@onready var _mesh:   MeshInstance3D = $MeshInstance3D
@onready var _label:  Label3D        = $Label3D

var _collected: bool  = false
var _bob_time:  float = 0.0

# Starting Y so we can bob relative to spawn position
var _base_y: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("collectible_item")

	_base_y = global_position.y

	# Colour the sphere based on item type
	var mat := StandardMaterial3D.new()
	match item_id:
		"milk":
			mat.albedo_color        = Color(0.85, 0.95, 1.0)
			mat.emission_enabled    = true
			mat.emission            = Color(0.5, 0.7, 1.0)
			mat.emission_energy_multiplier = 1.2
		"box":
			mat.albedo_color        = Color(0.78, 0.55, 0.25)
			mat.emission_enabled    = true
			mat.emission            = Color(0.9, 0.65, 0.2)
			mat.emission_energy_multiplier = 0.8
		_:
			mat.albedo_color = Color(1, 1, 0)

	_mesh.material_override = mat
	_label.text = item_display_name

func _process(delta: float) -> void:
	if _collected:
		return
	# Gentle bobbing + slow spin
	_bob_time += delta
	global_position.y = _base_y + sin(_bob_time * 2.2) * 0.12
	rotation_degrees.y += delta * 60.0

func _on_body_entered(body: Node3D) -> void:
	if _collected:
		return
	# The Player is a CharacterBody3D – only one in scene, so type-check works
	if body is CharacterBody3D:
		_do_collect()

func _do_collect() -> void:
	_collected = true
	set_deferred("monitoring", false)

	# Notify game manager
	var gm := get_node_or_null("/root/GameModeManager")
	if gm:
		gm.collect_item(item_id)

	# Pop animation then free
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "global_position:y", global_position.y + 0.8, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ZERO, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free).set_delay(0.26)
