# GameOverMenu - Game over overlay for Fusion Mania
# Shows final score, victory/defeat message, and new game button
extends CanvasLayer

# Signals
signal new_game_pressed()
signal menu_pressed()

# Node references (created dynamically)
var overlay_background: ColorRect
var menu_container: VBoxContainer
var title_label: Label
var score_label: Label
var rank_label: Label
var buttons_container: VBoxContainer
var btn_new_game: Node
var btn_menu: Node

var is_victory: bool  = false
var final_score: int  = 0
var final_rank: int   = 0

# Constants
const TITLE_FONT_SIZE  = 52
const SCORE_FONT_SIZE  = 40
const RANK_FONT_SIZE   = 32
const SPACER_HEIGHT    = 40
const BUTTON_WIDTH     = 400
const BUTTON_HEIGHT    = 91
const BUTTON_SEPARATION = 20
const CONTAINER_SEPARATION = 25


func _ready():
	# Build scene hierarchy
	_setup_scene()

	# Initially hidden
	hide()

	# Connect button signals
	btn_new_game.button_clicked.connect(_on_new_game_clicked)
	btn_menu.button_clicked.connect(_on_menu_clicked)

	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)


# Build scene hierarchy programmatically
func _setup_scene():
	# Overlay background
	overlay_background = ColorRect.new()
	overlay_background.name = "OverlayBackground"
	overlay_background.offset_right = 1080.0
	overlay_background.offset_bottom = 1920.0
	overlay_background.color = Color(0.2, 0, 0, 0.85)
	add_child(overlay_background)

	# Menu container
	menu_container = VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.offset_left = 240.0
	menu_container.offset_top = 550.0
	menu_container.offset_right = 840.0
	menu_container.offset_bottom = 1350.0
	menu_container.add_theme_constant_override("separation", CONTAINER_SEPARATION)
	add_child(menu_container)

	# Title label
	title_label = ThemeManager.create_label()
	title_label.name = "TitleLabel"
	title_label.layout_mode = 2
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.text = "GAME OVER"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_container.add_child(title_label)

	# Spacer 1
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, SPACER_HEIGHT)
	spacer1.layout_mode = 2
	menu_container.add_child(spacer1)

	# Score label
	score_label = ThemeManager.create_label()
	score_label.name = "ScoreLabel"
	score_label.layout_mode = 2
	score_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)
	score_label.text = "FINAL SCORE: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_container.add_child(score_label)

	# Rank label
	rank_label = ThemeManager.create_label()
	rank_label.name = "RankLabel"
	rank_label.layout_mode = 2
	rank_label.add_theme_font_size_override("font_size", RANK_FONT_SIZE)
	rank_label.text = "NEW HIGH SCORE #1!"
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_container.add_child(rank_label)

	# Spacer 2
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, SPACER_HEIGHT)
	spacer2.layout_mode = 2
	menu_container.add_child(spacer2)

	# Buttons container
	buttons_container = VBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.layout_mode = 2
	buttons_container.add_theme_constant_override("separation", BUTTON_SEPARATION)
	buttons_container.alignment = 1
	menu_container.add_child(buttons_container)

	# Create buttons
	btn_new_game = _create_button("BtnNewGame", "NEW GAME")
	btn_menu     = _create_button("BtnMenu", "BACK TO MENU")


# Helper to create button
func _create_button(button_name, initial_text):
	var btn = load("res://widgets/UIButton.tscn").instantiate()
	btn.name = button_name
	btn.layout_mode = 2
	btn.custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	btn.text = initial_text
	buttons_container.add_child(btn)
	return btn


# Show the menu with game results
func show_menu():
	visible = true

	# Get final data from SaveManager
	var infos 	= SaveManager.get_game_infos()
	is_victory	= infos.get("victory", false)
	final_score	= infos.get("final_score", 0)
	final_rank	= infos.get("rank", 0)

	update_display()
	update_translations()


# Hide the menu
func hide_menu():
	visible = false


# Update display based on game result
func update_display():
	# Title based on victory/defeat
	if is_victory:
		title_label.text = "🏆 " + tr("VICTORY") + " 🏆"
		overlay_background.color = Color(0, 0.3, 0, 0.8)  # Green tint
	else:
		title_label.text = "💀 " + tr("GAME_OVER") + " 💀"
		overlay_background.color = Color(0.3, 0, 0, 0.8)  # Red tint

	# Score
	score_label.text = tr("FINAL_SCORE") + ": " + str(final_score)

	# Rank
	if final_rank > 0 and final_rank <= 10:
		rank_label.text    = tr("NEW_HIGH_SCORE") + " #" + str(final_rank)
		rank_label.visible = true
	else:
		rank_label.visible = false


# Update translations
func update_translations():
	btn_new_game.text = tr("NEW_GAME")
	btn_menu.text     = tr("BACK_TO_MENU")
	update_display()


# Language changed callback
func _on_language_changed():
	update_translations()


# Button callbacks
func _on_new_game_clicked():
	print("GameOverMenu: New Game clicked")
	new_game_pressed.emit()


func _on_menu_clicked():
	print("GameOverMenu: Menu clicked")
	menu_pressed.emit()
