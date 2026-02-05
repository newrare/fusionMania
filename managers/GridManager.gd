# GridManager for Fusion Mania
# Manages the 4x4 grid, tile movements, and fusion logic
extends Node

# Load PowerEffect for visual effects
const PowerEffect = preload("res://visuals/PowerEffect.gd")

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

var grid: Array[Array]			= []
var grid_size: int				= 4
var can_move: bool				= true
var move_count: int				= 0
var blind_mode: bool			= false
var blind_turns: int			= 0

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


# Print current grid state to console
func print_grid_state(direction_name: String = ""):
	var header = "=== GRID STATE"
	if direction_name != "":
		header += " (after %s)" % direction_name
	header += " ==="
	print(header)

	for y in range(grid_size):
		var row_str = ""
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile != null:
				row_str += "%4d |" % tile.value
			else:
				row_str += "     |"
		print(row_str)
	print("")


# Start a new game
func start_new_game():
	# Clear all visual effects FIRST
	PowerEffect.clear_all_wind_effects()

	# Clear all existing tiles from visual grid
	var grid_node = get_tree().get_first_node_in_group("grid")
	if grid_node:
		grid_node.clear_all_tiles()

	initialize_grid()
	move_count = 0

	# Spawn initial tiles
	spawn_random_tile()
	spawn_random_tile()

	print("New game started")


# Get empty cells in the grid
func get_empty_cells():
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
func has_valid_moves():
	# Check for empty cells
	if not get_empty_cells().is_empty():
		return true

	# Check possible horizontal and vertical fusions
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile == null or tile.is_iced:
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

	# 70% chance of 2, 30% chance of 4
	var value = 2 if randf() < 0.7 else 4

	# Assign power
	var power = PowerManager.get_random_power()

	# Create tile (mark as new spawn)
	var tile = create_tile(value, power, random_cell, true)

	return tile


# Create tile at position
func create_tile(value: int, power: String, grid_pos: Vector2i, is_new_spawn: bool = false):
	var tile = preload("res://objects/Tile.tscn").instantiate()
	tile.initialize(value, power, grid_pos)
	tile.is_new_tile = is_new_spawn  # Only mark as new if it's a random spawn
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


# Animate tile movement visually without updating grid (for fusions)
func animate_tile_to_position(tile, target_pos: Vector2i):
	if tile == null or not is_instance_valid(tile):
		return

	var grid_node = get_tree().get_first_node_in_group("grid")
	if grid_node:
		var screen_pos = grid_node.calculate_screen_position(target_pos)
		tile.move_to_position(screen_pos)


# Bounce tile in direction (for tiles that can't move)
func bounce_tile(tile, direction: Direction):
	if tile == null or not is_instance_valid(tile):
		return

	var offset = Vector2.ZERO
	match direction:
		Direction.UP:
			offset = Vector2(0, -5)
		Direction.DOWN:
			offset = Vector2(0, 5)
		Direction.LEFT:
			offset = Vector2(-5, 0)
		Direction.RIGHT:
			offset = Vector2(5, 0)

	# Create bounce animation
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	# Original position
	var original_pos = tile.position

	# Move slightly in direction
	tween.tween_property(tile, "position", original_pos + offset, 0.1)
	# Return to original position
	tween.tween_property(tile, "position", original_pos, 0.1)


