# UIButton - Custom button widget for Fusion Mania
# Reviewed
extends Button


# Animation scales
var hover_scale: 	Vector2 = Vector2(1.05, 1.05)
var click_scale: 	Vector2 = Vector2(0.95, 0.95)
var normal_scale: 	Vector2 = Vector2.ONE

# Animation durations
const BUTTON_WIDTH: 	int 	= 400
const BUTTON_HEIGHT: 	int 	= 150
const FONT_SIZE: 		int 	= 60
const HOVER_DURATION: 	float 	= 0.1
const CLICK_DURATION: 	float 	= 0.05

# Reference to text label (created dynamically)
var text_label: Label

# Signals
signal button_clicked()

func _ready():
	# Build scene hierarchy
	_setup_scene()

	# Set pivot for scaling animations
	pivot_offset = size / 2

	# Sync text label with button text
	if text_label:
		text_label.text = text

	# Connect signals based on platform
	connect_signals()


# Build scene hierarchy programmatically
func _setup_scene():
	# Dimensions
	custom_minimum_size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)

	# Create button styles programmatically
	var margin = 20.0

	var style_normal 					= StyleBoxTexture.new()
	style_normal.texture 				= load("res://assets/svg/button_classic.svg")
	style_normal.texture_margin_left   	= margin
	style_normal.texture_margin_top    	= margin
	style_normal.texture_margin_right  	= margin
	style_normal.texture_margin_bottom 	= margin

	var style_select 					= StyleBoxTexture.new()
	style_select.texture 				= load("res://assets/svg/button_select.svg")
	style_select.texture_margin_left   	= margin
	style_select.texture_margin_top    	= margin
	style_select.texture_margin_right  	= margin
	style_select.texture_margin_bottom 	= margin

	# Apply button styles
	add_theme_stylebox_override("normal",	style_normal)
	add_theme_stylebox_override("hover", 	style_select)
	add_theme_stylebox_override("pressed", 	style_normal)

	# Text colors
	add_theme_color_override("font_color", 			ThemeManager.get_color("title"))
	add_theme_color_override("font_hover_color", 	ThemeManager.get_color("hover"))
	add_theme_color_override("font_pressed_color", 	ThemeManager.get_color("white"))

	# Font (Button extends Control, so use apply_font)
	ThemeManager.apply_font(self)
	add_theme_font_size_override("font_size", FONT_SIZE)


# Update text label when button text changes
func _set(property, value):
	if property == "text" and text_label:
		text_label.text = value

	return false


# Connect appropriate signals based on platform
func connect_signals():
	if not ToolsManager.get_is_mobile():
		# PC: hover effects enabled
		mouse_entered.connect(_on_hover_start)
		mouse_exited.connect(_on_hover_end)

	# All platforms: click
	pressed.connect(_on_clicked)


# Hover start (PC only)
func _on_hover_start():
	AudioManager.play_sfx_button_hover()

	# Scale up animation
	var tween = create_tween()

	tween.tween_property(self, "scale", hover_scale, HOVER_DURATION)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	# Counter-scale text to keep it crisp
	if text_label:
		var text_tween = create_tween()

		text_tween.tween_property(text_label, "scale", Vector2.ONE / hover_scale, HOVER_DURATION)
		text_tween.set_ease(Tween.EASE_OUT)
		text_tween.set_trans(Tween.TRANS_BACK)


# Hover end (PC only)
func _on_hover_end():
	# Scale back to normal
	var tween = create_tween()

	tween.tween_property(self, "scale", normal_scale, HOVER_DURATION)
	tween.set_ease(Tween.EASE_OUT)

	# Reset text scale
	if text_label:
		var text_tween = create_tween()

		text_tween.tween_property(text_label, "scale", Vector2.ONE, HOVER_DURATION)
		text_tween.set_ease(Tween.EASE_OUT)


# Button clicked (all platforms)
func _on_clicked():
	AudioManager.play_sfx_button_click()

	# Click animation (scale down then back)
	var tween = create_tween()

	tween.tween_property(self, "scale", click_scale, CLICK_DURATION)
	tween.tween_property(self, "scale", normal_scale, CLICK_DURATION)

	# Counter-scale text during click
	if text_label:
		var text_tween = create_tween()

		text_tween.tween_property(text_label, "scale", Vector2.ONE / click_scale, CLICK_DURATION)
		text_tween.tween_property(text_label, "scale", Vector2.ONE, CLICK_DURATION)

	# Emit custom signal
	button_clicked.emit()


# Manually trigger click (for programmatic clicks)
func trigger_click():
	_on_clicked()
