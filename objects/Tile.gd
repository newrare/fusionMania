extends Control

# Tile constants
const TILE_SIZE    = 240
const TILE_SPACING = 20
const BORDER_RADIUS = 20
const GLOW_SIZE = 8

# Tile neon color mapping (for glow border)
const TILE_COLORS = {
	2:    Color("#FFFFFF"),  # White
	4:    Color("#D9D9D9"),  # Light Gray
	8:    Color("#00FF00"),  # Green
	16:   Color("#6D9EEB"),  # Blue
	32:   Color("#FFE599"),  # Light Yellow
	64:   Color("#E69138"),  # Orange
	128:  Color("#FF00FF"),  # Magenta
	256:  Color("#C809C8"),  # Purple
	512:  Color("#9C079C"),  # Dark Purple
	1024: Color("#700570"),  # Darker Purple
	2048: Color("#440344")   # Deep Purple
}

# Background attenuation factor (lighter to reflect neon glow)
const BACKGROUND_ATTENUATION = 0.75

# Font sizes for each tile value (increases with value doubling)
const VALUE_FONT_SIZES = {
	2:    48,
	4:    52,
	8:    56,
	16:   60,
	32:   64,
	64:   68,
	128:  56,   # 3 digits - slightly smaller to fit
	256:  56,
	512:  56,
	1024: 48,   # 4 digits - smaller to fit
	2048: 48
}

# Power icon colors
const BONUS_COLOR = Color("#00FF00")  # Green for bonus
const MALUS_COLOR = Color("#FF0000")  # Red for malus

# Tile properties
var value: int         = 2
var power_type: String = ""
var grid_position: Vector2i
var is_frozen: bool    = false
var freeze_turns: int  = 0

# Visual node references
var background:  Panel
var value_label: Label
var power_icon:  TextureRect
var power_label: Label

# Signals
signal tile_clicked(tile)
signal tile_moved(from: Vector2i, to: Vector2i)
signal tile_merged(tile, merged_value: int)
signal tile_destroyed(tile)


func _ready():
	# Get child node references
	background  = $Background
	value_label = $ValueLabel
	power_icon  = $PowerIcon
	power_label = $PowerLabel

	# Ensure visual is updated after nodes are ready
	update_visual()


# Initialize tile with value, power, and grid position
func initialize(val: int, power: String = "", grid_pos: Vector2i = Vector2i.ZERO):
	value         = val
	power_type    = power
	grid_position = grid_pos

	# Defer visual update to next frame to ensure nodes are ready
	call_deferred("update_visual")
	spawn_animation()


# Create attenuated background color from neon color
func get_background_color(neon_color: Color):
	# Create a very dark version of the neon color
	return Color(
		neon_color.r * BACKGROUND_ATTENUATION,
		neon_color.g * BACKGROUND_ATTENUATION,
		neon_color.b * BACKGROUND_ATTENUATION,
		1.0
	)


# Create StyleBoxFlat with neon glow effect
func create_neon_style(neon_color: Color):
	var style = StyleBoxFlat.new()

	# Background color (very attenuated neon)
	style.bg_color = get_background_color(neon_color)

	# Rounded corners
	style.corner_radius_top_left = BORDER_RADIUS
	style.corner_radius_top_right = BORDER_RADIUS
	style.corner_radius_bottom_left = BORDER_RADIUS
	style.corner_radius_bottom_right = BORDER_RADIUS

	# Neon border
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = neon_color

	# Glow effect using shadow
	style.shadow_color = Color(neon_color.r, neon_color.g, neon_color.b, 0.8)
	style.shadow_size = GLOW_SIZE
	style.shadow_offset = Vector2.ZERO

	return style