# Move tiles up
func move_tiles_up(fusions: Array):
	var moved = false
	var animations = []  # Collect all animations to run in parallel

	# Traverse top to bottom, left to right
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_iced:
				continue

			# Find target position
			var target_y = y

			# Move up as far as possible
			while target_y > 0 and grid[target_y - 1][x] == null:
				target_y -= 1

			# Check if tile can exit grid (expel power)
			if tile.expel_direction == "v" and target_y == 0:
				# Tile reaches top edge and can exit
				grid[y][x] = null
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var off_screen_pos = Vector2i(tile.grid_position.x, -2)
					var target_screen_pos = grid_node.calculate_screen_position(off_screen_pos)
					var tween = tile.move_to_position(target_screen_pos, 0.2)
					if tween:
						animations.append(tween)
						tween.finished.connect(func(): if is_instance_valid(tile): tile.queue_free())
				print("🚀 Tile expelled through top edge")
				moved = true
				continue

			# Check fusion with tile above
			if target_y > 0:
				var above_tile = grid[target_y - 1][x]
				if above_tile != null and tile.can_merge_with(above_tile) and not above_tile.get("is_merging"):
					# Fusion possible
					var fusion_y = target_y - 1

					# Fadeout tile2 during movement
					var fadeout_tween = create_tween()
					fadeout_tween.tween_property(above_tile, "modulate:a", 0.0, 0.15)

					# Create new tile IMMEDIATELY at fusion position
					var merge_result = tile.merge_with(above_tile)
					print("🔥 Fusion Details - tile1(%d,%d) value=%d power='%s' + tile2(%d,%d) value=%d power='%s'" % [x, y, tile.value, tile.power_type, x, fusion_y, above_tile.value, above_tile.power_type])
					var new_tile = create_tile(merge_result.value, merge_result.power, Vector2i(x, fusion_y))
					new_tile.modulate.a = 0  # Hide until animation completes
					new_tile.is_merging = true  # Prevent double fusion in same move

					# Grid logic: put new tile in grid immediately
					grid[y][x] = null
					grid[fusion_y][x] = new_tile  # New tile blocks other tiles

					# Animation: move tile1 to fusion position (where tile2 is)
					tile.grid_position = Vector2i(x, fusion_y)
					var grid_node = get_tree().get_first_node_in_group("grid")
					if grid_node:
						var screen_pos = grid_node.calculate_screen_position(Vector2i(x, fusion_y))
						var tween = tile.move_to_position(screen_pos, 0.2)
						if tween:
							animations.append(tween)

					fusions.append({
						"tile1": tile,
						"tile2": above_tile,
						"new_tile": new_tile,
						"merge_result": merge_result,
						"position": Vector2i(x, fusion_y)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_y != y:
				grid[y][x] = null
				grid[target_y][x] = tile
				tile.grid_position = Vector2i(x, target_y)
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var screen_pos = grid_node.calculate_screen_position(Vector2i(x, target_y))
					var tween = tile.move_to_position(screen_pos, 0.2)
					if tween:
						animations.append(tween)
				moved = true

	# Wait for all animations to complete in parallel
	if animations.size() > 0:
		for tween in animations:
			if is_instance_valid(tween):
				await tween.finished

	return moved


# Move tiles down
func move_tiles_down(fusions: Array):
	var moved = false
	var animations = []  # Collect all animations

	# Traverse bottom to top, left to right
	for x in range(grid_size):
		for y in range(grid_size - 1, -1, -1):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_iced:
				continue

			# Find target position
			var target_y = y

			# Move down as far as possible
			while target_y < grid_size - 1 and grid[target_y + 1][x] == null:
				target_y += 1

			# Check if tile can exit grid (expel power)
			if tile.expel_direction == "v" and target_y == grid_size - 1:
				# Tile reaches bottom edge and can exit
				grid[y][x] = null
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var off_screen_pos = Vector2i(tile.grid_position.x, grid_size + 1)
					var target_screen_pos = grid_node.calculate_screen_position(off_screen_pos)
					var tween = tile.move_to_position(target_screen_pos, 0.2)
					if tween:
						animations.append(tween)
						tween.finished.connect(func(): if is_instance_valid(tile): tile.queue_free())
				print("🚀 Tile expelled through bottom edge")
				moved = true
				continue

			# Check fusion with tile below
			if target_y < grid_size - 1:
				var below_tile = grid[target_y + 1][x]
				if below_tile != null and tile.can_merge_with(below_tile) and not below_tile.get("is_merging"):
					# Fusion possible
					var fusion_y = target_y + 1

					# Fadeout tile2 during movement
					var fadeout_tween = create_tween()
					fadeout_tween.tween_property(below_tile, "modulate:a", 0.0, 0.15)

					# Create new tile IMMEDIATELY at fusion position
					var merge_result = tile.merge_with(below_tile)
					print("🔥 Fusion Details - tile1(%d,%d) value=%d power='%s' + tile2(%d,%d) value=%d power='%s'" % [x, y, tile.value, tile.power_type, x, fusion_y, below_tile.value, below_tile.power_type])
					var new_tile = create_tile(merge_result.value, merge_result.power, Vector2i(x, fusion_y))
					new_tile.modulate.a = 0  # Hide until animation completes
					new_tile.is_merging = true  # Prevent double fusion in same move

					# Grid logic: put new tile in grid immediately
					grid[y][x] = null
					grid[fusion_y][x] = new_tile  # New tile blocks other tiles

					# Animation: move tile1 to fusion position (where tile2 is)
					tile.grid_position = Vector2i(x, fusion_y)
					var grid_node = get_tree().get_first_node_in_group("grid")
					if grid_node:
						var screen_pos = grid_node.calculate_screen_position(Vector2i(x, fusion_y))
						var tween = tile.move_to_position(screen_pos, 0.2)
						if tween:
							animations.append(tween)

					fusions.append({
						"tile1": tile,
						"tile2": below_tile,
						"new_tile": new_tile,
						"merge_result": merge_result,
						"position": Vector2i(x, fusion_y)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_y != y:
				grid[y][x] = null
				grid[target_y][x] = tile
				tile.grid_position = Vector2i(x, target_y)
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var screen_pos = grid_node.calculate_screen_position(Vector2i(x, target_y))
					var tween = tile.move_to_position(screen_pos, 0.2)
					if tween:
						animations.append(tween)
				moved = true

	# Wait for all animations to complete
	if animations.size() > 0:
		for tween in animations:
			if is_instance_valid(tween):
				await tween.finished

	return moved


# Move tiles left
func move_tiles_left(fusions: Array):
	var moved = false
	var animations = []  # Collect all animations

	# Traverse left to right, top to bottom
	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_iced:
				continue

			# Find target position
			var target_x = x

			# Move left as far as possible
			while target_x > 0 and grid[y][target_x - 1] == null:
				target_x -= 1

			# Check if tile can exit grid (expel power)
			if tile.expel_direction == "h" and target_x == 0:
				# Tile reaches left edge and can exit
				grid[y][x] = null
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var off_screen_pos = Vector2i(-2, tile.grid_position.y)
					var target_screen_pos = grid_node.calculate_screen_position(off_screen_pos)
					var tween = tile.move_to_position(target_screen_pos, 0.2)
					if tween:
						animations.append(tween)
						tween.finished.connect(func(): if is_instance_valid(tile): tile.queue_free())
				print("🚀 Tile expelled through left edge")
				moved = true
				continue

			# Check fusion with tile to the left
			if target_x > 0:
				var left_tile = grid[y][target_x - 1]
				if left_tile != null and tile.can_merge_with(left_tile) and not left_tile.get("is_merging"):
					# Fusion possible
					var fusion_x = target_x - 1

					# Fadeout tile2 during movement
					var fadeout_tween = create_tween()
					fadeout_tween.tween_property(left_tile, "modulate:a", 0.0, 0.15)

					# Create new tile IMMEDIATELY at fusion position
					var merge_result = tile.merge_with(left_tile)
					print("🔥 Fusion Details - tile1(%d,%d) value=%d power='%s' + tile2(%d,%d) value=%d power='%s'" % [x, y, tile.value, tile.power_type, fusion_x, y, left_tile.value, left_tile.power_type])
					var new_tile = create_tile(merge_result.value, merge_result.power, Vector2i(fusion_x, y))
					new_tile.modulate.a = 0  # Hide until animation completes
					new_tile.is_merging = true  # Prevent double fusion in same move

					# Grid logic: put new tile in grid immediately
					grid[y][x] = null
					grid[y][fusion_x] = new_tile  # New tile blocks other tiles

					# Animation: move tile1 to fusion position (where tile2 is)
					tile.grid_position = Vector2i(fusion_x, y)
					var grid_node = get_tree().get_first_node_in_group("grid")
					if grid_node:
						var screen_pos = grid_node.calculate_screen_position(Vector2i(fusion_x, y))
						var tween = tile.move_to_position(screen_pos, 0.2)
						if tween:
							animations.append(tween)

					fusions.append({
						"tile1": tile,
						"tile2": left_tile,
						"new_tile": new_tile,
						"merge_result": merge_result,
						"position": Vector2i(fusion_x, y)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_x != x:
				grid[y][x] = null
				grid[y][target_x] = tile
				tile.grid_position = Vector2i(target_x, y)
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var screen_pos = grid_node.calculate_screen_position(Vector2i(target_x, y))
					var tween = tile.move_to_position(screen_pos, 0.2)
					if tween:
						animations.append(tween)
				moved = true

	# Wait for all animations to complete
	if animations.size() > 0:
		for tween in animations:
			if is_instance_valid(tween):
				await tween.finished

	return moved


# Move tiles right
func move_tiles_right(fusions: Array):
	var moved = false
	var animations = []  # Collect all animations

	# Traverse right to left, top to bottom
	for y in range(grid_size):
		for x in range(grid_size - 1, -1, -1):
			if grid[y][x] == null:
				continue

			var tile = grid[y][x]
			if tile.is_iced:
				continue

			# Find target position
			var target_x = x

			# Move right as far as possible
			while target_x < grid_size - 1 and grid[y][target_x + 1] == null:
				target_x += 1

			# Check if tile can exit grid (expel power)
			if tile.expel_direction == "h" and target_x == grid_size - 1:
				# Tile reaches right edge and can exit
				grid[y][x] = null
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var off_screen_pos = Vector2i(grid_size + 1, tile.grid_position.y)
					var target_screen_pos = grid_node.calculate_screen_position(off_screen_pos)
					var tween = tile.move_to_position(target_screen_pos, 0.2)
					if tween:
						animations.append(tween)
						tween.finished.connect(func(): if is_instance_valid(tile): tile.queue_free())
				print("🚀 Tile expelled through right edge")
				moved = true
				continue

			# Check fusion with tile to the right
			if target_x < grid_size - 1:
				var right_tile = grid[y][target_x + 1]
				if right_tile != null and tile.can_merge_with(right_tile) and not right_tile.get("is_merging"):
					# Fusion possible
					var fusion_x = target_x + 1

					# Fadeout tile2 during movement
					var fadeout_tween = create_tween()
					fadeout_tween.tween_property(right_tile, "modulate:a", 0.0, 0.15)

					# Create new tile IMMEDIATELY at fusion position
					var merge_result = tile.merge_with(right_tile)
					print("🔥 Fusion Details - tile1(%d,%d) value=%d power='%s' + tile2(%d,%d) value=%d power='%s'" % [x, y, tile.value, tile.power_type, fusion_x, y, right_tile.value, right_tile.power_type])
					var new_tile = create_tile(merge_result.value, merge_result.power, Vector2i(fusion_x, y))
					new_tile.modulate.a = 0  # Hide until animation completes
					new_tile.is_merging = true  # Prevent double fusion in same move

					# Grid logic: put new tile in grid immediately
					grid[y][x] = null
					grid[y][fusion_x] = new_tile  # New tile blocks other tiles

					# Animation: move tile1 to fusion position (where tile2 is)
					tile.grid_position = Vector2i(fusion_x, y)
					var grid_node = get_tree().get_first_node_in_group("grid")
					if grid_node:
						var screen_pos = grid_node.calculate_screen_position(Vector2i(fusion_x, y))
						var tween = tile.move_to_position(screen_pos, 0.2)
						if tween:
							animations.append(tween)

					fusions.append({
						"tile1": tile,
						"tile2": right_tile,
						"new_tile": new_tile,
						"merge_result": merge_result,
						"position": Vector2i(fusion_x, y)
					})
					moved = true
					continue

			# Simple movement (no fusion)
			if target_x != x:
				grid[y][x] = null
				grid[y][target_x] = tile
				tile.grid_position = Vector2i(target_x, y)
				var grid_node = get_tree().get_first_node_in_group("grid")
				if grid_node:
					var screen_pos = grid_node.calculate_screen_position(Vector2i(target_x, y))
					var tween = tile.move_to_position(screen_pos, 0.2)
					if tween:
						animations.append(tween)
				moved = true

	# Wait for all animations to complete
	if animations.size() > 0:
		for tween in animations:
			if is_instance_valid(tween):
				await tween.finished

	return moved


# Process fusions from movement
func process_fusions(fusions: Array):
	if fusions.is_empty():
		return

	# Wait for movement animations to complete (tiles moving to collision point)
	await get_tree().create_timer(0.2).timeout

	var power_to_activate = null
	var power_tile = null
	var highest_priority_value = -1
	var highest_priority_y = 999
	var highest_priority_x = 999

	for fusion_data in fusions:
		var tile1        = fusion_data.tile1
		var tile2        = fusion_data.tile2
		var new_tile     = fusion_data.new_tile
		var merge_result = fusion_data.merge_result
		var position     = fusion_data.position

		# Destroy old tiles visually (they are no longer in grid)
		if is_instance_valid(tile1):
			tile1.queue_free()
		if is_instance_valid(tile2):
			tile2.queue_free()

		# Show and animate new tile (already in grid)
		new_tile.modulate.a = 1.0
		new_tile.merge_animation()

		# Add score
		ScoreManager.add_to_score(merge_result.value)

		# Track power for priority activation (only one power per movement)
		print("🔍 GridManager Debug - merge_result.power_activated: %s, power_to_activate: '%s'" % [merge_result.power_activated, merge_result.get("power_to_activate", "N/A")])
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
				power_to_activate = merge_result.power_to_activate  # Use saved power name instead of tile power
				power_tile = new_tile
				highest_priority_value = merge_result.value
				highest_priority_y = position.y
				highest_priority_x = position.x

		fusion_occurred.emit(tile1, tile2, new_tile)

	# Wait for all merge animations to complete before activating power
	await get_tree().create_timer(0.3).timeout

	print("🔍 GridManager Final Debug - power_to_activate: '%s', power_tile: %s" % [power_to_activate, power_tile])

	# Play fusion SFX only if no power was activated
	if power_to_activate == null:
		AudioManager.play_sfx_fusion()
		print("🔊 Playing fusion SFX (no power)")

	# Activate only the highest priority power
	if power_to_activate != null and power_tile != null:
		print("⚡ Activating power '%s' via PowerManager" % power_to_activate)
		await PowerManager.activate_power(power_to_activate, power_tile, self)
		print("✅ Power activation completed")
	else:
		print("❌ No power to activate - power_to_activate: %s, power_tile: %s" % [power_to_activate, power_tile])


# Process movement
func process_movement(direction: Direction):
	if not can_move:
		return false

	# Check if direction is blocked (use GameManager for blocked state)
	if GameManager.is_direction_blocked(direction):
		print("Direction blocked by block power!")
		return false

	# Interrupt any running power animation
	PowerManager.interrupt_current_power()

	can_move = false
	var moved = false
	var fusions = []

	# Collect all tiles that will move (for bounce effect)
	var tiles_before_move = []
	for y in range(grid_size):
		for x in range(grid_size):
			if grid[y][x] != null:
				tiles_before_move.append({"tile": grid[y][x], "pos": Vector2i(x, y)})

	# Apply movement based on direction
	var direction_name = ""
	match direction:
		Direction.UP:
			direction_name = "UP"
			moved = await move_tiles_up(fusions)
		Direction.DOWN:
			direction_name = "DOWN"
			moved = await move_tiles_down(fusions)
		Direction.LEFT:
			direction_name = "LEFT"
			moved = await move_tiles_left(fusions)
		Direction.RIGHT:
			direction_name = "RIGHT"
			moved = await move_tiles_right(fusions)

	# Create a set of tiles that are in fusion (to avoid bouncing them)
	var tiles_in_fusion = {}
	for fusion_data in fusions:
		tiles_in_fusion[fusion_data.tile1] = true

	# Bounce tiles that didn't move (and are not in a fusion)
	for tile_data in tiles_before_move:
		var tile = tile_data["tile"]
		var old_pos = tile_data["pos"]

		# Check if tile still exists, hasn't moved, and is not in a fusion
		if is_instance_valid(tile) and tile.grid_position == old_pos and not tiles_in_fusion.has(tile):
			bounce_tile(tile, direction)

	# If at least one tile moved
	if moved:
		move_count += 1
		tiles_moved.emit()
		AudioManager.play_sfx_move()

		# Mark previously new tiles as old (they've had one movement now)
		# This happens BEFORE fusions so fusion tiles keep their background
		for y in range(grid_size):
			for x in range(grid_size):
				var tile = grid[y][x]
				if tile != null and is_instance_valid(tile) and tile.is_new_tile:
					tile.is_new_tile = false
					tile.update_visual()

		# Decrease ice turns for all tiles
		# Decrement all power counters (blind, blocked directions, tile ice)
		GameManager.decrement_power_counters()

		# Update persistent power counters via GameManager
		GameManager.decrement_power_counters()

		# Process fusions (includes animation wait + merge + power)
		await process_fusions(fusions)

		# Reset is_merging flag for all tiles (allow merging again next move)
		for y in range(grid_size):
			for x in range(grid_size):
				var tile = grid[y][x]
				if tile != null and is_instance_valid(tile):
					tile.is_merging = false

		# Print grid state after movement and fusions
		print_grid_state(direction_name)

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


# Check if tile with specific value exists
func has_tile_value(value: int):
	for y in range(grid_size):
		for x in range(grid_size):
			var tile = grid[y][x]
			if tile != null and tile.value == value:
				return true
	return false


# Check if game is over (no valid moves)
func is_game_over():
	return not has_valid_moves()


# Expel tile off screen with animation
func _expel_tile_off_screen(tile, direction: Direction):
	if tile == null or not is_instance_valid(tile):
		return

	var grid_node = get_tree().get_first_node_in_group("grid")
	if not grid_node:
		tile.queue_free()
		return

	# Calculate off-screen position (two tiles beyond grid for better visibility)
	var off_screen_pos: Vector2i
	match direction:
		Direction.UP:
			off_screen_pos = Vector2i(tile.grid_position.x, -2)
		Direction.DOWN:
			off_screen_pos = Vector2i(tile.grid_position.x, grid_size + 1)
		Direction.LEFT:
			off_screen_pos = Vector2i(-2, tile.grid_position.y)
		Direction.RIGHT:
			off_screen_pos = Vector2i(grid_size + 1, tile.grid_position.y)

	# Animate to off-screen position with longer duration
	var target_screen_pos = grid_node.calculate_screen_position(off_screen_pos)
	var tween = tile.move_to_position(target_screen_pos, 0.4)

	# Wait for animation to complete
	if tween:
		await tween.finished

	# Destroy tile after animation completes
	if is_instance_valid(tile):
		tile.queue_free()
