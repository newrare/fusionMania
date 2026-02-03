extends Node2D

# Test script for Tile object

func _ready():
	print("\n=== Testing Tile System ===\n")

	# Test 1: Create a simple tile with value 2
	test_tile_creation()

	# Test 2: Test spawn animation
	await get_tree().create_timer(0.5).timeout
	test_spawn_animation()

	# Test 3: Test color change with different values
	await get_tree().create_timer(0.5).timeout
	test_color_changes()

	# Test 4: Test tile with power
	await get_tree().create_timer(0.5).timeout
	test_tile_with_power()

	# Test 5: Test ice effect
	await get_tree().create_timer(0.5).timeout
	test_ice_effect()

	# Test 6: Test merge
	await get_tree().create_timer(0.5).timeout
	test_tile_merge()

	print("\n=== All Tile Tests Completed ===\n")


# Test 1: Create tile with value 2
func test_tile_creation():
	print("📝 Test 1: Create tile with value 2")

	var tile = preload("res://objects/Tile.tscn").instantiate()
	tile.initialize(2, "", Vector2i(0, 0))
	tile.position = Vector2(100, 100)
	add_child(tile)

	print("  ✅ Tile created: %s" % tile)
	print("  ✅ Value: %d" % tile.value)
	print("  ✅ Color should be white")


# Test 2: Test spawn animation
func test_spawn_animation():
	print("\n📝 Test 2: Test spawn animation")

	var tile = preload("res://objects/Tile.tscn").instantiate()
	tile.position = Vector2(400, 100)
	add_child(tile)
	tile.initialize(4, "", Vector2i(1, 0))

	print("  ✅ Spawn animation should be visible (scale 0→1)")


# Test 3: Test color changes with different values
func test_color_changes():
	print("\n📝 Test 3: Test color changes")

	var test_values = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
	var x_offset = 100

	for i in range(min(5, test_values.size())):
		var tile = preload("res://objects/Tile.tscn").instantiate()
		tile.initialize(test_values[i], "", Vector2i(i, 1))
		tile.position = Vector2(x_offset + i * 260, 400)
		add_child(tile)
		print("  ✅ Tile value %d created with color" % test_values[i])


# Test 4: Test tile with power
func test_tile_with_power():
	print("\n📝 Test 4: Test tile with power")

	var tile = preload("res://objects/Tile.tscn").instantiate()
	tile.initialize(8, "fire_h", Vector2i(0, 2))
	tile.position = Vector2(100, 700)
	add_child(tile)

	print("  ✅ Tile with fire_h power created")
	print("  ✅ Power icon should be visible: %s" % tile.power_icon.visible)


# Test 5: Test ice effect
func test_ice_effect():
	print("\n📝 Test 5: Test ice effect")

	var tile = preload("res://objects/Tile.tscn").instantiate()
	tile.initialize(16, "", Vector2i(1, 2))
	tile.position = Vector2(400, 700)
	add_child(tile)

	# Apply ice
	tile.apply_ice_effect()
	print("  ✅ Ice effect applied (blue tint)")
	print("  ✅ Is iced: %s" % tile.is_iced)

	# Remove ice after 1 second
	await get_tree().create_timer(1.0).timeout
	tile.remove_ice_effect()
	print("  ✅ Ice effect removed")


# Test 6: Test tile merge
func test_tile_merge():
	print("\n📝 Test 6: Test tile merge")

	var tile1 = preload("res://objects/Tile.tscn").instantiate()
	tile1.initialize(32, "bomb", Vector2i(0, 3))
	tile1.position = Vector2(100, 1000)
	add_child(tile1)

	var tile2 = preload("res://objects/Tile.tscn").instantiate()
	tile2.initialize(32, "bomb", Vector2i(1, 3))
	tile2.position = Vector2(400, 1000)
	add_child(tile2)

	print("  ✅ Two tiles created (value 32, power bomb)")
	print("  ✅ Can merge: %s" % tile1.can_merge_with(tile2))

	# Perform merge
	var merge_result = tile1.merge_with(tile2)
	print("  ✅ Merge result:")
	print("    - New value: %d" % merge_result.value)
	print("    - New power: %s" % merge_result.power)
	print("    - Power activated: %s" % merge_result.power_activated)

	# Update tile1 and destroy tile2
	tile1.initialize(merge_result.value, merge_result.power, tile1.grid_position)
	tile1.merge_animation()
	tile2.destroy_animation()
