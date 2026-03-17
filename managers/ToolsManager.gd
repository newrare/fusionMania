# ToolsManager for Fusion Mania
# Reviewed
extends Node

var is_mobile: bool = false

func _ready():
	detect_platform()


# Detect the current platform
func detect_platform():
	var os_name = OS.get_name()
	is_mobile 	= os_name in ["Android", "iOS"]


# Get if running on mobile
func get_is_mobile():
	return is_mobile


# Format ISO datetime string to date only (YYYY-MM-DD)
func format_date(iso_date: String):
	if iso_date.is_empty():
		return ""

	var parts = iso_date.split("T")

	if parts.size() > 0:
		return parts[0]

	return iso_date


# Create a title row with dividers on both sides
func title_row(title_text: String):
	# Container
	var title_row 					= HBoxContainer.new()
	title_row.alignment 			= BoxContainer.ALIGNMENT_CENTER
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Dividers
	var divider_left 					= TextureRect.new()
	divider_left.texture 				= load("res://assets/svg/divider_02.svg")
	divider_left.custom_minimum_size 	= Vector2(100, 40)
	divider_left.stretch_mode 			= TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var divider_right 					= TextureRect.new()
	divider_right.texture 				= load("res://assets/svg/divider_02.svg")
	divider_right.custom_minimum_size 	= Vector2(100, 40)
	divider_right.stretch_mode 			= TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider_right.flip_h				= true

	# Title label
	var title_label 	= ThemeManager.create_label()
	title_label.text 	= title_text
	title_label.add_theme_font_size_override("font_size", 60)

	# Spacers
	var spacer_left 				= Control.new()
	spacer_left.custom_minimum_size = Vector2(20, 0)

	var spacer_right 				= Control.new()
	spacer_right.custom_minimum_size = Vector2(20, 0)

	# Construct
	title_row.add_child(divider_left)
	title_row.add_child(spacer_left)
	title_row.add_child(title_label)
	title_row.add_child(spacer_right)
	title_row.add_child(divider_right)

	return title_row
