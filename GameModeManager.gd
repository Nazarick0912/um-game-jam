extends Node

# ──────────────────────────────────────────────────────────
#  GameModeManager  – Autoload singleton
#  Tracks the player's shopping list and broadcasts signals
#  to the ShoppingHUD.
# ──────────────────────────────────────────────────────────

signal list_updated()
signal game_won()
signal game_lost()

# Shopping list definition: key → { label, required, collected }
var shopping_list: Dictionary = {}

var _game_active: bool = false
var _game_ended:  bool = false

# ── Lifecycle ────────────────────────────────────────────
func _ready() -> void:
	_reset_list()

func _reset_list() -> void:
	shopping_list = {
		"milk":  { "label": "🥛 Milk",  "required": 1, "collected": 0 },
		"bread": { "label": "🍞 Bread", "required": 1, "collected": 0 },
		"box":   { "label": "📦 Box",   "required": 3, "collected": 0 },
	}
	_game_active = true
	_game_ended  = false

# ── Called by CollectibleItem when the player picks up an item ──
func collect_item(item_id: String) -> void:
	if not _game_active or _game_ended:
		return
	if item_id in shopping_list:
		var entry: Dictionary = shopping_list[item_id]
		if entry["collected"] < entry["required"]:
			entry["collected"] += 1
			emit_signal("list_updated")
			_check_win()

# ── Check if all items are collected ────────────────────
func _check_win() -> void:
	for key in shopping_list:
		if shopping_list[key]["collected"] < shopping_list[key]["required"]:
			return
	_game_ended  = true
	_game_active = false
	emit_signal("game_won")

# ── Called externally when the player's 60 s timer runs out ─
func notify_time_up() -> void:
	if not _game_ended:
		_game_ended  = true
		_game_active = false
		emit_signal("game_lost")

# ── Helpers ──────────────────────────────────────────────
func is_active() -> bool:
	return _game_active

## Returns formatted shopping list for UI display
func get_progress_lines() -> Array:
	var lines: Array = []
	for key in shopping_list:
		var e: Dictionary = shopping_list[key]
		var done: int = mini(e["collected"], e["required"])
		var tick: String = "✅" if done >= e["required"] else "🔲"
		lines.append("%s %s  %d / %d" % [tick, e["label"], done, e["required"]])
	return lines
