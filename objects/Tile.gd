extends Control

# Tile constants
const TILE_SIZE    	= 240
const TILE_SPACING 	= 20
const BORDER_RADIUS = 20
const GLOW_SIZE 	= 8

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
var value: 			int		= 2
var power_type: 	String 	= ""
var is_iced: 		bool	= false
var ice_turns: 		int		= 0
var is_merging:		bool	= false  # True during movement phase when tile is target of a fusion
var expel_direction: String	= ""  # "h" for horizontal, "v" for vertical, "" for none
var transparency: 	float	= 1.0  # 1.0 = full opacity, 0.7 = 30% transparent for expel
var grid_position: 	Vector2i
var is_new_tile:	bool	= false  # Only true for randomly spawned tiles

# Visual node references
var background:			Control
var tile_center:		TextureRect
var tile_corner_tl:		TextureRect
var tile_corner_tr:		TextureRect
var tile_corner_bl:		TextureRect
var tile_corner_br:		TextureRect
var value_label: 		Label
var power_icon: 		TextureRect
var power_label: 		Label

# Signals
signal tile_merged(tile, merged_value: int)
signal tile_destroyed(tile)


func _ready():
	# Get child node references
	background     = $Background
	tile_center    = $Background/TileCenter
	tile_corner_tl = $Background/TileCornerTopLeft
	tile_corner_tr = $Background/TileCornerTopRight
	tile_corner_bl = $Background/TileCornerBottomLeft
	tile_corner_br = $Background/TileCornerBottomRight
	value_label    = $ValueLabel
	power_icon     = $PowerIcon
	power_label    = $PowerLabel

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
	return Color(
		neon_color.r * BACKGROUND_ATTENUATION,
		neon_color.g * BACKGROUND_ATTENUATION,
		neon_color.b * BACKGROUND_ATTENUATION,
		1.0
	)


# Apply tile textures with color modulation
func apply_tile_textures(neon_color: Color, is_visible: bool = true):
	var bg_color = get_background_color(neon_color)
	bg_color.a = transparency  # Apply tile transparency

	# Load and apply textures with same color for all parts
	if tile_center:
		tile_center.texture = load("res://assets/images/tile_center.png")
		tile_center.self_modulate = bg_color

	# Apply normal corner textures
	if tile_corner_tl:
		tile_corner_tl.texture = load("res://assets/images/tile_corner_top_left.png")
		tile_corner_tl.self_modulate = bg_color
		tile_corner_tl.visible = is_visible

	if tile_corner_tr:
		tile_corner_tr.texture = load("res://assets/images/tile_corner_top_right.png")
		tile_corner_tr.self_modulate = bg_color
		tile_corner_tr.visible = is_visible

	if tile_corner_bl:
		tile_corner_bl.texture = load("res://assets/images/tile_corner_bottom_left.png")
		tile_corner_bl.self_modulate = bg_color
		tile_corner_bl.visible = is_visible

	if tile_corner_br:
		tile_corner_br.texture = load("res://assets/images/tile_corner_bottom_right.png")
		tile_corner_br.self_modulate = bg_color
		tile_corner_br.visible = is_visible


# Apply expel-specific textures based on direction
func apply_expel_textures(direction: String, bg_color: Color):
	if direction == "":
		return

	# Update center with same color (already has transparency applied)
	if tile_center:
		tile_center.self_modulate = bg_color

	if direction == "h":
		# Horizontal expel: top and bottom edges
		if tile_corner_tl:
			tile_corner_tl.texture = load("res://assets/images/tile_top.png")
			tile_corner_tl.self_modulate = bg_color
		if tile_corner_tr:
			tile_corner_tr.texture = load("res://assets/images/tile_top.png")
			tile_corner_tr.self_modulate = bg_color
		if tile_corner_bl:
			tile_corner_bl.texture = load("res://assets/images/tile_bottom.png")
			tile_corner_bl.self_modulate = bg_color
		if tile_corner_br:
			tile_corner_br.texture = load("res://assets/images/tile_bottom.png")
			tile_corner_br.self_modulate = bg_color

	elif direction == "v":
		# Vertical expel: left and right edges
		if tile_corner_tl:
			tile_corner_tl.texture = load("res://assets/images/tile_left.png")
			tile_corner_tl.self_modulate = bg_color
		if tile_corner_tr:
			tile_corner_tr.texture = load("res://assets/images/tile_right.png")
			tile_corner_tr.self_modulate = bg_color
		if tile_corner_bl:
			tile_corner_bl.texture = load("res://assets/images/tile_left.png")
			tile_corner_bl.self_modulate = bg_color
		if tile_corner_br:
			tile_corner_br.texture = load("res://assets/images/tile_right.png")
			tile_corner_br.self_modulate = bg_color


