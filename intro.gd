extends Control

# ─────────────────────────────────────────────
#  Intro Screen – Market Madness REDESIGN
#  Matches the game's vibrant purple/orange/red
#  cartoon supermarket aesthetic.
# ─────────────────────────────────────────────

const MAIN_SCENE := "res://main.tscn"

# Floating shopping icons to replace snowflakes
const ITEM_CHARS := ["🛒", "🥛", "🍎", "🧀", "🥕", "🍪", "🍅", "🥡", "⭐", "🛍️", "🍞", "🥣"]
const ITEM_COUNT := 18

# ─── Node references ─────────────────────────
@onready var background      : ColorRect      = $Background
@onready var particle_layer  : Node2D         = $SnowflakeLayer
@onready var card_shadow     : ColorRect      = $CardShadow
@onready var card            : PanelContainer = $Card
@onready var vbox            : VBoxContainer  = $Card/VBox
@onready var title_label     : Label          = $Card/VBox/TitleLabel
@onready var subtitle_label  : Label          = $Card/VBox/SubtitleLabel
@onready var separator       : HSeparator     = $Card/VBox/Separator
@onready var desc_label      : Label          = $Card/VBox/DescLabel
@onready var start_button    : Button         = $Card/VBox/StartButton
@onready var hint_label      : Label          = $Card/VBox/HintLabel
@onready var footer_label    : Label          = $FooterLabel

var start_sfx_player: AudioStreamPlayer

# ─── Runtime state ───────────────────────────
var _time          : float = 0.0
var _button_pulsed : float = 0.0
var _particles     : Array = []
var _can_start     : bool  = false
var _transitioning : bool  = false

# ─── BG gradient colors (hot purple + deep violet) ───
const BG_TOP    := Color(0.42, 0.08, 0.72, 1.0)   # bright violet
const BG_BOTTOM := Color(0.18, 0.03, 0.38, 1.0)   # deep royal purple

# ─────────────────────────────────────────────
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_apply_styles()
	_spawn_particles()
	start_button.pressed.connect(_on_start)

	start_sfx_player = AudioStreamPlayer.new()
	start_sfx_player.stream = load("res://Assets 1/KayKit_Prototype_Bits_1.1_FREE/Music/DingDong.ogg")
	add_child(start_sfx_player)

	await get_tree().process_frame
	_play_intro_animation()

# ─────────────────────────────────────────────
#  STYLES  (vibrant purple/orange game palette)
# ─────────────────────────────────────────────
func _apply_styles() -> void:
	# ── Background: deep purple ──
	background.color = BG_BOTTOM

	# ── Card: semi-transparent purple glass with vivid orange border ──
	var card_style := StyleBoxFlat.new()
	card_style.bg_color                   = Color(0.22, 0.06, 0.45, 0.92)
	card_style.border_color               = Color(1.0, 0.55, 0.05, 1.0)   # bright orange
	card_style.border_width_left          = 3
	card_style.border_width_right         = 3
	card_style.border_width_top           = 3
	card_style.border_width_bottom        = 3
	card_style.corner_radius_top_left     = 20
	card_style.corner_radius_top_right    = 20
	card_style.corner_radius_bottom_left  = 20
	card_style.corner_radius_bottom_right = 20
	card_style.content_margin_left        = 52
	card_style.content_margin_right       = 52
	card_style.content_margin_top         = 44
	card_style.content_margin_bottom      = 44
	# Glow shadow on card
	card_style.shadow_color = Color(1.0, 0.5, 0.0, 0.35)
	card_style.shadow_size  = 18
	card_style.shadow_offset= Vector2(0, 6)
	card.add_theme_stylebox_override("panel", card_style)

	# ── Title: big, bold, bright orange-yellow with glow ──
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.add_theme_color_override("font_color",        Color(1.0, 0.72, 0.05, 1.0))
	title_label.add_theme_color_override("font_shadow_color", Color(0.9, 0.3, 0.0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 4)
	title_label.add_theme_constant_override("shadow_as_outline", 0)

	# ── Subtitle: bright white with purple tint ──
	subtitle_label.add_theme_font_size_override("font_size", 18)
	subtitle_label.add_theme_color_override("font_color", Color(0.88, 0.78, 1.0, 1.0))

	# ── Separator: orange glow strip ──
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color             = Color(1.0, 0.55, 0.05, 0.7)
	sep_style.content_margin_top   = 4
	sep_style.content_margin_bottom = 4
	separator.add_theme_stylebox_override("separator", sep_style)

	# ── Desc: light lavender-white ──
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.92, 0.88, 1.0, 1.0))

	# ── START Button: vivid orange with red glow, rounded pill ──
	var btn_n := StyleBoxFlat.new()
	btn_n.bg_color                   = Color(0.95, 0.42, 0.05, 1.0)
	btn_n.corner_radius_top_left     = 40
	btn_n.corner_radius_top_right    = 40
	btn_n.corner_radius_bottom_left  = 40
	btn_n.corner_radius_bottom_right = 40
	btn_n.content_margin_left        = 32
	btn_n.content_margin_right       = 32
	btn_n.content_margin_top         = 16
	btn_n.content_margin_bottom      = 16
	btn_n.shadow_color = Color(1.0, 0.35, 0.0, 0.55)
	btn_n.shadow_size  = 16

	var btn_h := btn_n.duplicate() as StyleBoxFlat
	btn_h.bg_color    = Color(1.0, 0.58, 0.10, 1.0)
	btn_h.shadow_size = 26
	btn_h.shadow_color = Color(1.0, 0.5, 0.0, 0.70)

	var btn_p := btn_n.duplicate() as StyleBoxFlat
	btn_p.bg_color    = Color(0.75, 0.28, 0.02, 1.0)
	btn_p.shadow_size = 4

	start_button.add_theme_stylebox_override("normal",  btn_n)
	start_button.add_theme_stylebox_override("hover",   btn_h)
	start_button.add_theme_stylebox_override("pressed", btn_p)
	start_button.add_theme_font_size_override("font_size", 24)
	start_button.add_theme_color_override("font_color",         Color(1, 1, 1, 1))
	start_button.add_theme_color_override("font_hover_color",   Color(1, 1, 0.85, 1))
	start_button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
	start_button.custom_minimum_size = Vector2(300, 60)

	# ── Hint ──
	hint_label.add_theme_font_size_override("font_size", 14)
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.65, 1.0, 0.80))

	# ── Footer ──
	footer_label.add_theme_font_size_override("font_size", 13)
	footer_label.add_theme_color_override("font_color", Color(0.70, 0.60, 0.90, 0.75))

	# ── VBox spacing ──
	vbox.add_theme_constant_override("separation", 14)

