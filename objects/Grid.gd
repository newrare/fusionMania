extends Control

# Grid visual container
# Manages tile positioning and visual representation

const TILE_SIZE    = 240
const TILE_SPACING = 20
const GRID_SIZE    = 4

var cell_backgrounds: Array = []
var background: ColorRect

func _ready():
	add_to_group("grid")

	# Configure Grid layout
	layout_mode = 3
	anchors_preset = 0
	offset_right = 1060.0
	offset_bottom = 1060.0

	# Build scene hierarchy
	_setup_scene()

	# Disable clipping to allow tiles to move outside grid bounds
	clip_contents = false

	# Set grid size
	var grid_pixel_size = get_grid_pixel_size()
	custom_minimum_size = grid_pixel_size
	size                = grid_pixel_size

	# Create cell backgrounds for visual grid
	create_cell_backgrounds()

	print("Grid visual container ready (%dx%d pixels)" % [int(grid_pixel_size.x), int(grid_pixel_size.y)])


# Build scene hierarchy programmatically
func _setup_scene():
	# Background
	background = ColorRect.new()
	background.name = "Background"
	background.layout_mode = 1
	background.anchors_preset = Control.PRESET_FULL_RECT
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.grow_horizontal = Control.GROW_DIRECTION_BOTH
	background.grow_vertical = Control.GROW_DIRECTION_BOTH
	background.color = Color(0.25, 0.25, 0.3, 1)
	add_child(background)
	move_child(background, 0)


# Create visual backgrounds for each cell
func create_cell_backgrounds():
	# Load texture for grid cells
	var grid_texture = load("res://assets/svg/texture_grid.svg")

	# Create StyleBoxTexture with 9-slice
	var style_box = StyleBoxTexture.new()
	style_box.texture              = grid_texture
	style_box.texture_margin_left   = 20.0
	style_box.texture_margin_top    = 20.0
	style_box.texture_margin_right  = 20.0
	style_box.texture_margin_bottom = 20.0
	style_box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style_box.axis_stretch_vertical   = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell = Panel.new()
			cell.add_theme_stylebox_override("panel", style_box)
			cell.modulate = Color(1, 1, 1, 0.5)  # 50% transparency
			cell.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			cell.size          = Vector2(TILE_SIZE, TILE_SIZE)
			cell.position      = Vector2(
				TILE_SPACING + x * (TILE_SIZE + TILE_SPACING),
				TILE_SPACING + y * (TILE_SIZE + TILE_SPACING)
			)
			# Add behind other elements
			add_child(cell)
			move_child(cell, 0)
			cell_backgrounds.append(cell)


# Get grid size (for layout calculations)
func get_grid_pixel_size():
	var width  = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * TILE_SPACING
	var height = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * TILE_SPACING
	return Vector2(width, height)


# Add tile to grid
func add_tile(tile):
	add_child(tile)
	var screen_pos = calculate_screen_position(tile.grid_position)
	tile.position  = screen_pos


# Calculate screen position from grid position
func calculate_screen_position(grid_pos: Vector2i):
	var x = TILE_SPACING + grid_pos.x * (TILE_SIZE + TILE_SPACING)
	var y = TILE_SPACING + grid_pos.y * (TILE_SIZE + TILE_SPACING)
	return Vector2(x, y)


# Clear all tiles from the grid
func clear_all_tiles():
	# Remove all children that are tiles (not cell backgrounds)
	var tiles_to_remove = []
	for child in get_children():
		if child not in cell_backgrounds:
			tiles_to_remove.append(child)

	# Free them immediately
	for tile in tiles_to_remove:
		tile.free()  # Use free() instead of queue_free() for immediate removal

	print("🧹 Grid cleared of %d tiles" % tiles_to_remove.size())