# Update tile visual appearance (color, label, icon)
func update_visual():
	var neon_color = TILE_COLORS.get(value, Color.WHITE)

	# Transparency is always full opacity
	transparency = 1.0

	# Calculate background color with transparency
	var bg_color = get_background_color(neon_color)
	bg_color.a = transparency

	# Update background with tile textures
	if background:
		apply_tile_textures(neon_color, not is_new_tile)
		# Apply expel textures if needed (using same bg_color)
		if expel_direction != "":
			apply_expel_textures(expel_direction, bg_color)

	# Update value label with scaled font size and neon color
	if value_label:
		value_label.text 	= str(value)
		var font_size 		= VALUE_FONT_SIZES.get(value, 48)
		value_label.add_theme_font_size_override("font_size", font_size)
		value_label.add_theme_color_override("font_color", neon_color)

	# Update power icon and label
	if power_type != "" and power_type != "empty":
		var power 				= PowerManager.POWERS.get(power_type, {})
		var power_name 			= power.get("name", power_type)
		var power_type_category = power.get("type", "none")

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
			power_label.text 	= power_name
			power_label.visible = true
	else:
		# Hide power elements if no power or empty power
		if power_icon:
			power_icon.visible = false
		if power_label:
			power_label.visible = false


# Check if tile can merge with another tile
func can_merge_with(other_tile):
	# Cannot merge if either tile is iced or already merging this turn
	if is_iced or other_tile.is_iced:
		return false
	if is_merging or other_tile.is_merging:
		return false
	return value == other_tile.value


# Merge with another tile and return merge result
func merge_with(other_tile):
	# Double value
	var new_value = value * 2

	# Determine power to keep
	var new_power = PowerManager.resolve_power_merge(power_type, other_tile.power_type)

	# Check if power should be activated
	var power_activated = (power_type == other_tile.power_type and power_type != "")

	# Reset expel state when merging (fusion cancels expel effect)
	var expel_was_active = (expel_direction != "" or other_tile.expel_direction != "")
	expel_direction = ""  # Cancel expel effect on fusion
	if expel_was_active:
		print("  ✨ Fusion cancels expel effect")
		# Restore original corner textures by calling update_visual
		call_deferred("update_visual")

	# Return merge result
	return {
		"value":           new_value,
		"power":           new_power,
		"power_activated": power_activated
	}


# Spawn animation (scale from 0 to 1)
func spawn_animation():
	scale 		= Vector2.ZERO
	var tween 	= create_tween()

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
	var from_pos 	= grid_position
	var tween 		= create_tween()

	tween.tween_property(self, "position", target_pos, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	return tween


# Destroy animation (fade out and scale down)
func destroy_animation():
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)

	tween.tween_callback(func():
		emit_signal("tile_destroyed", self)
		queue_free()
	)


# Set iced state with number of turns
func set_iced(iced: bool, turns: int = 0):
	is_iced 		= iced
	ice_turns 	= turns

	if iced:
		apply_ice_effect()
	else:
		remove_ice_effect()


