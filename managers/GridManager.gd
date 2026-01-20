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

	# Spawn initial tiles
	spawn_random_tile()
	spawn_random_tile()

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

	# Check possible horizontal and vertical fusions
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile == null or tile.is_frozen:
				continue

			# Check right
			if x < grid_size - 1:
				var right_tile = grid[y][x + 1]
				if right_tile != null and tile.can_merge_with(right_tile):
					return true

			# Check bottom
			if y < grid_size - 1:
				var bottom_tile = grid[y + 1][x]
				if bottom_tile != null and tile.can_merge_with(bottom_tile):
					return true

	return false


# Spawn random tile at empty position
func spawn_random_tile():
	var empty_cells = get_empty_cells()

	if empty_cells.is_empty():
		return null

	# Choose random empty cell
	var random_cell = empty_cells[randi() % empty_cells.size()]

	# 90% chance of 2, 10% chance of 4
	var value = 2 if randf() < 0.9 else 4

	# Assign power
	var power = PowerManager.get_random_power()

	# Create tile
	var tile = create_tile(value, power, random_cell)

	return tile


# Create tile at position
func create_tile(value: int, power: String, grid_pos: Vector2i):
	var tile = preload("res://objects/Tile.tscn").instantiate()
	tile.initialize(value, power, grid_pos)
	grid[grid_pos.y][grid_pos.x] = tile

	# Add to Grid visual container
	var grid_node = get_tree().get_first_node_in_group("grid")
	if grid_node:
		grid_node.add_tile(tile)

	tile_spawned.emit(tile, grid_pos)
	return tile


# Destroy tile
func destroy_tile(tile):
	var pos = tile.grid_position
	grid[pos.y][pos.x] = null
	tile.destroy_animation()


# Move tile from one position to another
func move_tile(tile, from: Vector2i, to: Vector2i):
	# Update grid
	grid[from.y][from.x] = null
	grid[to.y][to.x]     = tile

	# Update tile
	tile.grid_position = to

	# Animation
	var grid_node = get_tree().get_first_node_in_group("grid")
	if grid_node:
		var screen_pos = grid_node.calculate_screen_position(to)
		tile.move_to_position(screen_pos)


# Move tiles up
func move_tiles_up(fusions: Array) -> bool:
	var moved = false

	# Traverse top to bottom, left to right
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_frozen:
				continue

			# Find target position
			var target_y = y

			# Move up as far as possible
			while target_y > 0 and grid[target_y - 1][x] == null:
				target_y -= 1

			# Check fusion with tile above
			if target_y > 0:
				var above_tile = grid[target_y - 1][x]
				if above_tile != null and tile.can_merge_with(above_tile):
					# Fusion possible - don't move yet, just track
					fusions.append({
						"tile1": tile,
						"tile2": above_tile,
						"position": Vector2i(x, target_y - 1)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_y != y:
				move_tile(tile, Vector2i(x, y), Vector2i(x, target_y))
				moved = true

	return moved


# Move tiles down
func move_tiles_down(fusions: Array) -> bool:
	var moved = false

	# Traverse bottom to top, left to right
	for x in range(grid_size):
		for y in range(grid_size - 1, -1, -1):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_frozen:
				continue

			# Find target position
			var target_y = y

			# Move down as far as possible
			while target_y < grid_size - 1 and grid[target_y + 1][x] == null:
				target_y += 1

			# Check fusion with tile below
			if target_y < grid_size - 1:
				var below_tile = grid[target_y + 1][x]
				if below_tile != null and tile.can_merge_with(below_tile):
					# Fusion possible - don't move yet, just track
					fusions.append({
						"tile1": tile,
						"tile2": below_tile,
						"position": Vector2i(x, target_y + 1)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_y != y:
				move_tile(tile, Vector2i(x, y), Vector2i(x, target_y))
				moved = true

	return moved


# Move tiles left
func move_tiles_left(fusions: Array) -> bool:
	var moved = false

	# Traverse left to right, top to bottom
	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_frozen:
				continue

			# Find target position
			var target_x = x

			# Move left as far as possible
			while target_x > 0 and grid[y][target_x - 1] == null:
				target_x -= 1

			# Check fusion with tile to the left
			if target_x > 0:
				var left_tile = grid[y][target_x - 1]
				if left_tile != null and tile.can_merge_with(left_tile):
					# Fusion possible - don't move yet, just track
					fusions.append({
						"tile1": tile,
						"tile2": left_tile,
						"position": Vector2i(target_x - 1, y)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_x != x:
				move_tile(tile, Vector2i(x, y), Vector2i(target_x, y))
				moved = true

	return moved


# Move tiles right
func move_tiles_right(fusions: Array) -> bool:
	var moved = false

	# Traverse right to left, top to bottom
	for y in range(grid_size):
		for x in range(grid_size - 1, -1, -1):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_frozen:
				continue

			# Find target position
			var target_x = x

			# Move right as far as possible
			while target_x < grid_size - 1 and grid[y][target_x + 1] == null:
				target_x += 1

			# Check fusion with tile to the right
			if target_x < grid_size - 1:
				var right_tile = grid[y][target_x + 1]
				if right_tile != null and tile.can_merge_with(right_tile):
					# Fusion possible - don't move yet, just track
					fusions.append({
						"tile1": tile,
						"tile2": right_tile,
						"position": Vector2i(target_x + 1, y)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_x != x:
				move_tile(tile, Vector2i(x, y), Vector2i(target_x, y))
				moved = true

	return moved


# Process fusions from movement
func process_fusions(fusions: Array):
	if fusions.is_empty():
		return

	for fusion_data in fusions:
		var tile1        = fusion_data.tile1
		var tile2        = fusion_data.tile2
		var position     = fusion_data.position

		# Remove tiles from their original positions in grid
		var pos1 = tile1.grid_position
		var pos2 = tile2.grid_position
		grid[pos1.y][pos1.x] = null
		grid[pos2.y][pos2.x] = null

		# Merge tiles
		var merge_result = tile1.merge_with(tile2)

		# Destroy old tiles visually
		tile1.queue_free()
		tile2.queue_free()

		# Create new tile at fusion position
		var new_tile = create_tile(
			merge_result.value,
			merge_result.power,
			position
		)

		# Add score
		ScoreManager.add_to_score(merge_result.value)

		# Animation and sound
		new_tile.merge_animation()
		AudioManager.play_sfx_fusion()

		# Activate power if match
		if merge_result.power_activated:
			PowerManager.activate_power(merge_result.power, new_tile, self)

		fusion_occurred.emit(tile1, tile2, new_tile)


# Process movement
func process_movement(direction: Direction):
	if not can_move:
		return

	# Check if direction is blocked
	if direction in blocked_directions:
		print("Direction blocked by freeze power!")
		return

	can_move = false
	var moved = false
	var fusions = []

	# Apply movement based on direction
	match direction:
		Direction.UP:
			moved = move_tiles_up(fusions)
		Direction.DOWN:
			moved = move_tiles_down(fusions)
		Direction.LEFT:
			moved = move_tiles_left(fusions)
		Direction.RIGHT:
			moved = move_tiles_right(fusions)

	# If at least one tile moved
	if moved:
		move_count += 1
		AudioManager.play_sfx_move()

		# Wait for animations to finish
		await get_tree().create_timer(0.3).timeout

		# Process fusions
		process_fusions(fusions)

		# Spawn new tile
		spawn_random_tile()

		# Check game over
		if not has_valid_moves():
			game_over.emit()
	else:
		print("No tiles moved")

	can_move = true
	movement_completed.emit(direction)
