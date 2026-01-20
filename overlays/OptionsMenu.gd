# OptionsMenu - Options overlay for Fusion Mania
# Music/SFX toggles, reset ranking, and back button
extends CanvasLayer

# Signals
signal back_pressed()
signal ranking_reset()

# Node references
@onready var overlay_background = $OverlayBackground
@onready var menu_container     = $MenuContainer
@onready var title_label        = $MenuContainer/TitleLabel
@onready var btn_music          = $MenuContainer/ButtonsContainer/BtnMusic
@onready var btn_sfx            = $MenuContainer/ButtonsContainer/BtnSfx
@onready var btn_language       = $MenuContainer/ButtonsContainer/BtnLanguage
@onready var btn_reset_ranking  = $MenuContainer/ButtonsContainer/BtnResetRanking
@onready var btn_back           = $MenuContainer/ButtonsContainer/BtnBack


func _ready():
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
