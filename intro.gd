extends Control

# ─────────────────────────────────────────────
#  Intro Screen – Market Madness
#  Uses await + scale animation (no position tweening)
#  to avoid anchor-layout conflicts in _ready()
# ─────────────────────────────────────────────

const MAIN_SCENE        := "res://main.tscn"
const SNOWFLAKE_CHARS   := ["❄", "❅", "❆", "*", "✦"]
const SNOWFLAKE_COUNT   := 22

# ─── Node references ─────────────────────────
@onready var background     : ColorRect      = $Background
@onready var snowflake_layer: Node2D         = $SnowflakeLayer
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

# ─── Runtime state ───────────────────────────
var _time          : float = 0.0
var _button_pulsed : float = 0.0
var _snowflakes    : Array = []
var _tree_labels   : Array = []
var _can_start     : bool  = false
var _transitioning : bool  = false

# Christmas-tree anchor positions (fraction of viewport)
const TREE_AX : Array = [0.06, 0.94]
const TREE_AY : Array = [0.48, 0.48]

# ─────────────────────────────────────────────
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_styles()
	_spawn_trees()
	_spawn_snowflakes()
	start_button.pressed.connect(_on_start)

	# Wait one frame so Control layout is fully resolved, THEN animate
	await get_tree().process_frame
	_play_intro_animation()

# ─────────────────────────────────────────────
#  STYLES
# ─────────────────────────────────────────────
func _apply_styles() -> void:
	background.color = Color(0.098, 0.075, 0.165, 1.0)

	# ── Card panel ──
	var card_style := StyleBoxFlat.new()
	card_style.bg_color                   = Color(0.10, 0.09, 0.22, 0.96)
	card_style.border_color               = Color(0.75, 0.38, 0.10, 1.0)
	card_style.border_width_left          = 2
	card_style.border_width_right         = 2
	card_style.border_width_top           = 2
	card_style.border_width_bottom        = 2
	card_style.corner_radius_top_left     = 16
	card_style.corner_radius_top_right    = 16
	card_style.corner_radius_bottom_left  = 16
	card_style.corner_radius_bottom_right = 16
	card_style.content_margin_left        = 48
	card_style.content_margin_right       = 48
	card_style.content_margin_top         = 40
	card_style.content_margin_bottom      = 40
	card.add_theme_stylebox_override("panel", card_style)

	# ── Title ──
	title_label.add_theme_font_size_override("font_size", 52)
	title_label.add_theme_color_override("font_color",        Color(0.96, 0.78, 0.20, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)

	# ── Subtitle ──
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.98, 0.60, 1.0))

	# ── Separator ──
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color            = Color(0.42, 0.42, 0.60, 0.5)
	sep_style.content_margin_top    = 6
	sep_style.content_margin_bottom = 6
	separator.add_theme_stylebox_override("separator", sep_style)

	# ── Desc ──
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.88, 0.88, 0.95, 1.0))

	# ── Start Button ──
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color                    = Color(0.85, 0.38, 0.08, 1.0)
	btn_n.corner_radius_top_left      = 40
	btn_n.corner_radius_top_right     = 40
	btn_n.corner_radius_bottom_left   = 40
	btn_n.corner_radius_bottom_right  = 40
	btn_n.content_margin_left         = 28
	btn_n.content_margin_right        = 28
	btn_n.content_margin_top          = 14
	btn_n.content_margin_bottom       = 14
	btn_n.shadow_color = Color(0.85, 0.38, 0.08, 0.45)
	btn_n.shadow_size  = 12

	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color   = Color(1.0, 0.50, 0.12, 1.0)
	btn_h.shadow_size = 20

	var btn_p := btn_n.duplicate() as StyleBoxFlat
	btn_p.bg_color   = Color(0.65, 0.26, 0.04, 1.0)
	btn_p.shadow_size = 4

	start_button.add_theme_stylebox_override("normal",  btn_n)
	start_button.add_theme_stylebox_override("hover",   btn_h)
	start_button.add_theme_stylebox_override("pressed", btn_p)
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.add_theme_color_override("font_color",         Color(1, 1, 1, 1))
	start_button.add_theme_color_override("font_hover_color",   Color(1, 1, 1, 1))
	start_button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	start_button.custom_minimum_size = Vector2(280, 56)

	# ── Hint ──
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.70, 0.70, 0.85, 0.8))

	# ── Footer ──
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", Color(0.60, 0.60, 0.80, 0.8))

	# ── VBox spacing ──
	vbox.add_theme_constant_override("separation", 14)

# ─────────────────────────────────────────────
#  CHRISTMAS TREES
# ─────────────────────────────────────────────
func _spawn_trees() -> void:
	for i in 2:
		var lbl := Label.new()
		lbl.text = "🎄"
		lbl.add_theme_font_size_override("font_size", 96)
		lbl.z_index = -1
		add_child(lbl)
		_tree_labels.append(lbl)

# ─────────────────────────────────────────────
#  SNOWFLAKES
# ─────────────────────────────────────────────
func _spawn_snowflakes() -> void:
	randomize()
	for i in SNOWFLAKE_COUNT:
		var lbl := Label.new()
		lbl.text = SNOWFLAKE_CHARS[randi() % SNOWFLAKE_CHARS.size()]
		lbl.add_theme_font_size_override("font_size", int(randf_range(14.0, 32.0)))
		lbl.add_theme_color_override("font_color", Color(0.72, 0.85, 1.0, randf_range(0.3, 0.85)))
		lbl.position = Vector2(randf_range(0.0, 1024.0), randf_range(-200.0, 600.0))
		snowflake_layer.add_child(lbl)
		_snowflakes.append({
			"label": lbl,
			"speed": randf_range(18.0, 55.0),
			"drift": randf_range(-15.0, 15.0),
			"spin" : randf_range(-0.5, 0.5),
			"phase": randf_range(0.0, TAU),
		})

