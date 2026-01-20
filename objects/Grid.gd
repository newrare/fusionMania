extends Control

# Grid visual container
# Manages tile positioning and visual representation

const TILE_SIZE    = 240
const TILE_SPACING = 20

func _ready():
	add_to_group("grid")
	print("Grid visual container ready")


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
	var width  = 4 * TILE_SIZE + 5 * TILE_SPACING
	var height = 4 * TILE_SIZE + 5 * TILE_SPACING
	return Vector2(width, height)
