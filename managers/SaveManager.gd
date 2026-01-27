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
	# Build grid state
	var grid_state = []
	for y in range(GridManager.grid_size):
		var row = []
		for x in range(GridManager.grid_size):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile != null:
				row.append({
					"value":    tile.value,
					"power":    tile.power_type,
					"frozen":   tile.is_frozen if tile.has_method("is_frozen") else false,
					"frozen_turns": tile.freeze_turns if tile.get("freeze_turns") else 0
				})
			else:
				row.append(null)
		grid_state.append(row)
	
	var save_data = {
		"version":           "1.0",
		"timestamp":         Time.get_datetime_string_from_system(),
		"score":             ScoreManager.get_current_score(),
		"moves":             GridManager.move_count,
		"grid":              grid_state,
		"frozen_directions": GridManager.frozen_directions.duplicate(),
		"blind_mode":        GridManager.blind_mode,
		"blind_turns":       GridManager.blind_turns
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
func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("❌ No saved game to load")
		return {}

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		print("❌ Failed to open save file")
		return {}

	var json_string  = file.get_as_text()
	file.close()

	var json         = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result == OK:
		print("✅ Game loaded")
		return json.data
	else:
		print("❌ Failed to parse save file")
		return {}


# Restore game state from loaded data
func restore_game(data: Dictionary):
	if data.is_empty():
		return false
	
	# Clear current grid
	GridManager.initialize_grid()
	
	# Restore score
	ScoreManager.current_score = data.get("score", 0)
	
	# Restore move count
	GridManager.move_count = data.get("moves", 0)
	
	# Restore frozen directions
	var frozen_dirs = data.get("frozen_directions", {})
	GridManager.frozen_directions.clear()
	for dir_key in frozen_dirs.keys():
		GridManager.frozen_directions[int(dir_key)] = frozen_dirs[dir_key]
	
	# Restore blind mode
	GridManager.blind_mode  = data.get("blind_mode", false)
	GridManager.blind_turns = data.get("blind_turns", 0)
	
	# Restore grid tiles
	var grid_data = data.get("grid", [])
	for y in range(grid_data.size()):
		for x in range(grid_data[y].size()):
			var tile_data = grid_data[y][x]
			if tile_data != null:
				var tile = GridManager.create_tile(
					tile_data.get("value", 2),
					tile_data.get("power", ""),
					Vector2i(x, y)
				)
				# Restore frozen state
				if tile_data.get("frozen", false) and tile.has_method("set_frozen"):
					tile.set_frozen(true, tile_data.get("frozen_turns", 0))
	
	print("✅ Game state restored")
	return true


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
func has_save():
	return has_saved_game
