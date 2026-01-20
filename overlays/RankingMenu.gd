# RankingMenu - Score ranking overlay for Fusion Mania
# Displays top 10 scores with back button
extends CanvasLayer

# Signals
signal back_pressed()

# Node references
@onready var overlay_background = $OverlayBackground
@onready var menu_container     = $MenuContainer
@onready var title_label        = $MenuContainer/TitleLabel
@onready var scores_container   = $MenuContainer/ScoresContainer
@onready var btn_back           = $MenuContainer/BtnBack


func _ready():
	# Initially hidden
	hide()

	# Connect button signals
	btn_back.button_clicked.connect(_on_back_clicked)

	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)


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
	title_label.text = tr("RANKING")
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
		var no_scores_label     = Label.new()
		no_scores_label.text    = tr("NO_SCORES")
		no_scores_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		scores_container.add_child(no_scores_label)
		return

	# Add score entries
	var rank = 1
	for score_data in high_scores:
		var entry = create_score_entry(rank, score_data)
		scores_container.add_child(entry)
		rank += 1


# Create a score entry row
func create_score_entry(rank: int, score_data: Dictionary):
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Rank label
	var rank_label                      = Label.new()
	rank_label.text                     = "#%d" % rank
	rank_label.custom_minimum_size.x    = 60
	rank_label.horizontal_alignment     = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(rank_label)

	# Score label
	var score_label                     = Label.new()
	score_label.text                    = str(score_data.get("score", 0))
	score_label.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	score_label.horizontal_alignment    = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(score_label)

	# Date label (formatted)
	var date_label                      = Label.new()
	var date_str                        = score_data.get("date", "")
	date_label.text                     = format_date(date_str)
	date_label.custom_minimum_size.x    = 100
	date_label.horizontal_alignment     = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(date_label)

	return row


# Format date for display
func format_date(iso_date: String):
	if iso_date.is_empty():
		return ""

	# Extract date part (YYYY-MM-DD)
	var parts = iso_date.split("T")

	if parts.size() > 0:
		return parts[0]

	return iso_date


# Language changed callback
func _on_language_changed():
	update_translations()


# Button callback
func _on_back_clicked():
	print("RankingMenu: Back clicked")
	back_pressed.emit()
