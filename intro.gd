extends Control

# ─────────────────────────────────────────────
#  Intro Screen – Market Madness
#  Thematic Overhaul: Market Chaos
# ─────────────────────────────────────────────

const MAIN_SCENE      := "res://main.tscn"
const ITEM_CHARS      := ["🛒", "🍎", "🥦", "🥛", "🥩", "🍞", "🧀"]
const ITEM_COUNT      := 25

# ─── Node references ─────────────────────────
@onready var background     : ColorRect      = $Background
@onready var snowflake_layer: Node2D         = $SnowflakeLayer # We'll reuse this as "ItemLayer"
@onready var card_shadow    : ColorRect      = $CardShadow
@onready var card           : PanelContainer = $Card
@onready var vbox           : VBoxContainer  = $Card/VBox
@onready var title_label    : Label          = $Card/VBox/TitleLabel
@onready var subtitle_label : Label          = $Card/VBox/SubtitleLabel
@onready var separator      : HSeparator     = $Card/VBox/Separator
@onready var desc_label     : Label          = $Card/VBox/DescLabel
@onready var start_button   : Button         = $Card/VBox/StartButton
@onready var hint_label     : Label          = $Card/VBox/HintLabel
@onready var footer_label   : Label          = $FooterLabel
var start_sfx_player: AudioStreamPlayer

# ─── Runtime state ───────────────────────────
var _time          : float = 0.0
var _button_pulsed : float = 0.0
var _items         : Array = []
var _side_labels   : Array = []
var _can_start     : bool  = false
var _transitioning : bool  = false

# Side icon positions (fraction of viewport)
const SIDE_AX : Array = [0.08, 0.92]
const SIDE_AY : Array = [0.50, 0.50]

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_styles()
	_spawn_side_icons()
	_spawn_falling_items()
	start_button.pressed.connect(_on_start)
	
	start_sfx_player = AudioStreamPlayer.new()
	start_sfx_player.stream = load("res://Assets 1/KayKit_Prototype_Bits_1.1_FREE/Music/DingDong.ogg")
	add_child(start_sfx_player)
	
	await get_tree().process_frame
	_play_intro_animation()

func _apply_styles() -> void:
	# Chaos Purple Background
	background.color = Color(0.08, 0.06, 0.14, 1.0)

	# ── Card panel ──
	var card_style := StyleBoxFlat.new()
	card_style.bg_color                   = Color(0.12, 0.10, 0.20, 0.92)
	card_style.border_color               = Color(0.95, 0.85, 0.20, 1.0) # Neon Yellow border
	card_style.set_border_width_all(3)
	card_style.set_corner_radius_all(20)
	card_style.set_content_margin_all(45)
	card_style.shadow_color               = Color(0.6, 0.2, 0.8, 0.3) # Purple glow
	card_style.shadow_size                = 25
	card.add_theme_stylebox_override("panel", card_style)

	# ── Title ──
	title_label.text = "MARKET MADNESS"
	title_label.add_theme_font_size_override("font_size", 64)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2)) # Bright Gold
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 12)

	# ── Subtitle ──
	subtitle_label.text = "THE ULTIMATE SHOPPING CHAOS"
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.9)) # Neon Pink

	# ── Start Button ──
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color                    = Color(0.95, 0.8, 0.1, 1.0) # Yellow
	btn_n.set_corner_radius_all(10)
	btn_n.set_content_margin_all(15)
	btn_n.shadow_color = Color(1.0, 0.8, 0.0, 0.5)
	btn_n.shadow_size  = 15

	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color   = Color(1.0, 0.95, 0.4, 1.0)
	btn_h.shadow_size = 25

	start_button.add_theme_stylebox_override("normal",  btn_n)
	start_button.add_theme_stylebox_override("hover",   btn_h)
	start_button.add_theme_font_size_override("font_size", 26)
	start_button.add_theme_color_override("font_color", Color.BLACK)
	start_button.add_theme_color_override("font_hover_color", Color.BLACK)

	desc_label.text = "Fill your cart, avoid the crowd, and survive the Roulette!"
	footer_label.text = "Created for UM Game Jam 2026"

func _spawn_side_icons() -> void:
	for i in 2:
		var lbl := Label.new()
		lbl.text = "🛒"
		lbl.add_theme_font_size_override("font_size", 110)
		lbl.z_index = -1
		add_child(lbl)
		_side_labels.append(lbl)

func _spawn_falling_items() -> void:
	randomize()
	for i in ITEM_COUNT:
		var lbl := Label.new()
		lbl.text = ITEM_CHARS[randi() % ITEM_CHARS.size()]
		lbl.add_theme_font_size_override("font_size", int(randf_range(20.0, 45.0)))
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, randf_range(0.4, 0.9)))
		lbl.position = Vector2(randf_range(0.0, 1152.0), randf_range(-200.0, 648.0))
		snowflake_layer.add_child(lbl)
		_items.append({
			"label": lbl,
			"speed": randf_range(50.0, 150.0),
			"drift": randf_range(-20.0, 20.0),
			"spin" : randf_range(-1.0, 1.0),
			"phase": randf_range(0.0, TAU),
		})

func _play_intro_animation() -> void:
	card.modulate = Color(1, 1, 1, 0)
	card.scale = Vector2(0.9, 0.9)
	card.pivot_offset = card.size / 2.0
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.8)
	tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.8)
	await tw.finished
	_can_start = true

func _process(delta: float) -> void:
	_time += delta
	var vp : Vector2 = get_viewport().get_visible_rect().size

	# ── Falling Items ──
	for item in _items:
		var lbl : Label = item["label"]
		lbl.position.y += (item["speed"] as float) * delta
		lbl.position.x += sin(_time + (item["phase"] as float)) * 0.5
		lbl.rotation   += (item["spin"]  as float) * delta
		if lbl.position.y > vp.y + 100:
			lbl.position.y = -100
			lbl.position.x = randf_range(0, vp.x)

	# ── Side Carts sway ──
	for i in _side_labels.size():
		var lbl : Label = _side_labels[i]
		var base_pos = Vector2(vp.x * SIDE_AX[i] - 55, vp.y * SIDE_AY[i] - 55)
		lbl.position = base_pos + Vector2(sin(_time * 2.0 + i) * 15, cos(_time * 1.5 + i) * 10)
		lbl.rotation = sin(_time * 3.0 + i) * 0.1

	# ── Title Chaos Vibration ──
	title_label.position.x = 0 + sin(_time * 20.0) * (2.0 if _can_start else 0.0)
	
	if _can_start and not _transitioning:
		var pulse : float = (sin(_time * 4.0) + 1.0) * 0.5
		start_button.modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.2, 1.2, 1.0), pulse)

func _on_start() -> void:
	if _transitioning: return
	if start_sfx_player: start_sfx_player.play()
	_transitioning = true
	_can_start = false
	
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(card, "modulate", Color(1, 1, 1, 0), 0.5)
	await tw.finished
	get_tree().change_scene_to_file(MAIN_SCENE)
