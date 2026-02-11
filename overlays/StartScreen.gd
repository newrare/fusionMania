# StartScreen - Initial splash screen for Fusion Mania
# Shows logo and "press to start" message
extends CanvasLayer

# Signals
signal start_pressed()

# Node references
@onready var logo = $Logo
@onready var press_message = $PressMessage

# Input detection flag
var can_start := true

# Animation time
var time := 0.0
const BREATH_SPEED := 1.5  # Vitesse de la respiration
const BREATH_MIN_ALPHA := 0.5  # Alpha minimum
const BREATH_MAX_ALPHA := 1.0  # Alpha maximum


func _ready():
	# Listen to language changes
	LanguageManager.language_changed.connect(_on_language_changed)
	update_message()


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
	visible = true
	can_start = true
	update_message()


# Hide the start screen
func hide_screen():
	visible = false
	can_start = false


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
		# Also accept mouse click for PC testing
		_on_start_input()


# Handle start input
func _on_start_input():
	if not can_start:
		return
	
	can_start = false
	print("StartScreen: Start input detected")
	start_pressed.emit()


# Language changed callback
func _on_language_changed():
	update_message()
