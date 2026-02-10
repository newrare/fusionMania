# GameScene for Fusion Mania
# Main game scene with grid and overlays
extends Node2D

@onready var background_layer         = $BackgroundLayer
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
@onready var enemy_container          = $EnemyContainer

# Background effect manager
var background_effect: Node

# Swipe detection
var swipe_start:     Vector2 = Vector2.ZERO
var swipe_threshold: float   = 50.0
var is_swiping:      bool    = false

# Move counter
var move_count: int = 0

# Enemy spawn protection
var enemy_just_spawned: bool = false

# Track active power ball animations for cancellation
var active_power_animations: Array = []


func _ready():
	# Add to group for visual effects to find this scene
	add_to_group("game_scene")

	# Setup UIEffect
	ui_effect.set_container(effects_container)

	# Initialize background effect
	var BackgroundEffect = preload("res://visuals/BackgroundEffect.gd")
	background_effect = BackgroundEffect.new()
	add_child(background_effect)
	background_effect.initialize(background_layer)

	# Connect to viewport resize
	get_viewport().size_changed.connect(_on_viewport_resized)
	_on_viewport_resized()  # Initial positioning
	_set_minimum_window_size()  # Set minimum window size

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
	GameManager.direction_blocked.connect(_on_direction_blocked)
	GameManager.direction_unblocked.connect(_on_direction_unblocked)

	# Connect to EnemyManager signals (with safety check)
	if EnemyManager != null:
		EnemyManager.enemy_spawned.connect(_on_enemy_spawned)
		EnemyManager.enemy_defeated.connect(_on_enemy_defeated)
		EnemyManager.enemy_damaged.connect(_on_enemy_damaged)
		EnemyManager.enemy_sprite_updated.connect(_on_enemy_sprite_updated)
		EnemyManager.power_ball_animation_requested.connect(_on_power_ball_animation_requested)
		EnemyManager.cancel_power_animations.connect(_on_cancel_power_animations)

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
	_hide_grid()
	title_menu.show_menu()


# Process loop for parallax scrolling
func _process(delta):
	if background_effect:
		background_effect.update(delta)


# Recentrer les éléments quand la fenêtre est redimensionnée
func _on_viewport_resized():
	var viewport_size = get_viewport().get_visible_rect().size
	var offset_x = (viewport_size.x - GameManager.DESIGN_WIDTH) / 2.0
	var offset_y = (viewport_size.y - GameManager.DESIGN_HEIGHT) / 2.0

	# Positionner l'ennemi en haut à droite avec marges (droite: 2%, top: 2%)
	# Le contenu fait 384px de large (sprite width)
	var enemy_content_width = 384
	var margin_right = viewport_size.x * 0.02
	var margin_top = viewport_size.y * 0.02
	# Position X: bord droit du viewport - marge droite - largeur du contenu
	enemy_container.position = Vector2(viewport_size.x - margin_right - enemy_content_width, margin_top)

	# Centrer la grille horizontalement et verticalement
	grid.position = Vector2(10 + offset_x, 430 + offset_y)

	# Centrer le blind overlay
	blind_overlay.offset_left = 10.0 + offset_x
	blind_overlay.offset_top = 430.0 + offset_y
	blind_overlay.offset_right = 1070.0 + offset_x
	blind_overlay.offset_bottom = 1490.0 + offset_y

	# Centrer le score label
	score_label.offset_left = 340.0 + offset_x
	score_label.offset_top = 50.0 + offset_y
	score_label.offset_right = 740.0 + offset_x
	score_label.offset_bottom = 130.0 + offset_y

	# Centrer le move count label
	move_count_label.offset_left = 390.0 + offset_x
	move_count_label.offset_top = 1480.0 + offset_y
	move_count_label.offset_right = 690.0 + offset_x
	move_count_label.offset_bottom = 1540.0 + offset_y

	# Centrer le power message container
	power_message_container.offset_left = 140.0 + offset_x
	power_message_container.offset_top = 1400.0 + offset_y
	power_message_container.offset_right = 940.0 + offset_x

	# Centrer tous les overlays
	_center_overlay_menu(title_menu)
	_center_overlay_menu(power_choice_menu)
	_center_overlay_menu(options_menu)
	_center_overlay_menu(ranking_menu)
	_center_overlay_menu(game_over_menu)


