# GameOverMenu - Game over overlay for Fusion Mania
# Shows final score, victory/defeat message, and new game button
extends CanvasLayer

# Signals
signal new_game_pressed()
signal menu_pressed()

# Node references
@onready var overlay_background = $OverlayBackground
@onready var menu_container     = $MenuContainer
@onready var title_label        = $MenuContainer/TitleLabel
@onready var score_label        = $MenuContainer/ScoreLabel
@onready var rank_label         = $MenuContainer/RankLabel
@onready var btn_new_game       = $MenuContainer/ButtonsContainer/BtnNewGame
@onready var btn_menu           = $MenuContainer/ButtonsContainer/BtnMenu

var is_victory: bool  = false
var final_score: int  = 0
var final_rank: int   = 0


func _ready():
	# Initially hidden
	hide()

	# Connect button signals
	btn_new_game.button_clicked.connect(_on_new_game_clicked)
	btn_menu.button_clicked.connect(_on_menu_clicked)

	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)


# Show the menu with game results
func show_menu():
	visible = true

	# Get final data from GameManager
	var game_data = GameManager.get_game_state()
	is_victory    = game_data.get("victory", false)
	final_score   = game_data.get("final_score", 0)
	final_rank    = game_data.get("rank", 0)

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
