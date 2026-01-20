# GridManager for Fusion Mania
# Manages the 4x4 grid, tile movements, and fusion logic
extends Node

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var grid: Array[Array]				= []
var grid_size: int					= 4
var can_move: bool					= true
var move_count: int					= 0
var blocked_directions: Array		= []

# Signals
signal tile_spawned(tile, position: Vector2i)
signal movement_completed(direction: Direction)
signal fusion_occurred(tile1, tile2, new_tile)
signal no_moves_available()
signal game_over()

func _ready():
	print("🎯 GridManager ready")


# Initialize empty grid
func initialize_grid():
	grid = []
	for y in range(grid_size):
		var row = []
		for x in range(grid_size):
			row.append(null)
		grid.append(row)

	print("Grid initialized (%dx%d)" % [grid_size, grid_size])


# Start a new game
func start_new_game():
	initialize_grid()
	move_count = 0
	blocked_directions.clear()

	# TODO: Spawn initial tiles when Tile system is ready
	print("New game started")


# Get empty cells in the grid
func get_empty_cells() -> Array:
	var empty = []
	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] == null:
				empty.append(Vector2i(x, y))
	return empty


# Get tile at position
func get_tile_at(position: Vector2i):
	if position.x < 0 or position.x >= grid_size:
		return null
	if position.y < 0 or position.y >= grid_size:
		return null
	return grid[position.y][position.x]


# Check if there are valid moves
func has_valid_moves() -> bool:
	# Check for empty cells
	if not get_empty_cells().is_empty():
		return true

	# TODO: Check for possible fusions when Tile system is ready

	return false


# Process movement (placeholder)
func process_movement(direction: Direction):
	if not can_move:
		return

	# Check if direction is blocked
	if direction in blocked_directions:
		print("Direction blocked by freeze power!")
		return

	# TODO: Implement movement logic when Tile system is ready
	print("Movement requested: %s" % Direction.keys()[direction])

	movement_completed.emit(direction)
