extends Node

# Test script to verify grid initialization and clear_all_tile_powers

func _ready():
	print("\n🧪 Testing grid initialization and clear_all_tile_powers...")
	await get_tree().process_frame  # Wait for autoloads
	
	# Test 1: Verify grid is initialized
	test_grid_initialization()
	
	# Test 2: Test get_tile_at with various positions
	test_get_tile_at()
	
	# Test 3: Test clear_all_tile_powers
	test_clear_all_tile_powers()
	
	print("\n✅ All grid tests completed!")
	
	# Auto quit after testing
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func test_grid_initialization():
	print("\n📋 Test 1: Grid initialization")
	
	# Check if grid exists
	if GridManager.grid == null:
		print("  ❌ Grid is null!")
		return
	
	print("  ✓ Grid exists")
	print("  ✓ Grid size: %dx%d" % [GridManager.grid.size(), GridManager.grid_size])
	
	# Check grid structure
	for y in range(GridManager.grid_size):
		if y >= GridManager.grid.size() or GridManager.grid[y] == null:
			print("  ❌ Row %d missing!" % y)
			return
		if GridManager.grid[y].size() != GridManager.grid_size:
			print("  ❌ Row %d has wrong size: %d" % [y, GridManager.grid[y].size()])
			return
	
	print("  ✓ Grid structure is correct")

func test_get_tile_at():
	print("\n🎯 Test 2: get_tile_at function")
	
	# Test valid positions
	for y in range(GridManager.grid_size):
		for x in range(GridManager.grid_size):
			var pos = Vector2i(x, y)
			var result = GridManager.get_tile_at(pos)
			# Should return null (empty) but not crash
			print("  ✓ Position %s -> %s" % [pos, "null" if result == null else "tile"])
	
	# Test invalid positions
	var invalid_positions = [
		Vector2i(-1, 0),
		Vector2i(0, -1),
		Vector2i(4, 0),
		Vector2i(0, 4),
		Vector2i(5, 5)
	]
	
	for pos in invalid_positions:
		var result = GridManager.get_tile_at(pos)
		if result != null:
			print("  ❌ Invalid position %s should return null!" % pos)
		else:
			print("  ✓ Invalid position %s correctly returns null" % pos)

func test_clear_all_tile_powers():
	print("\n🧹 Test 3: clear_all_tile_powers")
	
	# Call the function that was causing the error
	try_clear_all_tile_powers()

func try_clear_all_tile_powers():
	# Simply call the function - if it crashes, we'll see the error
	GameManager.clear_all_tile_powers()
	print("  ✅ clear_all_tile_powers executed successfully!")