# GameScene for Fusion Mania
# Main game scene with grid and overlays
extends Node2D

@onready var grid                     = $Grid
@onready var title_menu               = $TitleMenu
@onready var power_choice_menu        = $PowerChoiceMenu
@onready var options_menu             = $OptionsMenu
@onready var ranking_menu             = $RankingMenu
@onready var game_over_menu           = $GameOverMenu
@onready var score_label              = $ScoreLabel
@onready var move_count_label         = $MoveCountLabel
@onready var power_message_container  = $PowerMessageContainer
@onready var effects_container        = $EffectsContainer
@onready var ui_effect                = $UIEffect
@onready var blind_overlay            = $BlindOverlay

# Swipe detection
var swipe_start:     Vector2 = Vector2.ZERO
var swipe_threshold: float   = 50.0
var is_swiping:      bool    = false

# Move counter
var move_count: int = 0


func _ready():
	print("\n=== Fusion Mania - Game Scene Ready ===\n")
	
	# Add to group for visual effects to find this scene
	add_to_group("game_scene")

	# Setup UIEffect
	ui_effect.set_container(effects_container)

	# Connect to GameManager signals
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_ended.connect(_on_game_ended)

	# Connect to GridManager signals
	GridManager.game_over.connect(_on_grid_game_over)
	GridManager.fusion_occurred.connect(_on_fusion_occurred)
	GridManager.tiles_moved.connect(_on_tiles_moved)

	# Connect to ScoreManager signals
	ScoreManager.score_changed.connect(_on_score_changed)

	# Connect to PowerManager signals
	PowerManager.power_activated.connect(_on_power_activated)
	
	# Connect to GameManager persistent power signals
	GameManager.blind_started.connect(_on_blind_started)
	GameManager.blind_ended.connect(_on_blind_ended)
	GameManager.direction_frozen.connect(_on_direction_frozen)
	GameManager.direction_unfrozen.connect(_on_direction_unfrozen)

	# Connect to TitleMenu signals
	title_menu.new_game_pressed.connect(_on_new_game_pressed)
	title_menu.free_mode_pressed.connect(_on_free_mode_pressed)
	title_menu.resume_pressed.connect(_on_resume_pressed)
	title_menu.ranking_pressed.connect(_on_ranking_pressed)
	title_menu.options_pressed.connect(_on_options_pressed)
	title_menu.quit_pressed.connect(_on_quit_pressed)

	# Connect to PowerChoiceMenu signals
	if power_choice_menu:
		power_choice_menu.powers_selected.connect(_on_powers_selected)
		power_choice_menu.back_pressed.connect(_on_power_choice_back)

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
	power_choice_menu.hide_menu()
	options_menu.hide_menu()
	ranking_menu.hide_menu()
	game_over_menu.hide_menu()


# Title menu signal handlers
func _on_new_game_pressed():
	print("🎮 Starting new game...")
	hide_all_overlays()
	# Reset UI counters
	move_count = 0
	update_move_count()
	update_score_display()
	# Reset PowerManager to default spawn rates
	PowerManager.reset_to_default_spawn_rates()
	GameManager.start_new_game()


func _on_free_mode_pressed():
	print("🎮 Opening Free Mode power selection...")
	title_menu.hide_menu()
	power_choice_menu.show_menu()


func _on_resume_pressed():
	print("▶️ Resuming game...")
	hide_all_overlays()
	var save_data = SaveManager.load_game()
	if not save_data.is_empty():
		SaveManager.restore_game(save_data)
		# Restore move count if saved
		move_count = save_data.get("move_count", 0)
		update_move_count()
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


# PowerChoiceMenu signal handlers
func _on_powers_selected(selected_powers: Array):
	print("🎮 Starting Free Mode with %d selected powers" % selected_powers.size())
	hide_all_overlays()
	# Reset UI counters
	move_count = 0
	update_move_count()
	update_score_display()
	# Set custom spawn rates
	PowerManager.set_custom_spawn_rates(selected_powers)
	GameManager.start_new_game()


func _on_power_choice_back():
	power_choice_menu.hide_menu()
	title_menu.show_menu()


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


# GridManager signal handlers
func _on_fusion_occurred(tile1, tile2, new_tile):
	# Get the world position of the new tile
	var tile_world_pos = grid.position + new_tile.position
	# Show floating score
	ui_effect.show_floating_score(new_tile.value, tile_world_pos)


func _on_tiles_moved():
	# Increment move counter when tiles actually moved
	move_count += 1
	update_move_count()


# ScoreManager signal handlers
func _on_score_changed(new_score: int):
	score_label.text = "Score: %d" % new_score


# PowerManager signal handlers
func _on_power_activated(power_type: String, tile):
	var power = PowerManager.POWERS.get(power_type, {})
	var power_name = power.get("name", power_type)
	ui_effect.show_power_message(power_name, power_message_container)


func _on_blind_started():
	blind_overlay.visible = true
	print("🕶️ Blind overlay activated")


func _on_blind_ended():
	blind_overlay.visible = false
	print("👁️ Blind overlay removed")


# Freeze direction signal handlers
func _on_direction_frozen(direction: int, turns: int):
	print("🧊 Direction %d frozen for %d turns" % [direction, turns])
	# Add visual indicator for frozen direction (via PowerEffect)
	var PowerEffect = preload("res://visuals/PowerEffect.gd")
	PowerEffect.create_wind_effect(direction)
	PowerEffect.create_wind_sprites(direction)


func _on_direction_unfrozen(direction: int):
	print("🧊 Direction %d unfrozen" % direction)
	# Remove visual indicator
	var PowerEffect = preload("res://visuals/PowerEffect.gd")
	PowerEffect.remove_wind_effect(direction)


# Update move count label
func update_move_count():
	move_count_label.text = "Moves: %d" % move_count


# Update score display
func update_score_display():
	score_label.text = "Score: %d" % ScoreManager.get_current_score()


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
