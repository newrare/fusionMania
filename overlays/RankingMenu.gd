# RankingMenu - Score ranking overlay for Fusion Mania
# Reviewed
extends CanvasLayer

# Node references (created dynamically)
var overlay_background: Panel
var menu_container: 	VBoxContainer
var title_label: 		HBoxContainer
var scores_container: 	VBoxContainer
var btn_back: 			Node

# Constants
const TITLE_FONT_SIZE   	= 56
const SCORE_FONT_SIZE   	= 50
const DIVIDER_HEIGHT    	= 40
const SPACER_HEIGHT     	= 30
const BUTTON_WIDTH      	= 400
const BUTTON_HEIGHT     	= 91
const CONTAINER_SEPARATION 	= 15

# Signals
signal back_pressed()

func _ready():
	# Build scene hierarchy
	_setup_scene()

	# Initially hidden
	hide()

	# Connect button signals
	btn_back.button_clicked.connect(_on_back_clicked)

	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)


# Build scene hierarchy programmatically
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

	# Menu container
	menu_container 					= VBoxContainer.new()
	menu_container.name 			= "MenuContainer"
	menu_container.anchor_top 		= 0.5
	menu_container.anchor_bottom 	= 0.5
	menu_container.grow_vertical 	= Control.GROW_DIRECTION_BOTH

	add_child(menu_container)

	# Title row with dividers
	title_label = ToolsManager.title_row(tr("RANKING"))

	menu_container.add_child(title_label)

	# Spacer 1
	var spacer1 				= Control.new()
	spacer1.custom_minimum_size = Vector2(0, SPACER_HEIGHT)

	menu_container.add_child(spacer1)

	# Scores container
	scores_container 						= VBoxContainer.new()
	scores_container.name 					= "ScoresContainer"
	scores_container.size_flags_vertical 	= Control.SIZE_EXPAND_FILL

	scores_container.add_theme_constant_override("separation", CONTAINER_SEPARATION)

	menu_container.add_child(scores_container)

	# Spacer 2
	var spacer2 				= Control.new()
	spacer2.custom_minimum_size = Vector2(0, SPACER_HEIGHT)

	menu_container.add_child(spacer2)

	# Back button
	btn_back 						= load("res://widgets/UIButton.tscn").instantiate()
	btn_back.name 					= "BtnBack"
	btn_back.custom_minimum_size 	= Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)

	menu_container.add_child(btn_back)


# Show the menu
func show_menu():
	visible = true
	update_translations()
	display_scores()


# Hide the menu
func hide_menu():
	visible = false


# Update translations
func update_translations():
	#title_label.text = tr("RANKING")
	btn_back.text    = tr("BACK")


# Display high scores
func display_scores():
	# Clear existing scores
	for child in scores_container.get_children():
		child.queue_free()

	# Get high scores
	var high_scores = ScoreManager.get_high_scores()

	if high_scores.is_empty():
		# No scores yet
		var no_scores_label     				= ThemeManager.create_label()
		no_scores_label.text    				= tr("NO_SCORES")
		no_scores_label.horizontal_alignment 	= HORIZONTAL_ALIGNMENT_CENTER
		no_scores_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)

		scores_container.add_child(no_scores_label)
		return

	# Add score entries
	var rank = 1

	for score_data in high_scores:
		var entry = create_score_entry(rank, score_data)
		scores_container.add_child(entry)

		# Add divider between scores (not after the last one)
		if rank < high_scores.size():
			var divider = create_divider_row()
			scores_container.add_child(divider)

		rank += 1


# Create a score entry row
func create_score_entry(rank: int, score_data: Dictionary):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Rank label
	var rank_label                      = ThemeManager.create_label()
	rank_label.text                     = "%d" % rank
	rank_label.custom_minimum_size.x    = 60
	rank_label.horizontal_alignment     = HORIZONTAL_ALIGNMENT_LEFT

	rank_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)

	row.add_child(rank_label)

	# Score label
	var score_label                     = ThemeManager.create_label()
	score_label.text                    = "%d" % int(score_data.get("score", 0))
	score_label.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER

	score_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)

	row.add_child(score_label)

	# Date label (formatted)
	var date_label 	= ThemeManager.create_label()
	var date_str   	= score_data.get("date", "")
	date_label.text	= ToolsManager.format_date(date_str)

	date_label.add_theme_font_size_override("font_size", SCORE_FONT_SIZE)

	row.add_child(date_label)

	return row


# Create divider row
func create_divider_row():
	var divider_container 		= HBoxContainer.new()
	divider_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var svg_texture 		= load("res://assets/svg/divider_01.svg")

	var divider_revert 		= TextureRect.new()
	divider_revert.texture 	= svg_texture
	divider_revert.flip_h 	= true

	var divider_normal 		= TextureRect.new()
	divider_normal.texture	= svg_texture

	divider_container.add_child(divider_normal)
	divider_container.add_child(divider_revert)

	return divider_container


# Language changed callback
func _on_language_changed():
	update_translations()


# Button callback
func _on_back_clicked():
	print("RankingMenu: Back clicked")
	back_pressed.emit()