# Apply ice effect on tile
func apply_ice_effect():
	is_iced = true

	# Remove any existing ice overlay first
	var existing_ice = get_node_or_null("IceOverlay")

	if existing_ice:
		existing_ice.queue_free()
		await get_tree().process_frame  # Wait for queue_free to process

	# Load and apply ice tile texture as overlay ON TOP of tile
	var ice_texture = load("res://assets/images/ice_tile.jpg")

	if ice_texture != null:
		var ice_overlay 				= TextureRect.new()
		ice_overlay.texture 			= ice_texture
		ice_overlay.expand_mode 		= TextureRect.EXPAND_IGNORE_SIZE
		ice_overlay.stretch_mode 		= TextureRect.STRETCH_SCALE
		ice_overlay.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		ice_overlay.size 				= Vector2(TILE_SIZE, TILE_SIZE)
		ice_overlay.position 			= Vector2.ZERO
		ice_overlay.name 				= "IceOverlay"
		ice_overlay.modulate 			= Color(1, 1, 1, 0.9)  # 90% visible
		ice_overlay.mouse_filter 		= Control.MOUSE_FILTER_IGNORE

		# Add ON TOP of all other elements
		add_child(ice_overlay)

# Remove ice effect (fade out ice overlay)
func remove_ice_effect():
	is_iced = false

	# Find and fade out ice overlay
	var ice_overlay = get_node_or_null("IceOverlay")

	if ice_overlay != null:
		var tween = create_tween()
		tween.tween_property(ice_overlay, "modulate:a", 0.0, 0.5)
		tween.tween_callback(ice_overlay.queue_free)


# ============================
# Power Visual Effect Methods
# ============================

var _emitter_tween: Tween = null
var _target_tween: Tween = null

# Start emitter visual effect (blue label + blinking power icon)
func start_emitter_effect(duration: float = 2.0):
	stop_emitter_effect()  # Clean up any existing effect

	var has_label = value_label != null
	var has_icon = power_icon != null and power_icon.visible

	# Check if we have anything to animate
	if not has_label and not has_icon:
		return

	_emitter_tween = create_tween()

	# Change value label to blue (sequential animation)
	if has_label:
		var original_color = value_label.modulate
		_emitter_tween.tween_property(value_label, "modulate", Color(0.3, 0.5, 1, 1), 0.1)
		_emitter_tween.tween_interval(max(0.0, duration - 0.2))
		_emitter_tween.tween_property(value_label, "modulate", original_color, 0.1)

	# Blink power icon by scaling
	if has_icon:
		var original_scale = power_icon.scale
		var blink_count = max(1, int(duration / 0.2))

		for i in range(blink_count):
			if has_label:
				# Run parallel to label animation
				_emitter_tween.parallel().tween_property(power_icon, "scale", original_scale * 1.3, 0.1).set_delay(i * 0.2)
				_emitter_tween.parallel().tween_property(power_icon, "scale", original_scale, 0.1).set_delay(i * 0.2 + 0.1)
			else:
				# No label, so just add tweeners sequentially with delays
				_emitter_tween.tween_property(power_icon, "scale", original_scale * 1.3, 0.1).set_delay(i * 0.2)
				_emitter_tween.tween_property(power_icon, "scale", original_scale, 0.1).set_delay(i * 0.2 + 0.1)


# Stop emitter visual effect immediately
func stop_emitter_effect():
	if _emitter_tween != null and _emitter_tween.is_valid():
		_emitter_tween.kill()
		_emitter_tween = null

	# Reset to original state
	if value_label:
		value_label.modulate = Color.WHITE
	if power_icon and power_icon.visible:
		power_icon.scale = Vector2.ONE


# Start target visual effect (blink/flash the entire tile)
func start_target_effect(duration: float = 2.0):
	stop_target_effect()  # Clean up any existing effect

	_target_tween = create_tween()
	var blink_count = int(duration / 0.2)

	for i in range(blink_count):
		_target_tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
		_target_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

	_target_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.0)


# Stop target visual effect immediately
func stop_target_effect():
	if _target_tween != null and _target_tween.is_valid():
		_target_tween.kill()
		_target_tween = null

	# Reset to original state - always full opacity on tile itself
	modulate = Color(1.0, 1.0, 1.0, 1.0)


# Stop all power visual effects
func stop_all_power_effects():
	stop_emitter_effect()
	stop_target_effect()


# Debug string representation
func _to_string():
	return "Tile[value=%d, power=%s, pos=%s, iced=%s]" % [
		value, power_type, grid_position, is_iced
	]
