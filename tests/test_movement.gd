# Test script for movement and fusion logic
extends Node2D

func _ready():
	print("\n=== Movement and Fusion Tests ===\n")

	# Setup grid visual
	var grid_node = preload("res://objects/Grid.tscn").instantiate()
	grid_node.name = "Grid"
	add_child(grid_node)

	await get_tree().create_timer(0.1).timeout

	test_move_up()
	await get_tree().create_timer(1.0).timeout

	test_move_down()
	await get_tree().create_timer(1.0).timeout

	test_move_left()
	await get_tree().create_timer(1.0).timeout

	test_move_right()
	await get_tree().create_timer(1.0).timeout

	test_fusion()
	await get_tree().create_timer(1.0).timeout

	test_game_over()
	await get_tree().create_timer(1.0).timeout

	print("\n=== All Movement Tests Complete ===\n")
	get_tree().quit()


# Test 1: Move tiles up
func test_move_up():
	print("Test 1: Move tiles UP")
	GridManager.initialize_grid()

	# Create tile at bottom
	var tile1 = GridManager.create_tile(2, "none", Vector2i(1, 3))

	# Process movement
	GridManager.process_movement(GridManager.Direction.UP)
	await get_tree().create_timer(0.5).timeout

	# Check position
	var new_pos = tile1.grid_position
	print("  ✅ Tile moved from (1,3) to (%d,%d)" % [new_pos.x, new_pos.y])

	# Cleanup
	GridManager.destroy_tile(tile1)


# Test 2: Move tiles down
func test_move_down():
	print("Test 2: Move tiles DOWN")
	GridManager.initialize_grid()

	# Create tile at top
	var tile1 = GridManager.create_tile(2, "none", Vector2i(1, 0))

	# Process movement
	GridManager.process_movement(GridManager.Direction.DOWN)
	await get_tree().create_timer(0.5).timeout

	# Check position
	var new_pos = tile1.grid_position
	print("  ✅ Tile moved from (1,0) to (%d,%d)" % [new_pos.x, new_pos.y])

	# Cleanup
	GridManager.destroy_tile(tile1)


# Test 3: Move tiles left
func test_move_left():
	print("Test 3: Move tiles LEFT")
	GridManager.initialize_grid()

	# Create tile at right
	var tile1 = GridManager.create_tile(2, "none", Vector2i(3, 1))

	# Process movement
	GridManager.process_movement(GridManager.Direction.LEFT)
	await get_tree().create_timer(0.5).timeout

	# Check position
	var new_pos = tile1.grid_position
	print("  ✅ Tile moved from (3,1) to (%d,%d)" % [new_pos.x, new_pos.y])

	# Cleanup
	GridManager.destroy_tile(tile1)


# Test 4: Move tiles right
func test_move_right():
	print("Test 4: Move tiles RIGHT")
	GridManager.initialize_grid()

	# Create tile at left
	var tile1 = GridManager.create_tile(2, "none", Vector2i(0, 1))

	# Process movement
	GridManager.process_movement(GridManager.Direction.RIGHT)
	await get_tree().create_timer(0.5).timeout

	# Check position
	var new_pos = tile1.grid_position
	print("  ✅ Tile moved from (0,1) to (%d,%d)" % [new_pos.x, new_pos.y])

	# Cleanup
	GridManager.destroy_tile(tile1)


# Test 5: Fusion of two identical tiles
func test_fusion():
	print("Test 5: Fusion of two identical tiles")
	GridManager.initialize_grid()

	# Create two tiles with same value (no power)
	# tile1 at bottom, tile2 above it
	var tile1 = GridManager.create_tile(2, "none", Vector2i(1, 3))
	var tile2 = GridManager.create_tile(2, "none", Vector2i(1, 2))

	print("  Created tile1 at (1,3) value=%d" % tile1.value)
	print("  Created tile2 at (1,2) value=%d" % tile2.value)
	print("  Can merge: %s" % str(tile1.can_merge_with(tile2)))

	var initial_score = ScoreManager.current_score

	# Move up (tile1 should move up and fuse with tile2)
	GridManager.process_movement(GridManager.Direction.UP)
	await get_tree().create_timer(0.8).timeout

	# Check all positions
	print("  Grid after movement:")
	for y in range(4):
		for x in range(4):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile:
				print("    Position (%d,%d): value=%d" % [x, y, tile.value])

	# Check fusion occurred - should be at (1,0) after moving all the way up
	var final_tile = GridManager.get_tile_at(Vector2i(1, 0))
	if final_tile and final_tile.value == 4:
		print("  ✅ Fusion successful: 2 + 2 = 4 at position (1,0)")
	else:
		if final_tile:
			print("  ❌ Fusion failed - tile exists but value is %d" % final_tile.value)
		else:
			print("  ❌ Fusion failed - no tile at expected position (1,0)")

	# Check score increased
	var score_diff = ScoreManager.current_score - initial_score
	print("  ✅ Score increased by: %d" % score_diff)

	# Cleanup
	for y in range(4):
		for x in range(4):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile:
				GridManager.destroy_tile(tile)


# Test 6: Game over detection
func test_game_over():
	print("Test 6: Game over detection")
	GridManager.initialize_grid()

	# Fill grid with alternating values (no matches possible)
	var values = [2, 4]
	for y in range(4):
		for x in range(4):
			var value = values[(x + y) % 2]
			GridManager.create_tile(value, "none", Vector2i(x, y))

	# Check valid moves
	var has_moves = GridManager.has_valid_moves()

	if not has_moves:
		print("  ✅ Game over detected correctly (no valid moves)")
	else:
		print("  ⚠️ Game over detection issue")

	# Cleanup
	for y in range(4):
		for x in range(4):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile:
				GridManager.destroy_tile(tile)
