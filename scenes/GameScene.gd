# GameScene for Fusion Mania
# Main game scene with grid and overlays
extends Node2D

@onready var background_layer          = $BackgroundLayer
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
@onready var debug_label              = $DebugLabel if has_node("DebugLabel") else null

# Background parallax layers
var layer1_a: Sprite2D
var layer1_b: Sprite2D
var layer2_a: Sprite2D
var layer2_b: Sprite2D
var layer3_a: Sprite2D
var layer3_b: Sprite2D
var layer4_a: Sprite2D
var layer4_b: Sprite2D
var layer5_a: Sprite2D
var layer5_b: Sprite2D

# Parallax scrolling speeds (pixels per second)
const LAYER1_SPEED = 10.0   # Plus lent (plus éloigné)
const LAYER2_SPEED = 25.0
const LAYER3_SPEED = 50.0
const LAYER4_SPEED = 75.0
const LAYER5_SPEED = 100.0  # Plus rapide (plus proche)
const SPRITE_WIDTH = 3413.0  # Largeur d'un sprite scalé (576 * 5.926)

# Swipe detection
var swipe_start:     Vector2 = Vector2.ZERO
var swipe_threshold: float   = 50.0
var is_swiping:      bool    = false

# Move counter
var move_count: int = 0

# Enemy spawn protection
var enemy_just_spawned: bool = false

# Reference viewport size
const DESIGN_WIDTH = 1080.0
const DESIGN_HEIGHT = 1920.0
const MIN_WINDOW_WIDTH = 540.0   # 50% de la largeur originale (permet le redimensionnement)
const MIN_WINDOW_HEIGHT = 960.0  # 50% de la hauteur originale (permet le redimensionnement)


func _ready():
	print("\n=== Fusion Mania - Game Scene Ready ===\n")

	# Add to group for visual effects to find this scene
	add_to_group("game_scene")

	# Setup UIEffect
	ui_effect.set_container(effects_container)

	# Initialize background layer references
	layer1_a = background_layer.get_node("Layer1_A")
	layer1_b = background_layer.get_node("Layer1_B")
	layer2_a = background_layer.get_node("Layer2_A")
	layer2_b = background_layer.get_node("Layer2_B")
	layer3_a = background_layer.get_node("Layer3_A")
	layer3_b = background_layer.get_node("Layer3_B")
	layer4_a = background_layer.get_node("Layer4_A")
	layer4_b = background_layer.get_node("Layer4_B")
	layer5_a = background_layer.get_node("Layer5_A")
	layer5_b = background_layer.get_node("Layer5_B")

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

	# Connect to EnemyManager signals
	EnemyManager.enemy_spawned.connect(_on_enemy_spawned)
	EnemyManager.enemy_defeated.connect(_on_enemy_defeated)
	EnemyManager.enemy_damaged.connect(_on_enemy_damaged)

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
	# Scroll each layer at different speeds
	_scroll_layer(layer1_a, layer1_b, LAYER1_SPEED * delta)
	_scroll_layer(layer2_a, layer2_b, LAYER2_SPEED * delta)
	_scroll_layer(layer3_a, layer3_b, LAYER3_SPEED * delta)
	_scroll_layer(layer4_a, layer4_b, LAYER4_SPEED * delta)
	_scroll_layer(layer5_a, layer5_b, LAYER5_SPEED * delta)

	# Update debug display (only in debug builds)
	if OS.is_debug_build() and debug_label:
		update_debug_display()


# Scroll a background layer with looping
func _scroll_layer(sprite_a: Sprite2D, sprite_b: Sprite2D, speed: float):
	# Move both sprites to the left
	sprite_a.position.x -= speed
	sprite_b.position.x -= speed

	# When sprite A goes off-screen to the left, move it to the right (outside viewport)
	if sprite_a.position.x <= -SPRITE_WIDTH:
		sprite_a.position.x = sprite_b.position.x + SPRITE_WIDTH

	# When sprite B goes off-screen to the left, move it to the right (outside viewport)
	if sprite_b.position.x <= -SPRITE_WIDTH:
		sprite_b.position.x = sprite_a.position.x + SPRITE_WIDTH


