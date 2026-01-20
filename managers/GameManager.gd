# GameManager for Fusion Mania
# Central game state manager
extends Node

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var game_data:     Dictionary = {}  # Stores current game session data

# Signals
signal state_changed(new_state: GameState)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_ended(victory: bool)

func _ready():
	print("🎮 GameManager ready")


# Change game state
func change_state(new_state: GameState):
	if current_state == new_state:
		return
	
	current_state = new_state
	state_changed.emit(new_state)
	
	print("Game state changed to: %s" % GameState.keys()[new_state])


# Start a new game
func start_new_game():
	# Reset game data
	game_data = {
		"started_at": Time.get_datetime_string_from_system(),
		"moves":      0,
		"tiles":      []
	}
	
	# Reset score and grid
	ScoreManager.start_game()
	GridManager.initialize_grid()
	
	# Change state
	change_state(GameState.PLAYING)
	game_started.emit()
	
	print("🎮 New game started")


# Pause the game
func pause_game():
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		game_paused.emit()
		
		print("⏸️ Game paused")


# Resume the game
func resume_game():
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		game_resumed.emit()
		
		print("▶️ Game resumed")


# End the game
func end_game(victory: bool):
	# Save final score
	var final_score = ScoreManager.get_current_score()
	var rank        = ScoreManager.add_score(final_score)
	
	game_data["ended_at"]     = Time.get_datetime_string_from_system()
	game_data["final_score"]  = final_score
	game_data["victory"]      = victory
	game_data["rank"]         = rank
	
	# Change state
	change_state(GameState.GAME_OVER)
	game_ended.emit(victory)
	
	if victory:
		print("🏆 Game ended - VICTORY! Score: %d (Rank: %d)" % [final_score, rank])
	else:
		print("💀 Game ended - Game Over. Score: %d (Rank: %d)" % [final_score, rank])


# Return to menu
func return_to_menu():
	change_state(GameState.MENU)
	
	print("🏠 Returned to menu")


# Check if currently playing
func is_playing() -> bool:
	return current_state == GameState.PLAYING


# Check if paused
func is_paused() -> bool:
	return current_state == GameState.PAUSED


# Check if in menu
func is_in_menu() -> bool:
	return current_state == GameState.MENU


# Check if game over
func is_game_over() -> bool:
	return current_state == GameState.GAME_OVER


# Get current state
func get_current_state() -> GameState:
	return current_state


# Get current game data
func get_game_state() -> Dictionary:
	return game_data


# Increment move counter
func increment_moves():
	if game_data.has("moves"):
		game_data["moves"] += 1


# Update game data with grid state
func update_game_data(key: String, value):
	game_data[key] = value
