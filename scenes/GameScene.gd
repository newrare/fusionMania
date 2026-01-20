# GameScene for Fusion Mania
# Main game scene controller (placeholder for Phase 5)
extends CanvasLayer

func _ready():
	print("\n=== Fusion Mania Game Started ===\n")
	test_managers()


func test_managers():
	print("🎮 Testing all managers:\n")

	# Audio
	print("🎵 AudioManager:")
	print("  - Is music enabled: %s" % AudioManager.is_music_enabled())
	print("  - Is SFX enabled: %s" % AudioManager.is_sfx_enabled())

	# Language
	print("\n🌍 LanguageManager:")
	print("  - Current language: %s" % LanguageManager.get_current_language())
	print("  - Available languages: %d" % LanguageManager.available_languages.size())

	# Score
	print("\n🏆 ScoreManager:")
	print("  - High scores loaded: %d" % ScoreManager.get_high_scores().size())
	print("  - High score: %d" % ScoreManager.get_high_score())

	# Game
	print("\n🎯 GameManager:")
	print("  - Current state: %s" % GameManager.GameState.keys()[GameManager.current_state])

	# Grid
	print("\n🎲 GridManager:")
	print("  - Grid size: %dx%d" % [GridManager.grid_size, GridManager.grid_size])

	# Power
	print("\n⚡ PowerManager:")
	print("  - Powers available: %d" % PowerManager.POWER_DATA.size())

	# Save
	print("\n💾 SaveManager:")
	print("  - Has saved game: %s" % SaveManager.has_save())

	# Tools
	print("\n🔧 ToolsManager:")
	print("  - Is mobile: %s" % ToolsManager.get_is_mobile())
	print("  - Platform: %s" % OS.get_name())

	print("\n=== All managers ready! ===\n")
