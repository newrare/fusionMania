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

# ============================
# Persistent Power States
# ============================
var blind_turns_remaining: int = 0
var is_blind_active: bool = false
var blocked_directions: Dictionary = {}  # {Direction: turns_remaining}

# Constants for power durations
const DEFAULT_BLIND_TURNS: int = 3
const DEFAULT_BLOCK_TURNS: int = 3

# Signals
signal state_changed(new_state: GameState)
signal game_started()
signal game_paused()
signal game_resumed()
signal game_ended(victory: bool)
signal blind_started()
signal blind_ended()
signal direction_blocked(direction: int, turns: int)
signal direction_unblocked(direction: int)

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
	# Reset persistent power states
	reset_power_states()

	# Reset game data
	game_data = {
		"started_at": Time.get_datetime_string_from_system(),
		"moves":      0,
		"tiles":      []
	}

	# Reset score and grid (this clears visual tiles and spawns new ones)
	ScoreManager.start_game()
	GridManager.start_new_game()

	# Change state
	change_state(GameState.PLAYING)
	game_started.emit()

	print("🎮 New game started")


# Reset all persistent power states
func reset_power_states():
	blind_turns_remaining = 0
	is_blind_active = false
	blocked_directions.clear()
	print("🔄 Power states reset")


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
func is_playing():
	return current_state == GameState.PLAYING


# Check if paused
func is_paused():
	return current_state == GameState.PAUSED


# Check if in menu
func is_in_menu():
	return current_state == GameState.MENU


# Check if game over
func is_game_over():
	return current_state == GameState.GAME_OVER


# Get current state
func get_current_state():
	return current_state


# ============================
# Persistent Power Methods
# ============================

# Activate blind mode (or reset if already active)
func activate_blind(turns: int = DEFAULT_BLIND_TURNS):
	if is_blind_active:
		# Already active: reset counter to default
		blind_turns_remaining = turns
		print("👁️ Blind mode reset to %d turns" % turns)
	else:
		is_blind_active = true
		blind_turns_remaining = turns
		blind_started.emit()
		print("👁️ Blind mode activated for %d turns" % turns)


# Decrement blind counter (called after each move)
func decrement_blind_counter():
	if is_blind_active and blind_turns_remaining > 0:
		blind_turns_remaining -= 1
		print("👁️ Blind mode: %d movements remaining" % blind_turns_remaining)

		if blind_turns_remaining <= 0:
			is_blind_active = false
			blind_ended.emit()
			print("👁️ Blind mode ended")


# Check if blind is active
func is_blind_mode_active():
	return is_blind_active


# Block a direction (or reset if already blocked)
func block_direction(direction: int, turns: int = DEFAULT_BLOCK_TURNS):
	if blocked_directions.has(direction):
		# Already blocked: reset counter
		blocked_directions[direction] = turns
		print("🧊 Direction %d block reset to %d turns" % [direction, turns])
	else:
		blocked_directions[direction] = turns
		direction_blocked.emit(direction, turns)
		print("🧊 Direction %d blocked for %d turns" % [direction, turns])


# Decrement all blocked direction counters (called after each move)
func decrement_blocked_counters():
	var to_remove = []

	for dir in blocked_directions.keys():
		blocked_directions[dir] -= 1
		print("🧊 Direction %d: %d movements remaining" % [dir, blocked_directions[dir]])

		if blocked_directions[dir] <= 0:
			to_remove.append(dir)

	for dir in to_remove:
		blocked_directions.erase(dir)
		direction_unblocked.emit(dir)
		print("🧊 Direction %d unblocked" % dir)


# Check if a direction is blocked
func is_direction_blocked(direction: int):
	return blocked_directions.has(direction) and blocked_directions[direction] > 0


# Decrement ice counters for all tiles on the grid
func decrement_tile_ice_counters():
	for y in range(GridManager.grid_size):
		for x in range(GridManager.grid_size):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile != null and tile.ice_turns > 0:
				tile.ice_turns -= 1
				if tile.ice_turns == 0:
					tile.remove_ice_effect()


# Decrement all power counters (called after each move)
func decrement_power_counters():
	decrement_blind_counter()
	decrement_blocked_counters()
	decrement_tile_ice_counters()