# ─────────────────────────────────────────────
#  FLOATING SHOPPING PARTICLES (replace snowflakes)
# ─────────────────────────────────────────────
func _spawn_particles() -> void:
	randomize()
	for i in ITEM_COUNT:
		var lbl := Label.new()
		lbl.text = ITEM_CHARS[randi() % ITEM_CHARS.size()]
		var sz  := int(randf_range(20.0, 48.0))
		lbl.add_theme_font_size_override("font_size", sz)
		# Mix of light purple, orange, and white tints
		var tint_roll := randi() % 3
		var col : Color
		if tint_roll == 0:
			col = Color(1.0, 0.72, 0.3, randf_range(0.25, 0.60))   # warm orange
		elif tint_roll == 1:
			col = Color(0.85, 0.65, 1.0, randf_range(0.25, 0.60))  # soft purple
		else:
			col = Color(1.0, 1.0, 1.0, randf_range(0.18, 0.45))    # white
		lbl.add_theme_color_override("font_color", col)
		lbl.position = Vector2(randf_range(0.0, 1024.0), randf_range(-200.0, 650.0))
		particle_layer.add_child(lbl)
		_particles.append({
			"label": lbl,
			"speed": randf_range(14.0, 42.0),
			"drift": randf_range(-12.0, 12.0),
			"spin" : randf_range(-0.6, 0.6),
			"phase": randf_range(0.0, TAU),
			"bob"  : randf_range(0.3, 1.2),
		})

