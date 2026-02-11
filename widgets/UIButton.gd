# UIButton - Custom button widget for Fusion Mania
# Platform-aware button with adaptive hover, click animations, and sounds
extends Button

# Signals
signal button_clicked()

# Animation scales
var hover_scale: Vector2  = Vector2(1.05, 1.05)
var normal_scale: Vector2 = Vector2.ONE
var click_scale: Vector2  = Vector2(0.95, 0.95)

# Animation durations
const HOVER_DURATION: float = 0.1
const CLICK_DURATION: float = 0.05

# Reference to text label
@onready var text_label = $TextLabel if has_node("TextLabel") else null


func _ready():
	# Set pivot for scaling animations
	pivot_offset = size / 2

	# Sync text label with button text
	if text_label:
		text_label.text = text

	# Connect signals based on platform
	connect_signals()


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
