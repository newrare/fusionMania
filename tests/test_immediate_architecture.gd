extends Node

## Test script for immediate architecture validation
## Run this in Godot to test the new architecture

func _ready():
	print("🧪 Testing immediate architecture...")
	await get_tree().process_frame  # Wait for autoloads to be ready
	test_power_effect_calculation()
	test_movement_data_structures()
	test_animation_manager()

func test_power_effect_calculation():
	print("\n=== Testing Power Effect Calculation ===")
	
	# Test fire horizontal power
	var fire_h_effect = PowerManager.calculate_power_effect("fire_h", Vector2i(1, 2), null)
	print("Fire H effect: %d affected positions" % fire_h_effect.affected_positions.size())
	print("  Expected: 3 positions (0,2), (2,2), (3,2)")
	for pos in fire_h_effect.affected_positions:
		print("  - %s" % pos)
	
	# Test bomb power
	var bomb_effect = PowerManager.calculate_power_effect("bomb", Vector2i(1, 1), null)
	print("Bomb effect: %d affected positions" % bomb_effect.affected_positions.size())
	print("  Expected: 4 positions (adjacent to 1,1)")
	for pos in bomb_effect.affected_positions:
		print("  - %s" % pos)
	
	# Test block power
	var block_effect = PowerManager.calculate_power_effect("block_up", Vector2i(0, 0), null)
	print("Block UP effect: %d blocked directions, duration: %d" % [block_effect.blocked_directions.size(), block_effect.duration])

func test_movement_data_structures():
	print("\n=== Testing Movement Data Structures ===")
	
	# Create a movement result
	var result = MovementData.MovementResult.new()
	
	# Add moved tile
	var moved_tile = MovementData.MovedTileData.new(null, Vector2i(0, 0), Vector2i(1, 0))
	result.moved_tiles.append(moved_tile)
	print("Added moved tile: %s -> %s" % [moved_tile.from_position, moved_tile.to_position])
	
	# Add fusion
	var fusion = MovementData.FusionData.new(null, null, Vector2i(2, 2), 8, "fire_h")
	result.fusions.append(fusion)
	print("Added fusion: value %d, power %s at %s" % [fusion.new_value, fusion.new_power, fusion.position])
	
	# Add power effect
	var power_effect = MovementData.PowerEffectData.new("bomb", null, Vector2i(1, 1))
	power_effect.affected_positions = [Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 0), Vector2i(1, 2)]
	result.power_effects.append(power_effect)
	print("Added power effect: %s affecting %d positions" % [power_effect.power_type, power_effect.affected_positions.size()])
	
	print("Movement result summary:")
	print("  - %d moved tiles" % result.moved_tiles.size())
	print("  - %d fusions" % result.fusions.size())
	print("  - %d power effects" % result.power_effects.size())

func test_animation_manager():
	print("\n=== Testing Animation Manager ===")
	
	# Create sample animations
	var tween1 = create_tween()
	var tween2 = create_tween()
	
	AnimationManager.register_animation("movement", tween1)
	AnimationManager.register_animation("movement", tween2)
	print("Registered 2 animations in 'movement' group")
	
	# Test cancellation
	AnimationManager.cancel_animation_group("movement")
	print("Cancelled 'movement' group animations")
	
	# Test animation creation helper
	var test_node = Node2D.new()
	add_child(test_node)
	
	var movement_animation = AnimationManager.create_movement_animation(test_node, Vector2.ZERO, Vector2(100, 100))
	if movement_animation:
		print("Created movement animation successfully")
	else:
		print("Failed to create movement animation")
	
	test_node.queue_free()

func _exit_tree():
	print("🧪 Test completed")