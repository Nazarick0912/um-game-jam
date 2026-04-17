extends Node

# ──────────────────────────────────────────────────────────
#  GameItemSpawner
#  Generates dynamic collectibles and targets ambient map 
#  geometries (like tables, pots, and freezers) directly.
# ──────────────────────────────────────────────────────────

func _ready() -> void:
	var static_milk = get_node_or_null("../FLOOR/milk")
	if static_milk:
		static_milk.queue_free()

	await get_tree().process_frame
	_spawn_mapped_items()


func _spawn_mapped_items() -> void:
	var gm: Node = get_node_or_null("/root/GameModeManager")
	if not (gm and "shopping_list" in gm):
		return
		
	var s_list = gm.shopping_list
	if s_list.is_empty():
		return
		
	var config = {
		"milk": {"match": "freezer", "offset": 2.2},
		"cookie": {"match": "cookie", "offset": 0.5},
		"mustard": {"match": "mustard", "offset": 0.6},
		"ketchup": {"match": "ketchup", "offset": 0.6},
		"jar": {"match": "jar_b", "offset": 0.5},
		"pot": {"match": "pot", "offset": 0.6},
		"bowl": {"match": "bowl", "offset": 0.5},
		"knife": {"match": "knife", "offset": 0.4},
		"pan": {"match": "pan", "offset": 0.6},
		"papertowel": {"match": "papertowel", "offset": 0.5},
		"box": {"match": "box", "offset": 0.6},
		"bread": {"match": "display-bread", "offset": 1.2}
	}
	
	var candidate_map = {}
	for key in config:
		candidate_map[key] = []
		
	# Traverse and construct the mesh catalogue
	var floors_node: Node = get_node_or_null("../FLOOR")
	var assets_node: Node = get_node_or_null("../Assets")
	
	if floors_node: _scan_nodes(floors_node, config, candidate_map)
	if assets_node: _scan_nodes(assets_node, config, candidate_map)
	
	var collectible_scene = preload("res://CollectibleItem.tscn")
	var parent_node = get_parent()
	
	for key in s_list:
		var amount: int = s_list[key]["required"]
		var targets = candidate_map.get(key, [])
		targets.shuffle()
		
		for i in range(amount):
			var inst = collectible_scene.instantiate()
			inst.item_id = key
			inst.item_display_name = s_list[key]["label"]

			var pt = Vector3.ZERO
			if targets.size() > 0:
				var target_node = targets[i % targets.size()]
				pt = target_node.global_position + Vector3(0, config[key]["offset"], 0)
			else:
				push_warning("GameItemSpawner: No map geometry found for " + key)
				pt = Vector3(randf_range(-4, 4), 1.0, randf_range(-4, 4))
				
			inst.use_spawn_pos = true
			inst.spawn_global_pos = pt
			
			parent_node.call_deferred("add_child", inst)


func _scan_nodes(node: Node, config: Dictionary, candidate_map: Dictionary) -> void:
	if node is Node3D:
		var nname: String = node.name.to_lower()
		for key in config:
			if nname.find(config[key]["match"]) != -1:
				candidate_map[key].append(node)
				
	for c in node.get_children():
		_scan_nodes(c, config, candidate_map)
