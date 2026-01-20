# GameScene for Fusion Mania
# Main game scene with grid and overlays
extends Node2D

@onready var grid           = $Grid
@onready var title_menu     = $TitleMenu
@onready var options_menu   = $OptionsMenu
@onready var ranking_menu   = $RankingMenu
@onready var game_over_menu = $GameOverMenu

# Swipe detection
var swipe_start:     Vector2 = Vector2.ZERO
var swipe_threshold: float   = 50.0
var is_swiping:      bool    = false


func _ready():
	print("\n=== Fusion Mania - Game Scene Ready ===\n")

	# Connect to GameManager signals
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_ended.connect(_on_game_ended)

	# Connect to GridManager signals
	GridManager.game_over.connect(_on_grid_game_over)

	# Connect to TitleMenu signals
	title_menu.new_game_pressed.connect(_on_new_game_pressed)
	title_menu.resume_pressed.connect(_on_resume_pressed)
	title_menu.ranking_pressed.connect(_on_ranking_pressed)
	title_menu.options_pressed.connect(_on_options_pressed)
	title_menu.quit_pressed.connect(_on_quit_pressed)

	# Connect to OptionsMenu signals
	options_menu.back_pressed.connect(_on_options_back)
	options_menu.ranking_reset.connect(_on_ranking_reset)

	# Connect to RankingMenu signals
	ranking_menu.back_pressed.connect(_on_ranking_back)

	# Connect to GameOverMenu signals
	game_over_menu.new_game_pressed.connect(_on_gameover_new_game)
	game_over_menu.menu_pressed.connect(_on_gameover_menu)

	# Show title menu at start
	title_menu.show_menu()


# Hide all overlays
func hide_all_overlays():
	title_menu.hide_menu()
	options_menu.hide_menu()
	ranking_menu.hide_menu()
	game_over_menu.hide_menu()


# Title menu signal handlers
func _on_new_game_pressed():
	print("🎮 Starting new game...")
	hide_all_overlays()
	GameManager.start_new_game()


func _on_resume_pressed():
	print("▶️ Resuming game...")
	hide_all_overlays()
	var save_data = SaveManager.load_game()
	if not save_data.is_empty():
		SaveManager.restore_game(save_data)
	GameManager.resume_game()


func _on_ranking_pressed():
	print("🏆 Opening ranking...")
	title_menu.hide_menu()
	ranking_menu.show_menu()


func _on_options_pressed():
	print("⚙️ Opening options...")
	title_menu.hide_menu()
	options_menu.show_menu()


func _on_quit_pressed():
	print("👋 Quitting game...")
	get_tree().quit()


# Options menu signal handlers
func _on_options_back():
	options_menu.hide_menu()
	title_menu.show_menu()


func _on_ranking_reset():
	print("🗑️ Ranking reset!")


# Ranking menu signal handlers
func _on_ranking_back():
	ranking_menu.hide_menu()
	title_menu.show_menu()


# GameOver menu signal handlers
func _on_gameover_new_game():
	hide_all_overlays()
	GameManager.start_new_game()


func _on_gameover_menu():
	hide_all_overlays()
	GameManager.return_to_menu()
	title_menu.show_menu()


# GameManager signal handlers
func _on_game_started():
	print("Game started - grid is now playable")
	# Spawn 2 tiles when game starts
	GridManager.spawn_random_tile()
	GridManager.spawn_random_tile()


func _on_grid_game_over():
	print("Grid signal: Game Over detected")
	if GameManager.is_playing():
		var has_reached_2048 = GridManager.has_tile_value(2048)
		GameManager.end_game(has_reached_2048)


func _on_game_paused():
	print("Game paused - showing menu")
	title_menu.show_menu()


func _on_game_ended(victory: bool):
	print("Game ended - victory: %s" % victory)
	game_over_menu.show_menu()


# Handle input
func _input(event):
	# Pause with ESC
	if event.is_action_pressed("ui_cancel"):
		if GameManager.is_playing():
			GameManager.pause_game()
			get_tree().root.set_input_as_handled()
		return

	# Movement only when playing
	if not GameManager.is_playing():
		return

	# Keyboard input
	if event.is_action_pressed("move_up"):
		get_tree().root.set_input_as_handled()
		_process_move(GridManager.Direction.UP)
	elif event.is_action_pressed("move_down"):
		get_tree().root.set_input_as_handled()
		_process_move(GridManager.Direction.DOWN)
	elif event.is_action_pressed("move_left"):
		get_tree().root.set_input_as_handled()
		_process_move(GridManager.Direction.LEFT)
	elif event.is_action_pressed("move_right"):
		get_tree().root.set_input_as_handled()
		_process_move(GridManager.Direction.RIGHT)

	# Touch/Swipe input
	if event is InputEventScreenTouch:
		if event.pressed:
			swipe_start = event.position
			is_swiping  = true
		else:
			is_swiping = false

	if event is InputEventScreenDrag and is_swiping:
		var swipe_delta = event.position - swipe_start
		if swipe_delta.length() > swipe_threshold:
			_process_swipe(swipe_delta)
			is_swiping = false


# Process swipe gesture
func _process_swipe(delta: Vector2):
	if abs(delta.x) > abs(delta.y):
		# Horizontal swipe
		if delta.x > 0:
			_process_move(GridManager.Direction.RIGHT)
		else:
			_process_move(GridManager.Direction.LEFT)
	else:
		# Vertical swipe
		if delta.y > 0:
			_process_move(GridManager.Direction.DOWN)
		else:
			_process_move(GridManager.Direction.UP)


# Process movement
func _process_move(direction: GridManager.Direction):
	await GridManager.process_movement(direction)
