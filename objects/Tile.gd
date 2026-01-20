extends Control

# Tile constants
const TILE_SIZE    = 240
const TILE_SPACING = 20

# Tile color mapping
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

# Tile properties
var value: int         = 2
var power_type: String = ""
var grid_position: Vector2i
var is_frozen: bool    = false
var freeze_turns: int  = 0

# Visual node references
var background:  ColorRect
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


# Update tile visual appearance (color, label, icon)
func update_visual():
	# Update background color
	if background:
		background.color = TILE_COLORS.get(value, Color.WHITE)

	# Update value label
	if value_label:
		value_label.text = str(value)

	# Update power icon and label
	if power_type != "" and power_type != "empty":
		# Get power data from PowerManager
		var power_data = PowerManager.POWER_DATA.get(power_type, {})
		var power_name = power_data.get("name", power_type)
		
		# Show icon
		if power_icon:
			var icon_path = "res://assets/icons/power_%s.png" % power_type
			if ResourceLoader.exists(icon_path):
				power_icon.texture = load(icon_path)
				power_icon.visible = true
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


# Apply freeze effect (blue tint)
func apply_freeze_effect():
	is_frozen = true
	modulate  = Color(0.7, 0.7, 1.0, 1.0)


# Remove freeze effect (restore normal color)
func remove_freeze_effect():
	is_frozen = false
	modulate  = Color.WHITE


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
