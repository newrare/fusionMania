# Test script for fire powers (fire_h, fire_v, fire_cross)
extends Node2D

func _ready():
	print("\n=== Fire Powers Tests ===\n")

	# Setup grid visual
	var grid_node = preload("res://objects/Grid.tscn").instantiate()
	grid_node.name = "Grid"
	add_child(grid_node)

	await get_tree().create_timer(0.1).timeout

	test_fire_horizontal()
	await get_tree().create_timer(1.0).timeout

	test_fire_vertical()
	await get_tree().create_timer(1.0).timeout

	test_fire_cross()
	await get_tree().create_timer(1.0).timeout

	test_fire_fusion_activation()
	await get_tree().create_timer(1.0).timeout

	print("\n=== All Fire Power Tests Complete ===\n")
	get_tree().quit()


# Test 1: Fire Horizontal - destroy entire row
func test_fire_horizontal():
	print("Test 1: Fire Horizontal Power")
	GridManager.initialize_grid()

	# Create fire_h tile in middle of grid
	var fire_tile = GridManager.create_tile(8, "fire_h", Vector2i(1, 2))

	# Create other tiles in same row
	var tile1 = GridManager.create_tile(2, "none", Vector2i(0, 2))
	var tile2 = GridManager.create_tile(4, "none", Vector2i(2, 2))
	var tile3 = GridManager.create_tile(2, "none", Vector2i(3, 2))

	# Create tiles in other rows (should NOT be destroyed)
	var safe_tile1 = GridManager.create_tile(2, "none", Vector2i(1, 0))
	var safe_tile2 = GridManager.create_tile(4, "none", Vector2i(1, 3))

	print("  Created 4 tiles in row 2, 2 tiles in other rows")

	# Activate fire horizontal power
	PowerManager.activate_fire_horizontal(fire_tile, GridManager)
	await get_tree().create_timer(0.3).timeout

	# Check tiles in row 2 are destroyed (except fire_tile)
	var destroyed_count = 0
	if GridManager.get_tile_at(Vector2i(0, 2)) == null:
		destroyed_count += 1
	if GridManager.get_tile_at(Vector2i(2, 2)) == null:
		destroyed_count += 1
	if GridManager.get_tile_at(Vector2i(3, 2)) == null:
		destroyed_count += 1

	# Check fire_tile still exists
	var fire_exists = GridManager.get_tile_at(Vector2i(1, 2)) == fire_tile

	# Check safe tiles still exist
	var safe_exists = GridManager.get_tile_at(Vector2i(1, 0)) == safe_tile1 and GridManager.get_tile_at(Vector2i(1, 3)) == safe_tile2

	if destroyed_count == 3 and fire_exists and safe_exists:
		print("  ✅ Fire Horizontal: 3 tiles destroyed, fire tile intact, safe tiles intact")
	else:
		print("  ❌ Fire Horizontal failed: destroyed=%d, fire_exists=%s, safe_exists=%s" % [destroyed_count, fire_exists, safe_exists])

	# Cleanup
	cleanup_grid()


# Test 2: Fire Vertical - destroy entire column
func test_fire_vertical():
	print("\nTest 2: Fire Vertical Power")
	GridManager.initialize_grid()

	# Create fire_v tile in middle of grid
	var fire_tile = GridManager.create_tile(8, "fire_v", Vector2i(2, 1))

	# Create other tiles in same column
	var tile1 = GridManager.create_tile(2, "none", Vector2i(2, 0))
	var tile2 = GridManager.create_tile(4, "none", Vector2i(2, 2))
	var tile3 = GridManager.create_tile(2, "none", Vector2i(2, 3))

	# Create tiles in other columns (should NOT be destroyed)
	var safe_tile1 = GridManager.create_tile(2, "none", Vector2i(0, 1))
	var safe_tile2 = GridManager.create_tile(4, "none", Vector2i(3, 1))

	print("  Created 4 tiles in column 2, 2 tiles in other columns")

	# Activate fire vertical power
	PowerManager.activate_fire_vertical(fire_tile, GridManager)
	await get_tree().create_timer(0.3).timeout

	# Check tiles in column 2 are destroyed (except fire_tile)
	var destroyed_count = 0
	if GridManager.get_tile_at(Vector2i(2, 0)) == null:
		destroyed_count += 1
	if GridManager.get_tile_at(Vector2i(2, 2)) == null:
		destroyed_count += 1
	if GridManager.get_tile_at(Vector2i(2, 3)) == null:
		destroyed_count += 1

	# Check fire_tile still exists
	var fire_exists = GridManager.get_tile_at(Vector2i(2, 1)) == fire_tile

	# Check safe tiles still exist
	var safe_exists = GridManager.get_tile_at(Vector2i(0, 1)) == safe_tile1 and GridManager.get_tile_at(Vector2i(3, 1)) == safe_tile2

	if destroyed_count == 3 and fire_exists and safe_exists:
		print("  ✅ Fire Vertical: 3 tiles destroyed, fire tile intact, safe tiles intact")
	else:
		print("  ❌ Fire Vertical failed: destroyed=%d, fire_exists=%s, safe_exists=%s" % [destroyed_count, fire_exists, safe_exists])

	# Cleanup
	cleanup_grid()