# Update tile visual appearance (color, label, icon)
func update_visual():
	var neon_color = TILE_COLORS.get(value, Color.WHITE)

	# Update background with neon style
	if background:
		background.add_theme_stylebox_override("panel", create_neon_style(neon_color))

	# Update value label with scaled font size
	if value_label:
		value_label.text = str(value)
		var font_size = VALUE_FONT_SIZES.get(value, 48)
		value_label.add_theme_font_size_override("font_size", font_size)

	# Update power icon and label
	if power_type != "" and power_type != "empty":
		# Get power data from PowerManager
		var power_data = PowerManager.POWER_DATA.get(power_type, {})
		var power_name = power_data.get("name", power_type)
		var power_type_category = power_data.get("type", "none")

		# Show SVG icon
		if power_icon:
			var icon_path = "res://assets/icons/power_%s.svg" % power_type
			if ResourceLoader.exists(icon_path):
				power_icon.texture = load(icon_path)
				power_icon.visible = true

				# Determine color based on bonus/malus
				var icon_color = Color.WHITE
				if power_type_category == "bonus":
					icon_color = BONUS_COLOR
				elif power_type_category == "malus":
					icon_color = MALUS_COLOR

				# Create shader material to apply color tint to SVG
				var shader_material = ShaderMaterial.new()
				var shader = Shader.new()
				shader.code = """
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Apply tint while preserving alpha
	COLOR = vec4(tint_color.rgb, tex.a);
}
"""
				shader_material.shader = shader
				shader_material.set_shader_parameter("tint_color", icon_color)
				power_icon.material = shader_material
			else:
				power_icon.visible = false

		# Show power name label
		if power_label:
			power_label.text = power_name
			power_label.visible = true
	else:
		# Hide power elements if no power or empty power
		if power_icon:
			power_icon.visible = false
		if power_label:
			power_label.visible = false


# Check if tile can merge with another tile
func can_merge_with(other_tile) -> bool:
	return value == other_tile.value and not is_frozen and not other_tile.is_frozen


# Merge with another tile and return merge result
func merge_with(other_tile):
	# Double value
	var new_value = value * 2

	# Determine power to keep
	var new_power = PowerManager.resolve_power_merge(power_type, other_tile.power_type)

	# Check if power should be activated
	var power_activated = (power_type == other_tile.power_type and power_type != "")

	# Return merge result
	return {
		"value":           new_value,
		"power":           new_power,
		"power_activated": power_activated
	}


# Calculate screen position from grid position
func calculate_screen_position(grid_pos: Vector2i) -> Vector2:
	var x = TILE_SPACING + grid_pos.x * (TILE_SIZE + TILE_SPACING)
	var y = TILE_SPACING + grid_pos.y * (TILE_SIZE + TILE_SPACING)
	return Vector2(x, y)


# Spawn animation (scale from 0 to 1)
func spawn_animation():
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)


# Merge animation (scale up then down)
func merge_animation():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

	emit_signal("tile_merged", self, value)


# Move to target position with animation
func move_to_position(target_pos: Vector2, duration: float = 0.2):
	var from_pos = grid_position

	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)


# Destroy animation (fade out and scale down)
func destroy_animation():
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_callback(func():
		emit_signal("tile_destroyed", self)
		queue_free()
	)


# Set frozen state with number of turns
func set_frozen(frozen: bool, turns: int = 0):
	is_frozen = frozen
	freeze_turns = turns
	if frozen:
		apply_freeze_effect()
	else:
		remove_freeze_effect()


# Apply freeze effect (ice tile overlay on top)
func apply_freeze_effect():
	is_frozen = true

	# Remove any existing ice overlay first
	var existing_ice = get_node_or_null("IceOverlay")
	if existing_ice:
		existing_ice.queue_free()
		await get_tree().process_frame  # Wait for queue_free to process

	# Load and apply ice tile texture as overlay ON TOP of tile
	var ice_texture = load("res://assets/images/ice_tile.jpg")
	if ice_texture != null:
		# Create a TextureRect for the ice overlay
		var ice_overlay = TextureRect.new()
		ice_overlay.texture = ice_texture
		ice_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ice_overlay.stretch_mode = TextureRect.STRETCH_SCALE
		ice_overlay.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		ice_overlay.size = Vector2(TILE_SIZE, TILE_SIZE)
		ice_overlay.position = Vector2.ZERO
		ice_overlay.name = "IceOverlay"
		ice_overlay.modulate = Color(1, 1, 1, 0.9)  # 90% visible
		ice_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Add ON TOP of all other elements
		add_child(ice_overlay)

		print("✅ Ice overlay applied on top of tile at ", grid_position)
	else:
		print("⚠️ Ice tile texture not found")


# Remove freeze effect (fade out ice overlay)
func remove_freeze_effect():
	is_frozen = false

	# Find and fade out ice overlay
	var ice_overlay = get_node_or_null("IceOverlay")
	if ice_overlay != null:
		var tween = create_tween()
		tween.tween_property(ice_overlay, "modulate:a", 0.0, 0.3)
		tween.tween_callback(ice_overlay.queue_free)


# Decrease freeze counter and remove effect if needed
func decrease_freeze_turns():
	if freeze_turns > 0:
		freeze_turns -= 1
		if freeze_turns == 0:
			remove_freeze_effect()


# Debug string representation
func _to_string() -> String:
	return "Tile[value=%d, power=%s, pos=%s, frozen=%s]" % [
		value, power_type, grid_position, is_frozen
	]
