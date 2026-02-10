extends Node

# Demo script for testing the new immediate architecture
# Run this scene to see the architecture working

# Import MovementData for testing
const MovementData = preload("res://managers/MovementData.gd")

func _ready():
	print("\n🚀 === DEMONSTRATION NOUVELLE ARCHITECTURE ===")
	await get_tree().process_frame  # Wait for autoloads to be ready
	
	print("\n🧪 Test 1: Création des structures de données...")
	test_movement_data_creation()
	
	print("\n⚡ Test 2: Calculs d'effets de pouvoirs...")
	test_power_calculations()
	
	print("\n🎬 Test 3: Gestion des animations...")
	test_animation_management()
	
	print("\n✅ === DEMONSTRATION TERMINÉE ===")

func test_movement_data_creation():
	# Test MovementResult
	var result = MovementData.MovementResult.new()
	print("  ✓ MovementResult créé")
	
	# Test PowerEffectData
	var bomb_effect = MovementData.PowerEffectData.new("bomb", null, Vector2i(1, 1))
	print("  ✓ PowerEffectData créé pour 'bomb'")
	
	# Test MovedTileData
	var moved_data = MovementData.MovedTileData.new(null, Vector2i(0, 0), Vector2i(1, 0))
	print("  ✓ MovedTileData créé")
	
	# Test FusionData
	var fusion_data = MovementData.FusionData.new(null, null, null, Vector2i(1, 1), "fire")
	print("  ✓ FusionData créé")
	
	print("  🎯 Toutes les structures de données fonctionnent !")

func test_power_calculations():
	print("  🔥 Test bomb effect:")
	var bomb_effect = PowerManager.calculate_power_effect("bomb", Vector2i(1, 1), null)
	print("    - Type: %s" % bomb_effect.power_type)
	print("    - Positions affectées: %d" % bomb_effect.affected_positions.size())
	for pos in bomb_effect.affected_positions:
		print("      → %s" % pos)
	
	print("  🔥 Test fire_cross effect:")
	var fire_effect = PowerManager.calculate_power_effect("fire_cross", Vector2i(2, 2), null)
	print("    - Type: %s" % fire_effect.power_type)
	print("    - Positions affectées: %d" % fire_effect.affected_positions.size())
	print("    - Premières positions: %s, %s" % [fire_effect.affected_positions[0], fire_effect.affected_positions[1]])
	
	print("  🧊 Test ice effect:")
	var ice_effect = PowerManager.calculate_power_effect("ice", Vector2i(0, 0), null)
	print("    - Type: %s" % ice_effect.power_type)
	print("    - Durée: %d tours" % ice_effect.duration)
	
	print("  🎯 Tous les calculs de pouvoirs fonctionnent !")

func test_animation_management():
	# Test group status
	var is_active_before = AnimationManager.is_group_active("test_group")
	print("  📊 Groupe 'test_group' actif avant: %s" % is_active_before)
	
	# Test cancellation (should not error even if group doesn't exist)
	AnimationManager.cancel_animation_group("test_group")
	print("  🚫 Annulation de groupe testée")
	
	# Test status after cancellation
	var is_active_after = AnimationManager.is_group_active("test_group")
	print("  📊 Groupe 'test_group' actif après: %s" % is_active_after)
	
	print("  🎯 Gestion des animations fonctionnelle !")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("\n👋 Fermeture du test...")
		get_tree().quit()