extends Node

# ──────────────────────────────────────────────────────────
#  GameItemSpawner
#  Scans the market map at runtime locating tables and shelves.
#  Dynamically instantiates CollectibleItem.tscn at random
#  flat surfaces near them avoiding static collision issues.
# ──────────────────────────────────────────────────────────

func _ready() -> void:
	# Hide the statically hand-placed milk from the editor to avoid confusion
	var static_milk = get_node_or_null("../FLOOR/milk")
	if static_milk:
		static_milk.queue_free()

	# Give the scene a frame to initialize transformations
	await get_tree().process_frame
	
	_wrap_static_table_items()
	
	var spawn_points: Array[Vector3] = []
	_generate_safe_aisle_points(spawn_points)
	
	if spawn_points.is_empty():
		push_error("GameItemSpawner: Could not anchor aisles!")
		for i in range(15):
			spawn_points.append(Vector3(randf_range(-4, 4), 1.0, randf_range(-4, 4)))
		
	# Randomize locations for unpredictability
	spawn_points.shuffle()
	
	# Fetch generated shopping list from Singleton
	var items_to_spawn = []
	var gm: Node = get_node_or_null("/root/GameModeManager")
	if gm and "shopping_list" in gm:
		var s_list = gm.shopping_list
		for key in s_list:
			for _i in range(s_list[key]["required"]):
				items_to_spawn.append({
					"id": key,
					"label": s_list[key]["label"]
				})
				
	var collectible_scene = preload("res://CollectibleItem.tscn")
	
	for i in range(items_to_spawn.size()):
		var def = items_to_spawn[i]
		
		# Wrap around array index securely incase there's very little furniture 
		var anchor = spawn_points[i % spawn_points.size()]
		
		# Add a subtle positional jitter to avoid mathematically perfect stacking
		var pt = Vector3(
			anchor.x + randf_range(-0.4, 0.4),
			anchor.y,
			anchor.z + randf_range(-0.4, 0.4)
		)
		
		var inst = collectible_scene.instantiate()
		inst.item_id = def["id"]
		inst.item_display_name = def["label"]
		inst.global_position = pt
		
		# Attach to map safely
		get_parent().add_child.call_deferred(inst)

# ── Static Extraction Routine ────────────────────────────
func _wrap_static_table_items() -> void:
	var item_root = get_node_or_null("../Assets/Item")
	if not item_root: return
	
	var pans = []
	var pots = []
	var towels = []
	
	for child in item_root.get_children():
		if child is Node3D:
			var cname = child.name.to_lower()
			if "pan_" in cname: pans.append(child)
			elif "pot_b" in cname: pots.append(child)
			elif "papertowel" in cname: towels.append(child)
			
	pans.shuffle()
	pots.shuffle()
	towels.shuffle()
	
	_wrap_subset(pans, "pan", "🍳 Pan", 3)
	_wrap_subset(pots, "pot", "🍲 Pot", 3)
	_wrap_subset(towels, "papertowel", "🧻 Paper Towel", 4)

func _wrap_subset(nodes: Array, id: String, labeltxt: String, count: int) -> void:
	var collectible_scene = preload("res://CollectibleItem.tscn")
	var limit = min(count, nodes.size())
	for i in range(limit):
		var target = nodes[i]
		var inst = collectible_scene.instantiate()
		inst.item_id = id
		inst.item_display_name = labeltxt
		
		# Configure to steal/wrap the specific mapped mesh
		inst.external_mesh_to_steal = target
		inst.global_position = target.global_position
		
		# Insert explicitly securely into tree architecture 
		target.get_parent().add_child.call_deferred(inst)

# ── Safe Floor Aisle Drops ───────────────────────────────
func _generate_safe_aisle_points(arr: Array[Vector3]) -> void:
	var npcs = get_node_or_null("../GameNPCs")
	if not npcs: return
	
	# The GameNPCs act strictly as pathfinding constraints located beautifully inside clear aisles!
	var anchors = []
	for npc in npcs.get_children():
		if npc is Node3D:
			anchors.append(npc.global_position)
			
	for anchor in anchors:
		# Scatter dynamically 1.2m spacing off nodes
		var pts = [
			Vector3(anchor.x, 0.4, anchor.z),
			Vector3(anchor.x + 1.2, 0.4, anchor.z + 1.2),
			Vector3(anchor.x - 1.2, 0.4, anchor.z - 1.2),
			Vector3(anchor.x + 1.2, 0.4, anchor.z - 1.2),
			Vector3(anchor.x - 1.2, 0.4, anchor.z + 1.2)
		]
		
		# Safely boundary clamp each calculated spot
		for pt in pts:
			pt.x = clamp(pt.x, -31.0, -5.0)
			pt.z = clamp(pt.z, -43.0, -6.0)
			arr.append(pt)
