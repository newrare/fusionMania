# StartScreen - Initial splash screen for Fusion Mania
# Half Reviewed
extends CanvasLayer

# Node references (created dynamically)
var logo: 			TextureRect
var press_message: 	Label

# Input detection flag
var can_start := true

# Animation time
var time 				:= 0.0
const BREATH_SPEED 		:= 1.5  # Breathing speed
const BREATH_MIN_ALPHA 	:= 0.5  # Minimum alpha
const BREATH_MAX_ALPHA 	:= 1.0  # Maximum alpha

# Layout constants
const LOGO_WIDTH       	= 1000
const LOGO_HEIGHT      	= 400
const MESSAGE_FONT_SIZE = 84

# Signals
signal start_pressed()

func _ready():
	# Build scene hierarchy
	_setup_scene()

	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)
	update_message()


# Build scene hierarchy programmatically
func _setup_scene():
	# Logo
	logo 				= TextureRect.new()
	logo.texture 		= load("res://assets/images/logo.png")
	logo.name 			= "Logo"
	logo.anchor_top 	= 0.2
	#logo.anchor_bottom 	= 0.5
	#logo.anchors_preset = Control.PRESET_CENTER_TOP
	logo.anchor_left 	= 0.5
	logo.anchor_right 	= 0.5
	#logo.anchor_bottom 	= 0.0
	#logo.offset_left 	= -LOGO_WIDTH / 2.0
	#logo.offset_top 	= 520.0
	#logo.offset_right 	= LOGO_WIDTH / 2.0
	#logo.offset_bottom 	= 920.0
	#logo.grow_horizontal= Control.GROW_DIRECTION_BOTH
	#logo.expand_mode 	= 1
	#logo.stretch_mode 	= 5

	add_child(logo)

	# Press message label
	press_message 						= ThemeManager.create_label()
	press_message.name 					= "PressMessage"
	press_message.anchors_preset 		= Control.PRESET_CENTER_TOP
	press_message.anchor_left 			= 0.5
	press_message.anchor_top 			= 0.0
	press_message.anchor_right 			= 0.5
	press_message.anchor_bottom 		= 0.0
	press_message.offset_left 			= -500.0
	press_message.offset_top 			= 1480.0
	press_message.offset_right 			= 500.0
	press_message.offset_bottom 		= 1700.0
	press_message.grow_horizontal 		= Control.GROW_DIRECTION_BOTH
	press_message.horizontal_alignment 	= HORIZONTAL_ALIGNMENT_CENTER
	press_message.vertical_alignment 	= VERTICAL_ALIGNMENT_CENTER
	press_message.autowrap_mode 		= TextServer.AUTOWRAP_WORD

	press_message.add_theme_color_override("font_color", ThemeManager.get_color("white"))
	press_message.add_theme_font_size_override("font_size", MESSAGE_FONT_SIZE)

	add_child(press_message)


# Process loop for breathing animation
func _process(delta):
	if not visible:
		return

	# Animate the press message with breathing effect
	time += delta
	var alpha = BREATH_MIN_ALPHA + (BREATH_MAX_ALPHA - BREATH_MIN_ALPHA) * (0.5 + 0.5 * sin(time * BREATH_SPEED))
	press_message.modulate.a = alpha


# Show the start screen
func show_screen():
	visible 	= true
	can_start 	= true
	update_message()


# Hide the start screen
func hide_screen():
	visible 	= false
	can_start 	= false


# Update the message based on platform
func update_message():
	if ToolsManager.get_is_mobile():
		press_message.text = tr("PRESS_SCREEN_TO_START")
	else:
		press_message.text = tr("PRESS_KEY_TO_START")


# Detect input
func _input(event):
	if not visible or not can_start:
		return

	# Check for any key press or screen touch
	if event is InputEventKey and event.pressed and not event.echo:
		_on_start_input()
	elif event is InputEventScreenTouch and event.pressed:
		_on_start_input()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_start_input()


# Handle start input
func _on_start_input():
	if not can_start:
		return

	can_start = false

	start_pressed.emit()


# Language changed callback
func _on_language_changed():
	update_message()
