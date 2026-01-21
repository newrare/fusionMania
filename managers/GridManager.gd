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
signal tiles_moved()
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
	# Clear all existing tiles from visual grid
	var grid_node = get_tree().get_first_node_in_group("grid")
	if grid_node:
		grid_node.clear_all_tiles()
	
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
	
	var power_to_activate = null
	var power_tile = null
	var highest_priority_value = -1
	var highest_priority_y = 999
	var highest_priority_x = 999
	
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

		# Track power for priority activation (only one power per movement)
		if merge_result.power_activated:
			var should_replace = false
			
			# Priority 1: Highest value
			if merge_result.value > highest_priority_value:
				should_replace = true
			# Priority 2: Same value, highest position (lowest y)
			elif merge_result.value == highest_priority_value and position.y < highest_priority_y:
				should_replace = true
			# Priority 3: Same value and y, leftmost (lowest x)
			elif merge_result.value == highest_priority_value and position.y == highest_priority_y and position.x < highest_priority_x:
				should_replace = true
			
			if should_replace:
				power_to_activate = merge_result.power
				power_tile = new_tile
				highest_priority_value = merge_result.value
				highest_priority_y = position.y
				highest_priority_x = position.x

		fusion_occurred.emit(tile1, tile2, new_tile)
	
	# Wait for all merge animations to complete before activating power
	await get_tree().create_timer(0.3).timeout
	
	# Activate only the highest priority power
	if power_to_activate != null and power_tile != null:
		await PowerManager.activate_power(power_to_activate, power_tile, self)


# Process movement
func process_movement(direction: Direction) -> bool:
	if not can_move:
		return false

	# Check if direction is blocked
	if direction in blocked_directions:
		print("Direction blocked by freeze power!")
		return false

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
		tiles_moved.emit()
		AudioManager.play_sfx_move()

		# Decrease freeze turns for all tiles
		update_freeze_turns()

		# Wait for movement animations to finish
		await get_tree().create_timer(0.3).timeout

		# Process fusions and wait for all animations (merge + power) to complete
		await process_fusions(fusions)

		# Spawn new tile only after all animations are done
		spawn_random_tile()

		# Check game over
		if not has_valid_moves():
			game_over.emit()
	else:
		print("No tiles moved")

	can_move = true
	movement_completed.emit(direction)
	return moved


# ============================
# Power Support Methods
# ============================

var frozen_directions: Dictionary = {}  # {Direction: turns_remaining}
var blind_mode: bool              = false
var blind_turns: int              = 0


# Swap two tiles positions
func swap_tiles(tile1, tile2):
	var pos1 = tile1.grid_position
	var pos2 = tile2.grid_position
	
	# Swap in grid
	grid[pos1.y][pos1.x] = tile2
	grid[pos2.y][pos2.x] = tile1
	
	# Update tiles
	tile1.grid_position = pos2
	tile2.grid_position = pos1
	
	# Animate movement
	var grid_node = get_tree().get_first_node_in_group("grid")
	if grid_node:
		tile1.move_to_position(grid_node.calculate_screen_position(pos2))
		tile2.move_to_position(grid_node.calculate_screen_position(pos1))
	
	print("Swapped tiles at %s and %s" % [pos1, pos2])


# Freeze a direction for N turns
func freeze_direction(direction: Direction, turns: int):
	frozen_directions[direction] = turns
	print("Direction %s frozen for %d turns" % [Direction.keys()[direction], turns])


# Check if direction is frozen
func is_direction_frozen(direction: Direction) -> bool:
	return frozen_directions.has(direction) and frozen_directions[direction] > 0


# Decrement frozen direction counters (called after each move)
func update_frozen_directions():
	var to_remove = []
	for dir in frozen_directions.keys():
		frozen_directions[dir] -= 1
		if frozen_directions[dir] <= 0:
			to_remove.append(dir)
	
	for dir in to_remove:
		frozen_directions.erase(dir)
		print("Direction %s unfrozen" % Direction.keys()[dir])


# Set blind mode
func set_blind_mode(enabled: bool, turns: int = 0):
	blind_mode  = enabled
	blind_turns = turns
	
	if enabled:
		print("👁️ Blind mode enabled for %d turns" % turns)
	else:
		print("👁️ Blind mode disabled")


# Update blind mode (called after each move)
func update_blind_mode():
	if blind_mode and blind_turns > 0:
		blind_turns -= 1
		if blind_turns <= 0:
			set_blind_mode(false)


# Update freeze turns for all tiles (called after each move)
func update_freeze_turns():
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile != null and tile.has_method("decrease_freeze_turns"):
				tile.decrease_freeze_turns()


# Check if tile with specific value exists
func has_tile_value(value: int) -> bool:
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile != null and tile.value == value:
				return true
	return false


# Check if game is over (no valid moves)
func is_game_over() -> bool:
	return not has_valid_moves()
