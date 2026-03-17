# OptionsMenu - Options overlay for Fusion Mania
# Music/SFX toggles, reset ranking, and back button
extends CanvasLayer

# Signals
signal back_pressed()
signal ranking_reset()

# Node references (created dynamically)
var overlay_background: ColorRect
var menu_container: VBoxContainer
var title_label: Label
var buttons_container: VBoxContainer
var btn_music: Node
var btn_sfx: Node
var btn_language: Node
var btn_reset_ranking: Node
var btn_back: Node

# Constants for UI
const BUTTON_WIDTH     = 400
const BUTTON_HEIGHT    = 91
const BUTTON_SEPARATION = 20
const TITLE_FONT_SIZE  = 56
const SPACER_HEIGHT    = 40


func _ready():
	# Build scene hierarchy
	_setup_scene()

	# Initially hidden
	hide()

	# Connect button signals
	btn_music.button_clicked.connect(_on_music_clicked)
	btn_sfx.button_clicked.connect(_on_sfx_clicked)
	btn_language.button_clicked.connect(_on_language_clicked)
	btn_reset_ranking.button_clicked.connect(_on_reset_ranking_clicked)
	btn_back.button_clicked.connect(_on_back_clicked)

	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)

	# Update translations
	update_translations()


# Build scene hierarchy programmatically
func _setup_scene():
	# Overlay background
	overlay_background = ColorRect.new()
	overlay_background.name = "OverlayBackground"
	overlay_background.offset_right = 1080.0
	overlay_background.offset_bottom = 1920.0
	overlay_background.color = Color(0, 0, 0, 0.8)
	add_child(overlay_background)

	# Menu container
	menu_container = VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.offset_left = 240.0
	menu_container.offset_top = 500.0
	menu_container.offset_right = 840.0
	menu_container.offset_bottom = 1400.0
	menu_container.add_theme_constant_override("separation", 20)
	add_child(menu_container)

	# Title label
	title_label = ThemeManager.create_label()
	title_label.name = "TitleLabel"
	title_label.layout_mode = 2
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.text = "OPTIONS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_container.add_child(title_label)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, SPACER_HEIGHT)
	spacer.layout_mode = 2
	menu_container.add_child(spacer)

	# Buttons container
	buttons_container = VBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.layout_mode = 2
	buttons_container.add_theme_constant_override("separation", BUTTON_SEPARATION)
	buttons_container.alignment = 1
	menu_container.add_child(buttons_container)

	# Create all buttons
	btn_music         = _create_button("BtnMusic", "MUSIC: ON")
	btn_sfx           = _create_button("BtnSfx", "SFX: ON")
	btn_language      = _create_button("BtnLanguage", "ENGLISH")
	btn_reset_ranking = _create_button("BtnResetRanking", "RESET RANKING")
	btn_back          = _create_button("BtnBack", "BACK")


# Helper to create button
func _create_button(button_name, initial_text):
	var btn = load("res://widgets/UIButton.tscn").instantiate()
	btn.name = button_name
	btn.layout_mode = 2
	btn.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	btn.text = initial_text
	buttons_container.add_child(btn)
	return btn


# Show the menu
func show_menu():
	visible = true
	update_translations()


# Hide the menu
func hide_menu():
	visible = false


# Update all texts with translations
func update_translations():
	title_label.text = tr("OPTIONS")

	# Music button text based on state
	if AudioManager.is_music_enabled():
		btn_music.text = tr("MUSIC_ACTIVE")
	else:
		btn_music.text = tr("MUSIC_INACTIVE")

	# SFX button text based on state
	if AudioManager.is_sfx_enabled():
		btn_sfx.text = tr("SFX_ACTIVE")
	else:
		btn_sfx.text = tr("SFX_INACTIVE")

	# Language button
	var current_lang = LanguageManager.get_current_language()
	if current_lang == "fr":
		btn_language.text = tr("FRENCH")
	else:
		btn_language.text = tr("ENGLISH")

	btn_reset_ranking.text = tr("RESET_RANKING")
	btn_back.text          = tr("BACK")


# Language changed callback
func _on_language_changed():
	update_translations()


# Button callbacks
func _on_music_clicked():
	print("OptionsMenu: Music toggle clicked")
	AudioManager.toggle_music()
	update_translations()


func _on_sfx_clicked():
	print("OptionsMenu: SFX toggle clicked")
	AudioManager.toggle_sfx()
	update_translations()


func _on_language_clicked():
	print("OptionsMenu: Language toggle clicked")
	var current_lang = LanguageManager.get_current_language()
	if current_lang == "en":
		LanguageManager.set_language("fr")
	else:
		LanguageManager.set_language("en")
	update_translations()


func _on_reset_ranking_clicked():
	print("OptionsMenu: Reset ranking clicked")
	ScoreManager.reset_all_scores()
	ranking_reset.emit()


func _on_back_clicked():
	print("OptionsMenu: Back clicked")
	back_pressed.emit()
