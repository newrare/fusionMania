# ThemeManager for Fusion Mania
# Reviewed
extends Node

# Global theme
var global_theme: Theme

# Color constants
const COLOR_TITLE 		= Color(0.78, 0.92, 0.92, 1)  	# #C7EBEB (title, link, action)
const COLOR_HOVER 		= Color(0.23, 0.13, 0.33, 1)  	# #3B2155 (hover)
const COLOR_CLICK 		= Color(0.1, 0, 0, 1)         	# #100000 (click)
const COLOR_WHITE 		= Color(1, 1, 1, 1)           	# #FFFFFF (white)
const COLOR_BLACK 		= Color(0, 0, 0, 1)           	# #000000 (black)

# Level colors (tile values)
const COLOR_LEVEL_2 	= Color(1, 1, 1, 1)         	# #FFFFFF (White)
const COLOR_LEVEL_4 	= Color(0.85, 0.85, 0.85, 1)	# #D9D9D9 (Light Gray)
const COLOR_LEVEL_8 	= Color(0, 1, 0, 1)         	# #00FF00 (Green)
const COLOR_LEVEL_16 	= Color(0.43, 0.62, 0.92, 1)	# #6D9EEB (Blue)
const COLOR_LEVEL_32 	= Color(1, 0.90, 0.60, 1)   	# #FFE599 (Light Yellow)
const COLOR_LEVEL_64 	= Color(0.90, 0.57, 0.22, 1)	# #E69138 (Orange)
const COLOR_LEVEL_128 	= Color(1, 0, 1, 1)         	# #FF00FF (Magenta)
const COLOR_LEVEL_256 	= Color(0.78, 0.04, 0.78, 1)	# #C809C8 (Purple)
const COLOR_LEVEL_512 	= Color(0.61, 0.03, 0.61, 1)	# #9C079C (Dark Purple)
const COLOR_LEVEL_1024 	= Color(0.44, 0.02, 0.44, 1)	# #700570 (Darker Purple)
const COLOR_LEVEL_2048 	= Color(0.27, 0.01, 0.27, 1)	# #440344 (Deep Purple)

# Viewport design constants
const GAME_WIDTH      = 1080.0
const GAME_HEIGHT     = 1920.0
const GAME_WIDTH_MIN  = 540.0
const GAME_HEIGHT_MIN = 960.0

# Create and configure global theme
func _ready():
	setup_global_theme()


# Setup the global theme with font and colors
func setup_global_theme():
	global_theme = Theme.new()

	# Load and set default font
	var default_font = load("res://assets/others/font_super_crawler.ttf") as FontFile

	if default_font:
		# Set as default font for the entire theme
		global_theme.default_font = default_font

		# Also set font for specific control types to ensure it applies
		global_theme.set_font("font", 			"Label", 			default_font)
		global_theme.set_font("font", 			"Button", 			default_font)
		global_theme.set_font("font", 			"LineEdit", 		default_font)
		global_theme.set_font("font", 			"TextEdit", 		default_font)
		global_theme.set_font("normal_font", 	"RichTextLabel", 	default_font)

	# Set global colors (can be accessed via get_theme_color)
	global_theme.set_color("title", "Global", COLOR_TITLE)
	global_theme.set_color("hover", "Global", COLOR_HOVER)
	global_theme.set_color("click", "Global", COLOR_CLICK)
	global_theme.set_color("white", "Global", COLOR_WHITE)

	# Level colors
	global_theme.set_color("level_2", 		"Global", COLOR_LEVEL_2)
	global_theme.set_color("level_4", 		"Global", COLOR_LEVEL_4)
	global_theme.set_color("level_8", 		"Global", COLOR_LEVEL_8)
	global_theme.set_color("level_16", 		"Global", COLOR_LEVEL_16)
	global_theme.set_color("level_32", 		"Global", COLOR_LEVEL_32)
	global_theme.set_color("level_64", 		"Global", COLOR_LEVEL_64)
	global_theme.set_color("level_128", 	"Global", COLOR_LEVEL_128)
	global_theme.set_color("level_256", 	"Global", COLOR_LEVEL_256)
	global_theme.set_color("level_512", 	"Global", COLOR_LEVEL_512)
	global_theme.set_color("level_1024", 	"Global", COLOR_LEVEL_1024)
	global_theme.set_color("level_2048", 	"Global", COLOR_LEVEL_2048)

	# Apply theme to root
	get_tree().root.theme = global_theme


# Get a level color by tile value
func get_level_color(value: int):
	match value:
		2:    return COLOR_LEVEL_2
		4:    return COLOR_LEVEL_4
		8:    return COLOR_LEVEL_8
		16:   return COLOR_LEVEL_16
		32:   return COLOR_LEVEL_32
		64:   return COLOR_LEVEL_64
		128:  return COLOR_LEVEL_128
		256:  return COLOR_LEVEL_256
		512:  return COLOR_LEVEL_512
		1024: return COLOR_LEVEL_1024
		2048: return COLOR_LEVEL_2048
		_:    return COLOR_WHITE


# Get theme color by name
func get_color(color_name: String):
	match color_name:
		"title": return COLOR_TITLE
		"hover": return COLOR_HOVER
		"click": return COLOR_CLICK
		"white": return COLOR_WHITE
		"black": return COLOR_BLACK
		_:       return COLOR_WHITE


# Factory methods to create Controls with font already applied
func create_label():
	var label = Label.new()

	if global_theme and global_theme.default_font:
		label.add_theme_font_override("font", global_theme.default_font)

	return label


func create_button():
	var button = Button.new()

	if global_theme and global_theme.default_font:
		button.add_theme_font_override("font", global_theme.default_font)

	return button


func create_rich_text_label():
	var rtl = RichTextLabel.new()

	if global_theme and global_theme.default_font:
		rtl.add_theme_font_override("normal_font", global_theme.default_font)

	return rtl


# Legacy method for backward compatibility
func apply_font(control: Control):
	if global_theme and global_theme.default_font:
		if control is RichTextLabel:
			control.add_theme_font_override("normal_font", global_theme.default_font)
		else:
			control.add_theme_font_override("font", global_theme.default_font)
