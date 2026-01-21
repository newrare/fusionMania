# UIEffect for Fusion Mania
# Manages visual UI effects (floating scores, power messages)
extends Node

# Reference to the parent container where effects are displayed
var effects_container: Node = null


func _ready():
	print("✨ UIEffect ready")


# Set the container where UI effects will be displayed
func set_container(container: Node):
	effects_container = container


# Show floating score above a tile position
func show_floating_score(score: int, world_position: Vector2):
	if not effects_container:
		print("⚠️ No effects container set for UIEffect")
		return

	# Create label
	var label = Label.new()
	label.text = "+%d" % score
	label.position = world_position + Vector2(120, -40)  # Centered above tile
	label.z_index = 100

	# Styling - Neon blue
	label.add_theme_color_override("font_color", Color("#00BFFF"))
	label.add_theme_color_override("font_outline_color", Color("#0080FF"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	effects_container.add_child(label)

	# Animation: move up and fade out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 80, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)


# Show power activation message at bottom of grid
func show_power_message(power_name: String, message_container: Control):
	if not message_container:
		print("⚠️ No message container provided")
		return

	# Remove any existing label
	for child in message_container.get_children():
		child.queue_free()

	# Create new label
	var label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#FFD700"))  # Gold
	label.add_theme_color_override("font_outline_color", Color("#FF8C00"))  # Dark orange
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_size_override("font_size", 32)
	label.text = "🔥 %s" % power_name

	# Set label to fill container
	label.set_anchors_preset(Control.PRESET_FULL_RECT)

	message_container.add_child(label)

	# Fade out after 5 seconds
	var tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN)
	tween.tween_callback(label.queue_free)