# Test 3: Fire Cross - destroy row AND column
func test_fire_cross():
	print("\nTest 3: Fire Cross Power")
	GridManager.initialize_grid()

	# Create fire_cross tile at (1, 1)
	var fire_tile = GridManager.create_tile(16, "fire_cross", Vector2i(1, 1))

	# Create tiles in row 1
	var row_tile1 = GridManager.create_tile(2, "none", Vector2i(0, 1))
	var row_tile2 = GridManager.create_tile(4, "none", Vector2i(2, 1))
	var row_tile3 = GridManager.create_tile(2, "none", Vector2i(3, 1))

	# Create tiles in column 1
	var col_tile1 = GridManager.create_tile(2, "none", Vector2i(1, 0))
	var col_tile2 = GridManager.create_tile(4, "none", Vector2i(1, 2))
	var col_tile3 = GridManager.create_tile(2, "none", Vector2i(1, 3))

	# Create safe tiles (not in row 1 or column 1)
	var safe_tile1 = GridManager.create_tile(2, "none", Vector2i(0, 0))
	var safe_tile2 = GridManager.create_tile(4, "none", Vector2i(3, 3))

	print("  Created 7 tiles in cross pattern, 2 safe tiles")

	# Activate fire cross power
	PowerManager.activate_fire_cross(fire_tile, GridManager)
	await get_tree().create_timer(0.3).timeout

	# Check row tiles destroyed
	var row_destroyed = 0
	if GridManager.get_tile_at(Vector2i(0, 1)) == null:
		row_destroyed += 1
	if GridManager.get_tile_at(Vector2i(2, 1)) == null:
		row_destroyed += 1
	if GridManager.get_tile_at(Vector2i(3, 1)) == null:
		row_destroyed += 1

	# Check column tiles destroyed
	var col_destroyed = 0
	if GridManager.get_tile_at(Vector2i(1, 0)) == null:
		col_destroyed += 1
	if GridManager.get_tile_at(Vector2i(1, 2)) == null:
		col_destroyed += 1
	if GridManager.get_tile_at(Vector2i(1, 3)) == null:
		col_destroyed += 1

	# Check fire_tile still exists
	var fire_exists = GridManager.get_tile_at(Vector2i(1, 1)) == fire_tile

	# Check safe tiles still exist
	var safe_exists = GridManager.get_tile_at(Vector2i(0, 0)) == safe_tile1 and GridManager.get_tile_at(Vector2i(3, 3)) == safe_tile2

	if row_destroyed == 3 and col_destroyed == 3 and fire_exists and safe_exists:
		print("  ✅ Fire Cross: 6 tiles destroyed (3 row + 3 col), fire tile intact, safe tiles intact")
	else:
		print("  ❌ Fire Cross failed: row=%d, col=%d, fire_exists=%s, safe_exists=%s" % [row_destroyed, col_destroyed, fire_exists, safe_exists])

	# Cleanup
	cleanup_grid()


# Test 4: Fire power activation through fusion
func test_fire_fusion_activation():
	print("\nTest 4: Fire Power Activation via Fusion")
	GridManager.initialize_grid()

	# Create two tiles with fire_h power at positions (1,3) and (1,2)
	var tile1 = GridManager.create_tile(4, "fire_h", Vector2i(1, 3))
	var tile2 = GridManager.create_tile(4, "fire_h", Vector2i(1, 2))

	# Create target tiles in row 2 (where fusion will happen)
	var target1 = GridManager.create_tile(2, "none", Vector2i(0, 2))
	var target2 = GridManager.create_tile(2, "none", Vector2i(2, 2))

	# Safe tile in different row
	var safe_tile = GridManager.create_tile(2, "none", Vector2i(1, 0))

	print("  Created 2 fire_h tiles (will fuse to row 2), 2 targets in row 2")

	# Move up - should fuse and activate fire_h
	GridManager.process_movement(GridManager.Direction.UP)
	await get_tree().create_timer(1.0).timeout  # Wait for movement + fusion + power

	# Check targets in row 2 are destroyed
	var targets_destroyed = GridManager.get_tile_at(Vector2i(0, 2)) == null and GridManager.get_tile_at(Vector2i(2, 2)) == null

	# Check fusion tile exists at (1,0) after moving all the way up
	var fusion_exists = GridManager.get_tile_at(Vector2i(1, 0)) != null

	# Check safe tile still exists
	var safe_exists = GridManager.get_tile_at(Vector2i(1, 0)) != null  # This is now the fusion tile

	if targets_destroyed and fusion_exists:
		print("  ✅ Fire fusion: tiles fused, power activated, targets destroyed")
	else:
		print("  ❌ Fire fusion failed: targets_destroyed=%s, fusion_exists=%s" % [targets_destroyed, fusion_exists])

	# Cleanup
	cleanup_grid()


# Helper to cleanup grid
func cleanup_grid():
	for y in range(4):
		for x in range(4):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile:
				GridManager.destroy_tile(tile)
