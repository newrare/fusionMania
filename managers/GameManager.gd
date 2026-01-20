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
	change_state(GameState.PLAYING)
	game_started.emit()


# Pause the game
func pause_game():
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		game_paused.emit()


# Resume the game
func resume_game():
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		game_resumed.emit()


# End the game
func end_game(victory: bool):
	change_state(GameState.GAME_OVER)
	game_ended.emit(victory)


# Check if currently playing
func is_playing() -> bool:
	return current_state == GameState.PLAYING


# Check if paused
func is_paused() -> bool:
	return current_state == GameState.PAUSED


# Check if in menu
func is_in_menu() -> bool:
	return current_state == GameState.MENU


# Get current state
func get_current_state() -> GameState:
	return current_state
