extends Control

# Grid visual container
# Manages tile positioning and visual representation

const TILE_SIZE    = 240
const TILE_SPACING = 20
const GRID_SIZE    = 4

var cell_backgrounds: Array = []

func _ready():
	add_to_group("grid")
	
	# Set grid size
	var grid_pixel_size = get_grid_pixel_size()
	custom_minimum_size = grid_pixel_size
	size                = grid_pixel_size
	
	# Create cell backgrounds for visual grid
	create_cell_backgrounds()
	
	print("Grid visual container ready (%dx%d pixels)" % [int(grid_pixel_size.x), int(grid_pixel_size.y)])


# Create visual backgrounds for each cell
func create_cell_backgrounds():
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell = ColorRect.new()
			cell.color    = Color(0.4, 0.4, 0.45, 1.0)  # Dark gray cell
			cell.size     = Vector2(TILE_SIZE, TILE_SIZE)
			cell.position = Vector2(
				TILE_SPACING + x * (TILE_SIZE + TILE_SPACING),
				TILE_SPACING + y * (TILE_SIZE + TILE_SPACING)
			)
			# Add behind other elements
			add_child(cell)
			move_child(cell, 0)
			cell_backgrounds.append(cell)


# Add tile to grid
func add_tile(tile):
	add_child(tile)
	var screen_pos = calculate_screen_position(tile.grid_position)
	tile.position  = screen_pos


# Calculate screen position from grid position
func calculate_screen_position(grid_pos: Vector2i) -> Vector2:
	var x = TILE_SPACING + grid_pos.x * (TILE_SIZE + TILE_SPACING)
	var y = TILE_SPACING + grid_pos.y * (TILE_SIZE + TILE_SPACING)
	return Vector2(x, y)


# Get grid size (for layout calculations)
func get_grid_pixel_size() -> Vector2:
	var width  = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * TILE_SPACING
	var height = GRID_SIZE * TILE_SIZE + (GRID_SIZE + 1) * TILE_SPACING
	return Vector2(width, height)
