extends Node

# ──────────────────────────────────────────────────────────
#  GameItemSpawner
#  Wraps EXISTING market assets as pick-up items at runtime.
#  No new visual spheres are placed; the market's own models
#  become the collectibles — a floating label and glow light
#  appear above each one, and walking into it hides the model
#  and credits the item to the shopping list.
# ──────────────────────────────────────────────────────────

# ── Pickup definitions ────────────────────────────────────
# node_path   : relative from GameItemSpawner (sibling of FLOOR, Assets, …)
# item_id     : must match a key in GameModeManager.shopping_list
# label       : text shown above the item
# radius      : world-space pick-up sphere radius
const ITEM_DEFS: Array = [
	# ── Milk ────────────────────────────────────────────
	{
		"node_path": "../FLOOR/milk",
		"item_id":   "milk",
		"label":     "🥛 Milk",
		"radius":    1.5,
	},
	# ── Bread / Food aisle ───────────────────────────────
	{
		"node_path": "../Assets/Market Assets/display-bread",
		"item_id":   "bread",
		"label":     "🍞 Bread",
		"radius":    2.5,
	},
	# ── Boxes (shelf-boxes are literally stacked boxes) ──
	{
		"node_path": "../Assets/Market Assets/shelf-boxes",
		"item_id":   "box",
		"label":     "📦 Box",
		"radius":    2.5,
	},
	{
		"node_path": "../Assets/Market Assets/shelf-boxes2",
		"item_id":   "box",
		"label":     "📦 Box",
		"radius":    2.5,
	},
	{
		"node_path": "../Assets/Market Assets/shelf-boxes3",
		"item_id":   "box",
		"label":     "📦 Box",
		"radius":    2.5,
	},
]

func _ready() -> void:
	# Wait one frame so every node has its final global transform
	await get_tree().process_frame
	for def in ITEM_DEFS:
		var target: Node3D = get_node_or_null(def["node_path"]) as Node3D
		if target:
			_create_pickup_zone(target, def["item_id"], def["label"], def["radius"])
		else:
			push_warning("GameItemSpawner: node not found → " + str(def["node_path"]))

# ── Create an invisible Area3D at the item's world position ─
func _create_pickup_zone(
		target:    Node3D,
		item_id:   String,
		label_txt: String,
		radius:    float) -> void:

	var area := Area3D.new()

	# Sphere detection
	var col  := CollisionShape3D.new()
	var sph  := SphereShape3D.new()
	sph.radius  = radius
	col.shape   = sph
	area.add_child(col)

	# Floating label above the item
	var lbl := Label3D.new()
	lbl.text          = label_txt
	lbl.font_size     = 80
	lbl.billboard     = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.no_depth_test = true
	lbl.modulate      = Color(1.0, 0.95, 0.25)
	lbl.outline_size  = 8
	lbl.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	lbl.position      = Vector3(0.0, 2.5, 0.0)
	area.add_child(lbl)

	# Soft glow to make pick-up visible in the market
	var glow := OmniLight3D.new()
	glow.light_color  = Color(1.0, 0.9, 0.35)
	glow.light_energy = 1.5
	glow.omni_range   = 4.0
	glow.position     = Vector3(0.0, 0.8, 0.0)
	area.add_child(glow)

	# Add to scene root (so transforms are in world space)
	get_parent().add_child(area)
	area.global_position = target.global_position

	# Track per-item collected state (using a dictionary so it can be modified inside the lambda)
	var state := {"done": false}

	area.body_entered.connect(func(body: Node3D) -> void:
		if state["done"] or not (body is CharacterBody3D):
			return
		state["done"] = true
		area.set_deferred("monitoring", false)

		# Hide the actual market asset
		target.hide()

		# Tell the game manager
		var gm: Node = get_node_or_null("/root/GameModeManager")
		if gm:
			gm.collect_item(item_id)

		# Small pop animation then remove the zone
		var tw := area.create_tween()
		tw.set_parallel(true)
		tw.tween_property(area, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN)
		tw.tween_callback(area.queue_free).set_delay(0.31)
	)