# Recentrer les éléments quand la fenêtre est redimensionnée
func _on_viewport_resized():
	var viewport_size = get_viewport().get_visible_rect().size
	var offset_x = (viewport_size.x - DESIGN_WIDTH) / 2.0
	var offset_y = (viewport_size.y - DESIGN_HEIGHT) / 2.0

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
	var offset_x = (viewport_size.x - DESIGN_WIDTH) / 2.0
	var offset_y = (viewport_size.y - DESIGN_HEIGHT) / 2.0

	# Centrer le fond de l'overlay
	var overlay_bg = overlay.get_node_or_null("OverlayBackground")
	if overlay_bg:
		overlay_bg.offset_left = offset_x
		overlay_bg.offset_top = offset_y
		overlay_bg.offset_right = DESIGN_WIDTH + offset_x
		overlay_bg.offset_bottom = DESIGN_HEIGHT + offset_y

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
		window.min_size = Vector2i(MIN_WINDOW_WIDTH, MIN_WINDOW_HEIGHT)


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
	_hide_grid()
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
		# Enemy state is automatically restored by SaveManager.restore_game()
	GameManager.resume_game()


func _on_ranking_pressed():
	print("🏆 Opening ranking...")
	title_menu.hide_menu()
	_hide_grid()
	ranking_menu.show_menu()


func _on_options_pressed():
	print("⚙️ Opening options...")
	title_menu.hide_menu()
	_hide_grid()
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
	_hide_grid()
	title_menu.show_menu()


# Options menu signal handlers
func _on_options_back():
	options_menu.hide_menu()
	_hide_grid()
	title_menu.show_menu()


func _on_ranking_reset():
	print("🗑️ Ranking reset!")


# Ranking menu signal handlers
func _on_ranking_back():
	ranking_menu.hide_menu()
	_hide_grid()
	title_menu.show_menu()


# GameOver menu signal handlers
func _on_gameover_new_game():
	hide_all_overlays()
	GameManager.start_new_game()


func _on_gameover_menu():
	hide_all_overlays()
	GameManager.return_to_menu()
	_hide_grid()
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
	_hide_grid()
	title_menu.show_menu()


func _on_game_ended(victory: bool):
	print("Game ended - victory: %s" % victory)
	_hide_grid()
	game_over_menu.show_menu()


# GridManager signal handlers
func _on_fusion_occurred(tile1, tile2, new_tile):
	print("🔥 Fusion occurred - enemy_just_spawned=%s" % enemy_just_spawned)

	# Spawn enemy on first fusion (before dealing damage)
	if not EnemyManager.first_fusion_occurred:
		print("🐣 First fusion - spawning first enemy")
		EnemyManager.spawn_enemy()
		# Note: enemy_just_spawned flag is set in _on_enemy_spawned callback

	# Get the world position of the new tile
	var tile_world_pos = grid.position + new_tile.position
	# Show floating score
	ui_effect.show_floating_score(new_tile.value, tile_world_pos)

	# Deal damage to enemy if active (but not if it just spawned)
	if EnemyManager.is_enemy_active() and not enemy_just_spawned:
		var damage = int(new_tile.value / 2)
		print("⚔️ Applying %d damage to enemy" % damage)
		EnemyManager.damage_enemy(damage)

		# Show damage number floating from enemy (in red)
		var damage_pos = enemy_container.position + Vector2(0, -50)
		ui_effect.show_floating_damage(damage, damage_pos)
	elif enemy_just_spawned:
		print("🛡️ Enemy just spawned - protected from damage")

	# Reset spawn protection flag after checking
	enemy_just_spawned = false
	print("🔓 Spawn protection removed")


func _on_tiles_moved():
	# Increment move counter when tiles actually moved
	move_count += 1
	update_move_count()

	# Update enemy respawn timer
	print("🎮 Move completed, calling EnemyManager.on_move_completed()")
	EnemyManager.on_move_completed()