# ─────────────────────────────────────────────
#  INTRO ANIMATION
#  Called AFTER await get_tree().process_frame
#  so Control layout is already resolved.
# ─────────────────────────────────────────────
func _play_intro_animation() -> void:
	# ── Hide everything ──
	card.modulate           = Color(1, 1, 1, 0)
	card.scale              = Vector2(0.85, 0.85)
	card.pivot_offset       = Vector2(320.0, 206.0)   # centre of card (640x412 total = half each side)
	card_shadow.modulate    = Color(1, 1, 1, 0)
	title_label.modulate    = Color(1, 1, 1, 0)
	subtitle_label.modulate = Color(1, 1, 1, 0)
	separator.modulate      = Color(1, 1, 1, 0)
	desc_label.modulate     = Color(1, 1, 1, 0)
	start_button.modulate   = Color(1, 1, 1, 0)
	hint_label.modulate     = Color(1, 1, 1, 0)
	footer_label.modulate   = Color(1, 1, 1, 0)
	for t in _tree_labels:
		t.modulate = Color(1, 1, 1, 0)

	# ── Stage 1: card + shadow zoom-fade in ──
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card_shadow, "modulate", Color(1, 1, 1, 1), 0.55).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate", Color(1, 1, 1, 1), 0.55).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale",    Vector2(1.0, 1.0),  0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw.finished

	# ── Stage 2: title ──
	var tw2 := create_tween()
	tw2.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.4).set_ease(Tween.EASE_OUT)
	await tw2.finished

	# ── Stage 3: subtitle ──
	var tw3 := create_tween()
	tw3.tween_property(subtitle_label, "modulate", Color(1, 1, 1, 1), 0.35)
	await tw3.finished

	# ── Stage 4: separator + desc ──
	var tw4 := create_tween()
	tw4.set_parallel(true)
	tw4.tween_property(separator,  "modulate", Color(1, 1, 1, 1), 0.30)
	tw4.tween_property(desc_label, "modulate", Color(1, 1, 1, 1), 0.40)
	await tw4.finished

	# ── Stage 5: button + hint ──
	var tw5 := create_tween()
	tw5.set_parallel(true)
	tw5.tween_property(start_button, "modulate", Color(1, 1, 1, 1), 0.4)
	tw5.tween_property(hint_label,   "modulate", Color(1, 1, 1, 1), 0.3)
	await tw5.finished

	# ── Stage 6: trees + footer ──
	var tw6 := create_tween()
	tw6.set_parallel(true)
	for t in _tree_labels:
		tw6.tween_property(t, "modulate", Color(1, 1, 1, 1), 0.5)
	tw6.tween_property(footer_label, "modulate", Color(1, 1, 1, 1), 0.4)
	await tw6.finished

	_can_start = true

# ─────────────────────────────────────────────
#  PROCESS – snowflakes + button pulse + trees
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	_time          += delta
	_button_pulsed += delta

	var vp : Vector2 = get_viewport().get_visible_rect().size

	# ── Snowflakes ──
	for flake in _snowflakes:
		var lbl : Label = flake["label"]
		lbl.position.x += (flake["drift"] as float) * delta + sin(_time * 0.8 + (flake["phase"] as float)) * 0.4
		lbl.position.y += (flake["speed"] as float) * delta
		lbl.rotation   += (flake["spin"]  as float) * delta

		if lbl.position.y > vp.y + 60.0:
			lbl.position.y = -60.0
			lbl.position.x = randf_range(0.0, vp.x)
		if lbl.position.x < -40.0:
			lbl.position.x = vp.x + 20.0
		elif lbl.position.x > vp.x + 40.0:
			lbl.position.x = -20.0

	# ── Christmas trees sway ──
	for i in _tree_labels.size():
		var lbl  : Label  = _tree_labels[i]
		var ax   : float  = TREE_AX[i]
		var ay   : float  = TREE_AY[i]
		var bx   : float  = vp.x * ax - 48.0
		var by   : float  = vp.y * ay - 48.0
		var sway : float  = sin(_time * 0.9 + float(i) * PI) * 5.0
		var bob  : float  = sin(_time * 1.4 + float(i) * 0.7) * 4.0
		lbl.position = Vector2(bx + sway, by + bob)

	# ── Button pulse ──
	if _can_start and not _transitioning:
		var pulse : float = 0.88 + sin(_button_pulsed * 3.2) * 0.12
		start_button.modulate = Color(1.0, pulse * 0.85 + 0.15, pulse * 0.5, 1.0)

# ─────────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if _can_start and not _transitioning:
		if event.is_action_pressed("ui_accept"):
			_on_start()

# ─────────────────────────────────────────────
#  START TRANSITION
# ─────────────────────────────────────────────
func _on_start() -> void:
	if _transitioning:
		return
	_transitioning = true
	_can_start     = false

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card,         "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(card,         "scale",    Vector2(0.9, 0.9), 0.5).set_ease(Tween.EASE_IN)
	tw.tween_property(card_shadow,  "modulate", Color(1, 1, 1, 0), 0.5)
	tw.tween_property(background,   "modulate", Color(1, 1, 1, 0), 0.6).set_ease(Tween.EASE_IN)
	tw.tween_property(footer_label, "modulate", Color(1, 1, 1, 0), 0.4)
	for t in _tree_labels:
		tw.tween_property(t, "modulate", Color(1, 1, 1, 0), 0.4)

	await tw.finished
	get_tree().change_scene_to_file(MAIN_SCENE)
