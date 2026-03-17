# SaveManager for Fusion Mania
# Reviewed
extends Node

const SAVE_FILE = "user://fusion_mania_game.save"

var has_saved_game: bool 		= false
var game_data: 		Dictionary 	= {}

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
					"value":		tile.value,
					"power":		tile.power_type,
					"iced":			tile.is_iced if tile.has_method("is_iced") else false,
					"ice_turns": 	tile.ice_turns if tile.get("ice_turns") else 0
				})
			else:
				row.append(null)
		grid_state.append(row)

	var save_data = {
		"version":		"1.0",
		"timestamp":	Time.get_datetime_string_from_system(),
		"score":		ScoreManager.get_current_score(),
		"moves":		GridManager.move_count,
		"grid":			grid_state,
		"powers":		GameManager.powers.duplicate(true),
		"enemy":		EnemyManager.get_save_data()
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
func restore_game(data):
	if data.is_empty():
		return false

	# Clear current grid
	GridManager.initialize_grid()

	# Restore score
	ScoreManager.current_score = data.get("score", 0)

	# Restore move count
	GridManager.move_count = data.get("moves", 0)

	# Restore powers
	var saved_powers = data.get("powers", {})

	if not saved_powers.is_empty():
		for power_key in saved_powers.keys():
			if GameManager.powers.has(power_key) and typeof(saved_powers[power_key]) == TYPE_DICTIONARY:
				GameManager.powers[power_key] = saved_powers[power_key].duplicate()

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
				if tile_data.get("iced", false) and tile.has_method("set_iced"):
					tile.set_iced(true, tile_data.get("ice_turns", 0))

	# Restore enemy state
	var enemy_data = data.get("enemy", {})

	if not enemy_data.is_empty():
		EnemyManager.load_save_data(enemy_data)

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
	if GameManager.is_state_playing():
		save_game()


# Check if saved game exists
func has_save():
	return has_saved_game


# Initialize game session data
func init_game_session():
	game_data = {
		"started_at":	Time.get_datetime_string_from_system(),
		"moves": 		0,
		"tiles":		[]
	}


# End the game and finalize game data
func end_game(victory: bool):
	var final_score = ScoreManager.get_current_score()
	var rank 		= ScoreManager.add_score(final_score)

	game_data["ended_at"] 		= Time.get_datetime_string_from_system()
	game_data["final_score"] 	= final_score
	game_data["victory"] 		= victory
	game_data["rank"] 			= rank


# Get game infos
func get_game_infos():
	return game_data.duplicate()