# ScoreManager signal handlers
func _on_score_changed(new_score: int):
	score_label.text = "Score: %d" % new_score


# PowerManager signal handlers
func _on_power_activated(power_type: String, tile):
	var power = PowerManager.POWERS.get(power_type, {})
	var power_name = power.get("name", power_type)
	ui_effect.show_power_message(power_name, power_message_container)


# EnemyManager signal handlers
func _on_enemy_spawned(enemy_data: Dictionary) -> void:
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
	print("🛡️ Enemy spawn protection enabled")

	print("Enemy spawned: ", enemy_data.get("name"), " (Level ", enemy_data.get("level"), ")")


func _on_enemy_damaged(damage_amount: int, remaining_hp: int) -> void:
	# Update the visual enemy instance with new HP
	if enemy_container.get_child_count() > 0:
		var enemy = enemy_container.get_child(0)
		if enemy.has_method("update_hp"):
			enemy.update_hp(remaining_hp)
		# Show damage in the enemy's damage label
		if enemy.has_method("show_damage"):
			enemy.show_damage(damage_amount)


func _on_enemy_defeated(enemy_level: int, score_bonus: int) -> void:
	# Play defeat animation on enemy (die() handles queue_free after animation)
	for child in enemy_container.get_children():
		if child.has_method("die"):
			child.die()
		else:
			child.queue_free()

	# Display bonus score as floating text
	var bonus_text_pos = enemy_container.position
	ui_effect.show_floating_score(score_bonus, bonus_text_pos)

	# Note: score bonus already added by EnemyManager.defeat_enemy()

	print("Enemy defeated! Level ", enemy_level, " - Bonus: +", score_bonus)


func _on_blind_started():
	blind_overlay.visible = true
	print("🕶️ Blind overlay activated")


func _on_blind_ended():
	blind_overlay.visible = false
	print("👁️ Blind overlay removed")


# Block direction signal handlers
func _on_direction_blocked(direction: int, turns: int):
	print("🧊 Direction %d blocked for %d turns" % [direction, turns])
	# Add visual indicator for blocked direction (via PowerEffect)
	var PowerEffect = preload("res://visuals/PowerEffect.gd")
	PowerEffect.create_wind_effect(direction)
	PowerEffect.create_wind_sprites(direction)


func _on_direction_unblocked(direction: int):
	print("🧊 Direction %d unblocked" % direction)
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
	# Debug commands (only in debug builds)
	if OS.is_debug_build():
		if event.is_action_pressed("ui_text_delete"): # Delete key
			kill_enemy()
			return
		elif event.is_action_pressed("ui_home"): # Home key
			spawn_test_enemy(2)
			return
		elif event.is_action_pressed("ui_end"): # End key
			spawn_test_enemy(2048)
			return
		elif event.is_action_pressed("ui_page_up"): # Page Up key
			damage_enemy_debug(50)
			return
		elif event.is_action_pressed("ui_page_down"): # Page Down key
			set_respawn_timer(3)
			return
		elif event is InputEventKey and event.pressed:
			if event.keycode == KEY_I and event.ctrl_pressed:
				print_enemy_info()
				return

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


# ============================================================================
# DEBUG COMMANDS (Only work in debug builds)
# ============================================================================

# Update debug display
func update_debug_display():
	if not debug_label:
		return

	var debug_text = "[DEBUG MODE]\n"

	if EnemyManager.is_enemy_active():
		var enemy_data = EnemyManager.active_enemy
		debug_text += "Enemy: %s (Lv.%d)\n" % [enemy_data.get("name", "?"), enemy_data.get("level", 0)]
		debug_text += "HP: %d/%d\n" % [enemy_data.get("current_hp", 0), enemy_data.get("max_hp", 0)]

		# Show available powers
		var powers = enemy_data.get("powers", [])
		if powers.size() > 0:
			debug_text += "Powers: %s\n" % ", ".join(powers)
	else:
		if EnemyManager.moves_until_respawn > 0:
			debug_text += "Enemy respawns in: %d moves\n" % EnemyManager.moves_until_respawn
		else:
			debug_text += "No enemy active\n"

	debug_text += "\nDebug Keys:\n"
	debug_text += "Home: Spawn Lv.2 | End: Spawn Boss\n"
	debug_text += "Delete: Kill Enemy\n"
	debug_text += "PgUp: Damage 50 | PgDn: Set Respawn 3\n"
	debug_text += "Ctrl+I: Print Info"

	debug_label.text = debug_text


