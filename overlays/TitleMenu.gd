# TitleMenu - Main menu overlay for Fusion Mania
# Reviewed
extends CanvasLayer

# Signals for each button action
signal mania_mode_pressed()
signal classic_mode_pressed()
signal free_mode_pressed()
signal resume_pressed()
signal ranking_pressed()
signal options_pressed()
signal quit_pressed()

# Node references
@onready var overlay_background	= $OverlayBackground
@onready var menu_container    	= $MenuContainer
@onready var logo             	= $MenuContainer/Logo
@onready var btn_mania        	= $MenuContainer/ButtonsContainer/BtnMania
@onready var btn_classic      	= $MenuContainer/ButtonsContainer/BtnClassic
@onready var btn_free_mode    	= $MenuContainer/ButtonsContainer/BtnFree
@onready var btn_resume       	= $MenuContainer/ButtonsContainer/BtnResume
@onready var btn_ranking      	= $MenuContainer/ButtonsContainer/BtnRanking
@onready var btn_options      	= $MenuContainer/ButtonsContainer/BtnOptions
@onready var btn_quit         	= $MenuContainer/ButtonsContainer/BtnQuit


func _ready():
	# Initially hidden
	hide()

	# Connect button signals
	btn_mania.button_clicked.connect(_on_mania_mode_clicked)
	btn_classic.button_clicked.connect(_on_classic_mode_clicked)
	btn_free_mode.button_clicked.connect(_on_free_mode_clicked)
	btn_resume.button_clicked.connect(_on_resume_clicked)
	btn_ranking.button_clicked.connect(_on_ranking_clicked)
	btn_options.button_clicked.connect(_on_options_clicked)
	btn_quit.button_clicked.connect(_on_quit_clicked)

	# Update translations
	update_translations()

	# Check if resume should be available
	update_resume_button()


# Show the menu
func show_menu():
	visible = true

	# Auto-save when menu opens
	SaveManager.auto_save()

	# Update resume button visibility
	update_resume_button()

	# Reload translations
	update_translations()


# Hide the menu
func hide_menu():
	visible = false


# Update all button texts with translations
func update_translations():
	btn_mania.text     = tr("MANIA_MODE")
	btn_classic.text   = tr("CLASSIC_MODE")
	btn_free_mode.text = tr("FREE_MODE")
	btn_resume.text    = tr("RESUME")
	btn_ranking.text   = tr("RANKING")
	btn_options.text   = tr("OPTIONS")
	btn_quit.text      = tr("QUIT")


# Update resume button visibility based on game_session_active
func update_resume_button():
	btn_resume.visible   = GameManager.game_session_active
	btn_resume.disabled  = not GameManager.game_session_active


# Button callbacks
func _on_mania_mode_clicked():
	print("TitleMenu: Mania Mode clicked")
	mania_mode_pressed.emit()


func _on_classic_mode_clicked():
	print("TitleMenu: Classic Mode clicked")
	classic_mode_pressed.emit()


func _on_free_mode_clicked():
	print("TitleMenu: Free Mode clicked")
	free_mode_pressed.emit()


func _on_resume_clicked():
	print("TitleMenu: Resume clicked")
	resume_pressed.emit()


func _on_ranking_clicked():
	print("TitleMenu: Ranking clicked")
	ranking_pressed.emit()


func _on_options_clicked():
	print("TitleMenu: Options clicked")
	options_pressed.emit()


func _on_quit_clicked():
	print("TitleMenu: Quit clicked")
	quit_pressed.emit()
