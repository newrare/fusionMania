# Test script for GameManager
extends Node2D

var received_signals: Array = []

func _ready():
	print("\n=== GameManager Tests ===\n")

	# Connect signals to track them
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	GameManager.game_ended.connect(_on_game_ended)

	# Give managers time to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	test_initial_state()
	test_state_transitions()
	test_new_game()
	test_pause_resume()
	test_game_over()
	test_game_data()

	print("\n=== All GameManager Tests Complete ===\n")
	get_tree().quit()


# Test 1: Initial state
func test_initial_state():
	print("Test 1: Initial State")

	var state = GameManager.get_current_state()
	if state == GameManager.GameState.MENU:
		print("  ✅ Initial state is MENU")
	else:
		print("  ❌ Expected MENU state, got: %s" % GameManager.GameState.keys()[state])

	if GameManager.is_in_menu():
		print("  ✅ is_in_menu() returns true")
	else:
		print("  ❌ is_in_menu() should return true")

	var game_data = GameManager.get_game_state()
	if game_data.is_empty():
		print("  ✅ Game data initially empty")
	else:
		print("  ⚠️ Game data not empty: %s" % game_data)


# Test 2: State transitions
func test_state_transitions():
	print("\nTest 2: State Transitions")

	received_signals.clear()

	# MENU -> PLAYING
	GameManager.change_state(GameManager.GameState.PLAYING)
	await get_tree().process_frame

	if "state_changed" in received_signals:
		print("  ✅ state_changed signal emitted")
	else:
		print("  ❌ state_changed signal not emitted")

	if GameManager.is_playing():
		print("  ✅ State changed to PLAYING")
	else:
		print("  ❌ State should be PLAYING")

	# PLAYING -> PAUSED
	received_signals.clear()
	GameManager.change_state(GameManager.GameState.PAUSED)
	await get_tree().process_frame

	if GameManager.is_paused():
		print("  ✅ State changed to PAUSED")
	else:
		print("  ❌ State should be PAUSED")

	# PAUSED -> GAME_OVER
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	await get_tree().process_frame

	if GameManager.is_game_over():
		print("  ✅ State changed to GAME_OVER")
	else:
		print("  ❌ State should be GAME_OVER")

	# Reset to MENU
	GameManager.change_state(GameManager.GameState.MENU)
	await get_tree().process_frame


# Test 3: New game
func test_new_game():
	print("\nTest 3: New Game")

	received_signals.clear()
	GameManager.start_new_game()
	await get_tree().process_frame

	if "game_started" in received_signals:
		print("  ✅ game_started signal emitted")
	else:
		print("  ❌ game_started signal not emitted")

	if GameManager.is_playing():
		print("  ✅ Game state is PLAYING after start")
	else:
		print("  ❌ Should be PLAYING after start_new_game()")

	var game_data = GameManager.get_game_state()
	if game_data.has("started_at"):
		print("  ✅ Game data has started_at timestamp")
	else:
		print("  ❌ Game data missing started_at")

	if game_data.has("moves") and game_data["moves"] == 0:
		print("  ✅ Moves counter initialized to 0")
	else:
		print("  ❌ Moves counter not properly initialized")

	if ScoreManager.get_current_score() == 0:
		print("  ✅ Score reset to 0")
	else:
		print("  ❌ Score should be 0 at game start")


# Test 4: Pause and resume
func test_pause_resume():
	print("\nTest 4: Pause and Resume")

	# Ensure we're playing
	if not GameManager.is_playing():
		GameManager.start_new_game()
		await get_tree().process_frame

	# Test pause
	received_signals.clear()
	GameManager.pause_game()
	await get_tree().process_frame

	if "game_paused" in received_signals:
		print("  ✅ game_paused signal emitted")
	else:
		print("  ❌ game_paused signal not emitted")

	if GameManager.is_paused():
		print("  ✅ Game is paused")
	else:
		print("  ❌ Game should be paused")

	# Test resume
	received_signals.clear()
	GameManager.resume_game()
	await get_tree().process_frame

	if "game_resumed" in received_signals:
		print("  ✅ game_resumed signal emitted")
	else:
		print("  ❌ game_resumed signal not emitted")

	if GameManager.is_playing():
		print("  ✅ Game resumed to PLAYING")
	else:
		print("  ❌ Game should be PLAYING after resume")


# Test 5: Game over
func test_game_over():
	print("\nTest 5: Game Over")

	# Set up a game with score
	GameManager.start_new_game()
	await get_tree().process_frame
	ScoreManager.add_to_score(100)

	# Test victory
	received_signals.clear()
	GameManager.end_game(true)
	await get_tree().process_frame

	if "game_ended" in received_signals:
		print("  ✅ game_ended signal emitted")
	else:
		print("  ❌ game_ended signal not emitted")

	if GameManager.is_game_over():
		print("  ✅ Game state is GAME_OVER")
	else:
		print("  ❌ State should be GAME_OVER")

	var game_data = GameManager.get_game_state()
	if game_data.has("victory") and game_data["victory"] == true:
		print("  ✅ Victory flag set correctly")
	else:
		print("  ❌ Victory flag not set")

	if game_data.has("final_score") and game_data["final_score"] == 100:
		print("  ✅ Final score saved (100)")
	else:
		print("  ❌ Final score not saved correctly")

	if game_data.has("ended_at"):
		print("  ✅ End timestamp recorded")
	else:
		print("  ❌ End timestamp missing")

	# Test defeat
	GameManager.start_new_game()
	await get_tree().process_frame
	GameManager.end_game(false)
	await get_tree().process_frame

	var defeat_data = GameManager.get_game_state()
	if defeat_data.has("victory") and defeat_data["victory"] == false:
		print("  ✅ Defeat flag set correctly")
	else:
		print("  ❌ Defeat flag not set")


# Test 6: Game data manipulation
func test_game_data():
	print("\nTest 6: Game Data")

	GameManager.start_new_game()
	await get_tree().process_frame

	# Test increment moves
	var initial_moves = GameManager.get_game_state()["moves"]
	GameManager.increment_moves()
	var after_moves = GameManager.get_game_state()["moves"]

	if after_moves == initial_moves + 1:
		print("  ✅ increment_moves() works")
	else:
		print("  ❌ Moves not incremented correctly")

	# Test update game data
	GameManager.update_game_data("custom_key", "custom_value")
	var game_data = GameManager.get_game_state()

	if game_data.has("custom_key") and game_data["custom_key"] == "custom_value":
		print("  ✅ update_game_data() works")
	else:
		print("  ❌ Custom data not saved")

	# Test return to menu
	GameManager.return_to_menu()
	await get_tree().process_frame

	if GameManager.is_in_menu():
		print("  ✅ return_to_menu() works")
	else:
		print("  ❌ Should return to MENU state")


# Signal handlers
func _on_state_changed(new_state):
	received_signals.append("state_changed")

func _on_game_started():
	received_signals.append("game_started")

func _on_game_paused():
	received_signals.append("game_paused")

func _on_game_resumed():
	received_signals.append("game_resumed")

func _on_game_ended(victory: bool):
	received_signals.append("game_ended")