# Force spawn enemy at specific level (DEBUG ONLY)
func spawn_test_enemy(level: int):
	if not OS.is_debug_build():
		return

	if not EnemyManager.ENEMY_LEVELS.has(level):
		print("❌ Invalid enemy level: %d" % level)
		return

	# Kill current enemy if exists
	if EnemyManager.is_enemy_active():
		kill_enemy()
		await get_tree().create_timer(0.5).timeout

	# Create enemy data manually
	var enemy_data = {
		"level": level,
		"name": EnemyManager.get_random_name(),
		"max_hp": EnemyManager.HP_BY_LEVEL.get(level, 10),
		"current_hp": EnemyManager.HP_BY_LEVEL.get(level, 10),
		"sprite_path": EnemyManager.get_random_sprite_path(level),
		"powers": EnemyManager.ENEMY_POWERS_BY_LEVEL.get(level, [])
	}

	EnemyManager.active_enemy = enemy_data
	EnemyManager.first_fusion_occurred = true
	EnemyManager.enemy_spawned.emit(enemy_data)

	print("🐛 DEBUG: Spawned test enemy: %s (Lv.%d, HP:%d)" % [enemy_data.name, level, enemy_data.max_hp])


# Instantly defeat current enemy (DEBUG ONLY)
func kill_enemy():
	if not OS.is_debug_build():
		return

	if not EnemyManager.is_enemy_active():
		print("🐛 DEBUG: No enemy to kill")
		return

	var enemy_level = EnemyManager.active_enemy.get("level", 2)
	EnemyManager.defeat_enemy()
	print("🐛 DEBUG: Killed enemy (Lv.%d)" % enemy_level)


# Apply specific damage to enemy (DEBUG ONLY)
func damage_enemy_debug(amount: int):
	if not OS.is_debug_build():
		return

	if not EnemyManager.is_enemy_active():
		print("🐛 DEBUG: No enemy to damage")
		return

	EnemyManager.damage_enemy(amount)
	print("🐛 DEBUG: Damaged enemy for %d HP" % amount)


# Set custom respawn timer (DEBUG ONLY)
func set_respawn_timer(moves: int):
	if not OS.is_debug_build():
		return

	EnemyManager.moves_until_respawn = moves
	EnemyManager.enemy_defeated_flag = (moves > 0)
	print("🐛 DEBUG: Set respawn timer to %d moves" % moves)


# Print current enemy stats (DEBUG ONLY)
func print_enemy_info():
	if not OS.is_debug_build():
		return

	print("\n=== ENEMY DEBUG INFO ===")

	if EnemyManager.is_enemy_active():
		var enemy = EnemyManager.active_enemy
		print("Name: %s" % enemy.get("name", "?"))
		print("Level: %d" % enemy.get("level", 0))
		print("HP: %d/%d (%.1f%%)" % [
			enemy.get("current_hp", 0),
			enemy.get("max_hp", 0),
			(float(enemy.get("current_hp", 0)) / enemy.get("max_hp", 1)) * 100.0
		])
		print("Sprite: %s" % enemy.get("sprite_path", "?"))
		print("Powers: %s" % enemy.get("powers", []))
	else:
		print("No active enemy")

	print("First fusion occurred: %s" % EnemyManager.first_fusion_occurred)
	print("Enemy defeated: %s" % EnemyManager.enemy_defeated_flag)
	print("Moves until respawn: %d" % EnemyManager.moves_until_respawn)
	print("========================\n")
