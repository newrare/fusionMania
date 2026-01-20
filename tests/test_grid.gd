extends Node2D

# Test script for GridManager and Grid system

func _ready():
	print("\n=== Testing GridManager and Grid System ===\n")

	# Test 1: Initialize grid
	test_initialize_grid()

	# Test 2: Get empty cells
	await get_tree().create_timer(0.5).timeout
	test_empty_cells()

	# Test 3: Spawn tiles
	await get_tree().create_timer(0.5).timeout
	test_spawn_tiles()

	# Test 4: Grid positions
	await get_tree().create_timer(0.5).timeout
	test_grid_positions()

	# Test 5: Valid moves detection
	await get_tree().create_timer(0.5).timeout
	test_valid_moves()

	print("\n=== All GridManager Tests Completed ===\n")


# Test 1: Initialize grid
func test_initialize_grid():
	print("📝 Test 1: Initialize grid")

	GridManager.initialize_grid()

	print("  ✅ Grid initialized")
	print("  ✅ Grid size: %dx%d" % [GridManager.grid_size, GridManager.grid_size])
	print("  ✅ Grid array length: %d" % GridManager.grid.size())

	# Verify all cells are null
	var null_count = 0
	for row in GridManager.grid:
		for cell in row:
			if cell == null:
				null_count += 1

	print("  ✅ Empty cells: %d (should be 16)" % null_count)


# Test 2: Get empty cells
func test_empty_cells():
	print("\n📝 Test 2: Get empty cells")

	GridManager.initialize_grid()
	var empty_cells = GridManager.get_empty_cells()

	print("  ✅ Empty cells count: %d" % empty_cells.size())
	print("  ✅ All positions are Vector2i: %s" % (empty_cells[0] is Vector2i))


# Test 3: Spawn tiles
func test_spawn_tiles():
	print("\n📝 Test 3: Spawn tiles")

	# Create Grid visual container
	var grid_visual = preload("res://objects/Grid.tscn").instantiate()
	add_child(grid_visual)

	# Start new game (spawns 2 tiles)
	GridManager.start_new_game()

	await get_tree().create_timer(0.3).timeout

	# Count tiles
	var tile_count = 0
	for row in GridManager.grid:
		for cell in row:
			if cell != null:
				tile_count += 1

	print("  ✅ Tiles spawned: %d (should be 2)" % tile_count)

	# Check tile values
	for row in GridManager.grid:
		for cell in row:
			if cell != null:
				print("  ✅ Tile: value=%d, power=%s, pos=%s" % [
					cell.value,
					cell.power_type,
					cell.grid_position
				])


# Test 4: Grid positions
func test_grid_positions():
	print("\n📝 Test 4: Grid positions")

	# Test get_tile_at
	for y in range(4):
		for x in range(4):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile != null:
				print("  ✅ Tile at (%d,%d): value=%d" % [x, y, tile.value])

	# Test out of bounds
	var out_tile = GridManager.get_tile_at(Vector2i(10, 10))
	print("  ✅ Out of bounds returns null: %s" % (out_tile == null))


# Test 5: Valid moves detection
func test_valid_moves():
	print("\n📝 Test 5: Valid moves detection")

	# With empty cells
	var has_moves = GridManager.has_valid_moves()
	print("  ✅ Has valid moves (with empty cells): %s" % has_moves)

	# Fill grid completely
	GridManager.initialize_grid()
	for y in range(4):
		for x in range(4):
			var value = 2 if (x + y) % 2 == 0 else 4
			var tile  = GridManager.create_tile(value, "", Vector2i(x, y))

	has_moves = GridManager.has_valid_moves()
	print("  ✅ Has valid moves (full grid, no matches): %s" % has_moves)

	# Create a match
	GridManager.initialize_grid()
	GridManager.create_tile(2, "", Vector2i(0, 0))
	GridManager.create_tile(2, "", Vector2i(1, 0))

	has_moves = GridManager.has_valid_moves()
	print("  ✅ Has valid moves (with match): %s" % has_moves)