# Centrer un menu overlay
func _center_overlay_menu(overlay):
	if not overlay:
		return

	var viewport_size = get_viewport().get_visible_rect().size
	var offset_x = (viewport_size.x - GameManager.DESIGN_WIDTH) / 2.0
	var offset_y = (viewport_size.y - GameManager.DESIGN_HEIGHT) / 2.0

	# Centrer le fond de l'overlay
	var overlay_bg = overlay.get_node_or_null("OverlayBackground")
	if overlay_bg:
		overlay_bg.offset_left = offset_x
		overlay_bg.offset_top = offset_y
		overlay_bg.offset_right = GameManager.DESIGN_WIDTH + offset_x
		overlay_bg.offset_bottom = GameManager.DESIGN_HEIGHT + offset_y

	# Centrer le conteneur du menu
	var menu_container = overlay.get_node_or_null("MenuContainer")
	if menu_container:
		var original_left = 240.0
		var original_top = menu_container.offset_top  # Garder la position verticale originale
		var original_right = 840.0
		var original_bottom = menu_container.offset_bottom

		menu_container.offset_left = original_left + offset_x
		menu_container.offset_top = original_top + offset_y
		menu_container.offset_right = original_right + offset_x
		menu_container.offset_bottom = original_bottom + offset_y


# Définir la taille minimale de la fenêtre
func _set_minimum_window_size():
	var window = get_window()
	if window:
		window.min_size = Vector2i(GameManager.MIN_WINDOW_WIDTH, GameManager.MIN_WINDOW_HEIGHT)


# Hide all overlays
func hide_all_overlays():
	title_menu.hide_menu()
	power_choice_menu.hide_menu()
	options_menu.hide_menu()
	ranking_menu.hide_menu()
	game_over_menu.hide_menu()
	# Rendre la grille visible quand tous les menus sont fermés
	grid.visible = true


# Cacher la grille quand un menu overlay s'ouvre
func _hide_grid():
	grid.visible = false


# Title menu signal handlers
func _on_new_game_pressed():
	hide_all_overlays()
	# Reset UI counters
	move_count = 0
	update_move_count()
	update_score_display()
	# Ensure we're in Classic mode (no powers)
	GameManager.enter_classic_mode()
	GameManager.start_new_game()


func _on_free_mode_pressed():
	title_menu.hide_menu()
	_hide_grid()
	power_choice_menu.show_menu()


func _on_resume_pressed():
	hide_all_overlays()
	var save_data = SaveManager.load_game()
	if not save_data.is_empty():
		SaveManager.restore_game(save_data)
		# Restore move count if saved
		move_count = save_data.get("move_count", 0)
		update_move_count()
		# Enemy state is automatically restored by SaveManager.restore_game()
	GameManager.resume_game()


func _on_ranking_pressed():
	title_menu.hide_menu()
	_hide_grid()
	ranking_menu.show_menu()


func _on_options_pressed():
	title_menu.hide_menu()
	_hide_grid()
	options_menu.show_menu()


func _on_quit_pressed():
	get_tree().quit()


# PowerChoiceMenu signal handlers
func _on_powers_selected(selected_powers: Array):
	hide_all_overlays()
	# Reset UI counters
	move_count = 0
	update_move_count()
	update_score_display()
	# Enter Free Mode BEFORE starting game so initial tiles spawn with powers
	GameManager.enter_free_mode(selected_powers)
	GameManager.start_new_game()
	# Assign powers to the initial tiles after grid is created
	GameManager.assign_powers_to_existing_tiles()


func _on_power_choice_back():
	power_choice_menu.hide_menu()
	_hide_grid()
	title_menu.show_menu()


# Options menu signal handlers
func _on_options_back():
	options_menu.hide_menu()
	_hide_grid()
	title_menu.show_menu()


func _on_ranking_reset():
	pass


# Ranking menu signal handlers
func _on_ranking_back():
	ranking_menu.hide_menu()
	_hide_grid()
	title_menu.show_menu()


# GameOver menu signal handlers
func _on_gameover_new_game():
	hide_all_overlays()
	# Ensure we're in Classic mode when starting new game from game over
	GameManager.enter_classic_mode()
	GameManager.start_new_game()


func _on_gameover_menu():
	hide_all_overlays()
	GameManager.return_to_menu()
	_hide_grid()
	title_menu.show_menu()


# GameManager signal handlers
func _on_game_started():
	# Spawn 2 tiles when game starts
	GridManager.spawn_random_tile()
	GridManager.spawn_random_tile()


func _on_grid_game_over():
	if GameManager.is_playing():
		var has_reached_2048 = GridManager.has_tile_value(2048)
		GameManager.end_game(has_reached_2048)


func _on_game_paused():
	_hide_grid()
	title_menu.show_menu()


func _on_game_ended(victory: bool):
	_hide_grid()
	game_over_menu.show_menu()


# GridManager signal handlers
func _on_fusion_occurred(tile1, tile2, new_tile):
	# Spawn enemy on first fusion (only if not in Free Mode)
	if EnemyManager != null and not EnemyManager.first_fusion_occurred and not GameManager.is_free_mode():
		EnemyManager.spawn_enemy()
		# Note: enemy_just_spawned flag is set in _on_enemy_spawned callback

	# Get the world position of the new tile
	var tile_world_pos = grid.position + new_tile.position
	# Show floating score
	ui_effect.show_floating_score(new_tile.value, tile_world_pos)

	# Deal damage to enemy if active (but not if it just spawned)
	if EnemyManager != null and EnemyManager.is_enemy_active() and not enemy_just_spawned:
		var damage = int(new_tile.value / 2)
		EnemyManager.damage_enemy(damage)

		# Show damage number floating from enemy (in red)
		var damage_pos = enemy_container.position + Vector2(0, -50)
		ui_effect.show_floating_damage(damage, damage_pos)

	# Reset spawn protection flag after checking
	enemy_just_spawned = false


