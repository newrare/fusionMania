# SaveManager for Fusion Mania
# Manages game save/load functionality
extends Node

const SAVE_FILE = "user://fusion_mania_game.save"

var has_saved_game: bool = false

func _ready():
	check_for_saved_game()
	print("💾 SaveManager ready")


# Check if a saved game exists
func check_for_saved_game():
	has_saved_game = FileAccess.file_exists(SAVE_FILE)
	if has_saved_game:
		print("✅ Saved game found")
	else:
		print("ℹ️ No saved game")


# Save the current game state
func save_game():
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"score": ScoreManager.get_current_score(),
		"moves": GridManager.move_count,
		# TODO: Save grid state when Tile system is ready
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		has_saved_game = true
		print("✅ Game saved")
		return true
	else:
		print("❌ Failed to save game")
		return false


# Load a saved game
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		print("❌ No saved game to load")
		return {}

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("❌ Failed to open save file")
		return {}

	var json_string		= file.get_as_text()
	file.close()

	var json			= JSON.new()
	var parse_result	= json.parse(json_string)

	if parse_result == OK:
		print("✅ Game loaded")
		return json.data
	else:
		print("❌ Failed to parse save file")
		return {}


# Delete saved game
func delete_save():
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
		has_saved_game = false
		print("🗑️ Saved game deleted")


# Auto-save (called when pausing)
func auto_save():
	if GameManager.is_playing() or GameManager.is_paused():
		save_game()


# Check if saved game exists
func has_save() -> bool:
	return has_saved_game
