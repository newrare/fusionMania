# TitleMenu - Main menu overlay for Fusion Mania
# Reviewed
extends CanvasLayer

# Node references (created dynamically)
var overlay_background: Panel
var menu_container: 	VBoxContainer
var logo: 				TextureRect
var buttons_container: 	VBoxContainer

var btn_mania: 		Node
var btn_classic: 	Node
var btn_free_mode: 	Node
var btn_resume: 	Node
var btn_ranking: 	Node
var btn_options: 	Node
var btn_quit: 		Node

# Constants for UI configuration
const LOGO_HEIGHT 		= 400
const SPACER_HEIGHT 	= 80
const BUTTON_SEPARATION = 25

# Signals for each button action
signal mania_mode_pressed()
signal classic_mode_pressed()
signal free_mode_pressed()
signal resume_pressed()
signal ranking_pressed()
signal options_pressed()
signal quit_pressed()


func _ready():
	# Build the entire scene hierarchy in code
	_setup_scene()

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


# Setup the entire scene hierarchy programmatically
func _setup_scene():
	# Create overlay background with svg margin (for no stretching border)
	var style_box 					= StyleBoxTexture.new()
	style_box.texture 				= load("res://assets/svg/overlay.svg")
	style_box.texture_margin_left   = 10.0
	style_box.texture_margin_top    = 10.0
	style_box.texture_margin_right  = 10.0
	style_box.texture_margin_bottom = 10.0

	overlay_background 			= Panel.new()
	overlay_background.name 	= "OverlayBackground"

	overlay_background.add_theme_stylebox_override("panel", style_box)
	#overlay_background.modulate = Color(1, 0, 0, 1)

	add_child(overlay_background)

	# Create main menu container
	menu_container 					= VBoxContainer.new()
	menu_container.name 			= "MenuContainer"
	menu_container.anchor_top 		= 0.5
	menu_container.anchor_bottom 	= 0.5
	menu_container.grow_vertical 	= Control.GROW_DIRECTION_BOTH

	add_child(menu_container)

	# Create logo
	logo 						= TextureRect.new()
	logo.texture 				= load("res://assets/images/logo.png")
	logo.name 					= "Logo"
	logo.custom_minimum_size 	= Vector2(0, LOGO_HEIGHT)

	menu_container.add_child(logo)

	# Create spacer
	var spacer1 				= Control.new()
	spacer1.name 				= "Spacer1"
	spacer1.custom_minimum_size = Vector2(0, SPACER_HEIGHT)

	menu_container.add_child(spacer1)

	# Create buttons container
	buttons_container 		= VBoxContainer.new()
	buttons_container.name 	= "ButtonsContainer"

	buttons_container.add_theme_constant_override("separation", BUTTON_SEPARATION)
	menu_container.add_child(buttons_container)

	# Create all buttons
	btn_mania 		= _create_button("BtnMania")
	btn_classic 	= _create_button("BtnClassic")
	btn_free_mode 	= _create_button("BtnFree")
	btn_resume 		= _create_button("BtnResume")
	btn_ranking 	= _create_button("BtnRanking")
	btn_options 	= _create_button("BtnOptions")
	btn_quit 		= _create_button("BtnQuit")


# Helper function to create a button instance
func _create_button(button_name: String):
	var btn		= load("res://widgets/UIButton.tscn").instantiate()
	btn.name	= button_name

	buttons_container.add_child(btn)
	return btn


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


# Update resume button visibility based on party_started
func update_resume_button():
	btn_resume.visible   = GameManager.is_party_started()
	btn_resume.disabled  = not GameManager.is_party_started()


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