# ─────────────────────────────────────────────
#  INTRO ANIMATION
# ─────────────────────────────────────────────
func _play_intro_animation() -> void:
	card.modulate           = Color(1, 1, 1, 0)
	card.scale              = Vector2(0.80, 0.80)
	card.pivot_offset       = Vector2(320.0, 206.0)
	card_shadow.modulate    = Color(1, 1, 1, 0)
	title_label.modulate    = Color(1, 1, 1, 0)
	subtitle_label.modulate = Color(1, 1, 1, 0)
	separator.modulate      = Color(1, 1, 1, 0)
	desc_label.modulate     = Color(1, 1, 1, 0)
	start_button.modulate   = Color(1, 1, 1, 0)
	hint_label.modulate     = Color(1, 1, 1, 0)
	footer_label.modulate   = Color(1, 1, 1, 0)

	# Stage 1: card pops in with a bouncy spring
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card_shadow, "modulate", Color(1,1,1,1), 0.50).set_ease(Tween.EASE_OUT)
	tw.tween_property(card,        "modulate", Color(1,1,1,1), 0.50).set_ease(Tween.EASE_OUT)
	tw.tween_property(card,        "scale",    Vector2(1,1),   0.55).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	await tw.finished

	# Stage 2: title slams in
	var tw2 := create_tween()
	tw2.tween_property(title_label, "modulate", Color(1,1,1,1), 0.35).set_ease(Tween.EASE_OUT)
	await tw2.finished

	# Title quick bounce
	var tw2b := create_tween()
	tw2b.tween_property(title_label, "scale", Vector2(1.06, 1.06), 0.08).set_trans(Tween.TRANS_QUAD)
	tw2b.tween_property(title_label, "scale", Vector2(1.0,  1.0),  0.12).set_trans(Tween.TRANS_BACK)
	await tw2b.finished

	# Stage 3: subtitle
	var tw3 := create_tween()
	tw3.tween_property(subtitle_label, "modulate", Color(1,1,1,1), 0.30)
	await tw3.finished

	# Stage 4: separator + desc
	var tw4 := create_tween()
	tw4.set_parallel(true)
	tw4.tween_property(separator,  "modulate", Color(1,1,1,1), 0.28)
	tw4.tween_property(desc_label, "modulate", Color(1,1,1,1), 0.38)
	await tw4.finished

	# Stage 5: button + hint + footer
	var tw5 := create_tween()
	tw5.set_parallel(true)
	tw5.tween_property(start_button, "modulate", Color(1,1,1,1), 0.40)
	tw5.tween_property(hint_label,   "modulate", Color(1,1,1,1), 0.30)
	tw5.tween_property(footer_label, "modulate", Color(1,1,1,1), 0.30)
	await tw5.finished

	_can_start = true

# ─────────────────────────────────────────────
#  PROCESS
# ─────────────────────────────────────────────
func _process(delta: float) -> void:
	_time          += delta
	_button_pulsed += delta

	var vp : Vector2 = get_viewport().get_visible_rect().size

	# Animated background: subtle gradient pulse between two purples
	var t_col := BG_TOP.lerp(BG_BOTTOM, 0.5 + 0.5 * sin(_time * 0.4))
	background.color = t_col.lerp(BG_BOTTOM, 0.3)

	# ── Floating items drift upward (rising effect) ──
	for p in _particles:
		var lbl : Label = p["label"]
		lbl.position.y -= (p["speed"] as float) * delta
		lbl.position.x += (p["drift"] as float) * delta * 0.5 + sin(_time * (p["bob"] as float) + (p["phase"] as float)) * 0.5
		lbl.rotation   += (p["spin"]  as float) * delta

		# Wrap: if flies off top, respawn at bottom
		if lbl.position.y < -80.0:
			lbl.position.y = vp.y + 60.0
			lbl.position.x = randf_range(0.0, vp.x)
		if lbl.position.x < -50.0:
			lbl.position.x = vp.x + 30.0
		elif lbl.position.x > vp.x + 50.0:
			lbl.position.x = -30.0

	# ── Start button: energetic orange pulse ──
	if _can_start and not _transitioning:
		var pulse : float = 0.90 + sin(_button_pulsed * 4.0) * 0.10
		start_button.modulate = Color(pulse, pulse * 0.8 + 0.2, pulse * 0.4, 1.0)
		# Also slightly scale the button
		var btn_scale := 1.0 + sin(_button_pulsed * 4.0) * 0.025
		start_button.scale = Vector2(btn_scale, btn_scale)

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
	if start_sfx_player:
		start_sfx_player.play()
	_transitioning = true
	_can_start     = false
	GameModeManager.play_start_sound()

	# Flash white before scene swap (energetic punch feel)
	var tw_flash := create_tween()
	tw_flash.tween_property(background, "color", Color(1, 1, 1, 1), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_flash.finished

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(card,        "modulate", Color(1, 1, 1, 0), 0.40).set_ease(Tween.EASE_IN)
	tw.tween_property(card,        "scale",    Vector2(1.1, 1.1), 0.40).set_ease(Tween.EASE_IN)
	tw.tween_property(card_shadow, "modulate", Color(1, 1, 1, 0), 0.40)
	tw.tween_property(background,  "modulate", Color(1, 1, 1, 0), 0.50).set_ease(Tween.EASE_IN)
	tw.tween_property(footer_label,"modulate", Color(1, 1, 1, 0), 0.30)
	await tw.finished

	get_tree().change_scene_to_file(MAIN_SCENE)