func _on_tiles_moved():
	# Increment move counter when tiles actually moved
	move_count += 1
	update_move_count()

	# Update enemy respawn timer
	if EnemyManager != null:
		EnemyManager.on_move_completed()


# ScoreManager signal handlers
func _on_score_changed(new_score: int):
	score_label.text = "Score: %d" % new_score


# PowerManager signal handlers
func _on_power_activated(power_type: String, tile):
	var power = PowerManager.POWERS.get(power_type, {})
	var power_name = power.get("name", power_type)

	# Calculate world position from tile
	var world_position = Vector2.ZERO
	if tile != null:
		const TILE_SIZE = 240
		const TILE_SPACING = 20
		const CELL_SIZE = TILE_SIZE + TILE_SPACING
		world_position = Vector2(
			tile.grid_position.x * CELL_SIZE + TILE_SPACING,
			tile.grid_position.y * CELL_SIZE + TILE_SPACING
		)

	ui_effect.show_power_message(power_name, world_position)


# EnemyManager signal handlers
func _on_enemy_spawned(enemy_data: Dictionary):
	# Instance the Enemy scene
	var enemy_scene = preload("res://objects/Enemy.tscn")
	var enemy = enemy_scene.instantiate()

	# Initialize enemy with data from EnemyManager
	enemy.initialize(enemy_data)

	# Clear any existing enemy first
	for child in enemy_container.get_children():
		child.queue_free()

	# Add to container
	enemy_container.add_child(enemy)

	# Protect newly spawned enemy from taking damage this turn
	enemy_just_spawned = true


func _on_enemy_damaged(damage_amount: int, remaining_hp: int):
	# Update the visual enemy instance with new HP
	if enemy_container.get_child_count() > 0:
		var enemy = enemy_container.get_child(0)
		if enemy.has_method("update_hp"):
			enemy.update_hp(remaining_hp)
		# Show damage in the enemy's damage label
		if enemy.has_method("show_damage"):
			enemy.show_damage(damage_amount)


func _on_enemy_sprite_updated(new_sprite_path: String):
	# Update the visual enemy sprite when health state changes
	if enemy_container.get_child_count() > 0:
		var enemy = enemy_container.get_child(0)
		if enemy.has_method("update_sprite"):
			enemy.update_sprite(new_sprite_path)


func _on_enemy_defeated(enemy_level: int, score_bonus: int):
	# Play defeat animation on enemy (die() handles queue_free after animation)
	for child in enemy_container.get_children():
		if child.has_method("die"):
			child.die()
		else:
			child.queue_free()

	# Display bonus score as floating text
	var bonus_text_pos = enemy_container.position
	ui_effect.show_floating_score(score_bonus, bonus_text_pos)


func _on_blind_started():
	blind_overlay.visible = true


func _on_blind_ended():
	blind_overlay.visible = false


# Block direction signal handlers
func _on_direction_blocked(direction: int, turns: int):
	# Add visual indicator for blocked direction (via PowerEffect)
	var PowerEffect = preload("res://visuals/PowerEffect.gd")
	PowerEffect.create_wind_effect(direction)
	PowerEffect.create_wind_sprites(direction)


func _on_direction_unblocked(direction: int):
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


# Handle power ball animation from enemy to tile
func _on_power_ball_animation_requested(power_type: String, tile_position: Vector2i):
	# Calculate enemy sprite position (center of enemy sprite)
	var enemy_pos = enemy_container.position + Vector2(96, 122)  # IdleSprite position

	# Calculate target tile position (center of tile)
	var tile_size = 256  # Tile visual size
	var grid_start = grid.position
	var target_pos = grid_start + Vector2(
		tile_position.x * tile_size + tile_size / 2,
		tile_position.y * tile_size + tile_size / 2
	)

	# Create and play power ball animation
	var EnemyEffect = preload("res://visuals/EnemyEffect.gd")
	var animation = EnemyEffect.create_animation(self, enemy_pos, target_pos)

	# Track animation for potential cancellation
	active_power_animations.append(animation)

	# Remove from tracking when animation completes
	animation.animation_completed.connect(func(): active_power_animations.erase(animation))


# Handle cancellation of all power ball animations
func _on_cancel_power_animations():
	for animation in active_power_animations:
		if is_instance_valid(animation):
			animation.cancel_animation()
	active_power_animations.clear()
