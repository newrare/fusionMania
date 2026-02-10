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


# Show floating damage above enemy position
func show_floating_damage(damage: int, world_position: Vector2):
	if not effects_container:
		print("⚠️ No effects container set for UIEffect")
		return

	# Create label
	var label = Label.new()
	label.text = "-%d" % damage
	label.position = world_position + Vector2(120, -40)  # Centered above position
	label.z_index = 100

	# Styling - Red damage text
	label.add_theme_color_override("font_color", Color("#FF4444"))
	label.add_theme_color_override("font_outline_color", Color("#AA0000"))
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


# Show power activation message
func show_power_message(power_name: String, world_position: Vector2):
	if not effects_container:
		print("⚠️ No effects container set for UIEffect")
		return

	# Create label
	var label = Label.new()
	label.text = power_name.to_upper()
	label.position = world_position + Vector2(120, -60)  # Above tile
	label.z_index = 100

	# Styling - Power text
	label.add_theme_color_override("font_color", Color("#FFD700"))
	label.add_theme_color_override("font_outline_color", Color("#FF8C00"))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 32)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	effects_container.add_child(label)

	# Animation: scale up then fade out
	label.scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(label, "position:y", label.position.y - 40, 1.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD).set_delay(0.5)
	tween.set_parallel(false)
	tween.tween_callback(label.queue_free)
