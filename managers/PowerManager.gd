# PowerManager for Fusion Mania
extends Node

# Load PowerEffect for visual effects
const PowerEffect = preload("res://visuals/PowerEffect.gd")

# Power data with spawn rates (total = 100%)
const POWERS = {
	"fire_h":       {"name": "Fire Row",        "spawn_rate": 10, "type": "bonus", "duration": 1.0},
	"fire_v":       {"name": "Fire Column",     "spawn_rate": 10, "type": "bonus", "duration": 1.0},
	"fire_cross":   {"name": "Fire Cross",      "spawn_rate": 5,  "type": "bonus", "duration": 1.0},
	"bomb":         {"name": "Bomb",            "spawn_rate": 10, "type": "bonus", "duration": 0.3},
	"ice":          {"name": "Ice",             "spawn_rate": 6,  "type": "malus", "duration": 3.0},
	"switch_h":     {"name": "Switch H",        "spawn_rate": 5,  "type": "bonus", "duration": 0.3},
	"switch_v":     {"name": "Switch V",        "spawn_rate": 5,  "type": "bonus", "duration": 0.3},
	"teleport":     {"name": "Teleport",        "spawn_rate": 2,  "type": "bonus", "duration": 0.3},
	"expel_h":      {"name": "Expel H",         "spawn_rate": 10, "type": "bonus", "duration": 0.3},
	"expel_v":      {"name": "Expel V",         "spawn_rate": 10, "type": "bonus", "duration": 0.3},
	"block_up":     {"name": "Block Up",        "spawn_rate": 5,  "type": "malus", "duration": 1.0},
	"block_down":   {"name": "Block Down",      "spawn_rate": 5,  "type": "malus", "duration": 1.0},
	"block_left":   {"name": "Block Left",      "spawn_rate": 5,  "type": "malus", "duration": 1.0},
	"block_right":  {"name": "Block Right",     "spawn_rate": 5,  "type": "malus", "duration": 1.0},
	"lightning":    {"name": "Lightning",       "spawn_rate": 2,  "type": "bonus", "duration": 0.3},
	"nuclear":      {"name": "Nuclear",         "spawn_rate": 1,  "type": "bonus", "duration": 1.5},
	"blind":        {"name": "Blind",           "spawn_rate": 2,  "type": "malus", "duration": 4.0},
	"bowling":      {"name": "Bowling",         "spawn_rate": 2,  "type": "bonus", "duration": 0.5},
	"ads":          {"name": "Ads",             "spawn_rate": 10, "type": "malus", "duration": 1.0}
}

# Current active spawn rates (can be modified for Free Mode)
var active_spawn_rates: Dictionary = {}

# Animation tracking (for interruption)
var is_power_animating: bool = false
var pending_effects: Callable = Callable()
var current_emitter_tile = null
var current_target_tiles: Array = []

# Signals
signal power_activated(power_type: String, tile)
signal power_effect_completed(power_type: String)
signal power_animation_started()
signal power_animation_interrupted()

func _ready():
	print("⚡ PowerManager ready with %d powers" % POWERS.size())
	reset_to_default_spawn_rates()


# Get default spawn rates from POWERS
func get_default_spawn_rates():
	var default_rates = {}
	for power_key in POWERS.keys():
		default_rates[power_key] = POWERS[power_key].get("spawn_rate", 0)
	return default_rates


# Get a random power based on spawn rates
func get_random_power():
	var total_rate = 0
	for power_key in active_spawn_rates.keys():
		total_rate += active_spawn_rates[power_key]

	# If all spawn rates are 0%, return empty (no power)
	if total_rate == 0:
		return "empty"

	var random_value = randf() * total_rate
	var current_sum = 0

	for power_key in active_spawn_rates.keys():
		current_sum += active_spawn_rates[power_key]
		if random_value <= current_sum:
			return power_key

	# Default: return empty (should never happen if rates are correct)
	return "empty"


# Set custom spawn rates for Free Mode
func set_custom_spawn_rates(selected_powers: Array):
	if selected_powers.is_empty():
		# No selection = all powers at 0% (no powers spawn)
		active_spawn_rates.clear()
		for power_key in POWERS.keys():
			active_spawn_rates[power_key] = 0.0
		print("🎲 Free Mode: No powers selected - all spawn rates set to 0%")
	else:
		# Equal distribution among selected powers, others at 0%
		active_spawn_rates.clear()
		var rate_per_power = 100.0 / selected_powers.size()

		for power_key in POWERS.keys():
			if power_key in selected_powers:
				active_spawn_rates[power_key] = rate_per_power
			else:
				active_spawn_rates[power_key] = 0.0

		print("🎲 Free Mode: %d powers active, %.1f%% each" % [selected_powers.size(), rate_per_power])


# Reset to default spawn rates
func reset_to_default_spawn_rates():
	active_spawn_rates = get_default_spawn_rates()
	print("🎲 Spawn rates reset to default")


# Resolve which power to keep when merging two tiles
func resolve_power_merge(power1: String, power2: String):
	# Case 1: Same power (activation!)
	if power1 == power2:
		return power1

	# Case 2: One tile has no power
	if power1 == "":
		return power2
	if power2 == "":
		return power1

	# Case 3: Different powers -> keep the rarer one
	var rate1 = POWERS.get(power1, {}).get("spawn_rate", 100)
	var rate2 = POWERS.get(power2, {}).get("spawn_rate", 100)

	if rate1 < rate2:
		return power1  # power1 is rarer
	elif rate2 < rate1:
		return power2  # power2 is rarer
	else:
		# Same rarity: keep the one from the initiating tile (handled by caller)
		return power1


# ============================
# Power Animation Interruption
# ============================

# Interrupt current power animation and apply effects immediately
func interrupt_current_power():
	if not is_power_animating:
		return

	print("⚡ Interrupting power animation")
	power_animation_interrupted.emit()

	# Stop visual effects on tiles
	if current_emitter_tile != null and is_instance_valid(current_emitter_tile):
		current_emitter_tile.stop_all_power_effects()

	for target in current_target_tiles:
		if is_instance_valid(target):
			target.stop_all_power_effects()

	# Apply pending effects immediately
	if pending_effects.is_valid():
		pending_effects.call()
		pending_effects = Callable()

	# Reset state
	is_power_animating = false
	current_emitter_tile = null
	current_target_tiles.clear()


# ============================
# Target Determination Methods
# ============================

# Get power targets based on power type
func get_power_targets(power_type: String, emitter_tile, grid_manager):
	var targets: Array = []

	match power_type:
		"fire_h":
			targets = _get_row_targets(emitter_tile, grid_manager)
		"fire_v":
			targets = _get_column_targets(emitter_tile, grid_manager)
		"fire_cross":
			targets = _get_cross_targets(emitter_tile, grid_manager)
		"bomb":
			targets = _get_adjacent_targets(emitter_tile, grid_manager)
		"ice":
			targets = []  # Ice affects the emitter itself
		"switch_h":
			targets = _get_horizontal_neighbors(emitter_tile, grid_manager)
		"switch_v":
			targets = _get_vertical_neighbors(emitter_tile, grid_manager)
		"teleport":
			targets = _get_random_tiles(emitter_tile, grid_manager, 2)
		"expel_h", "expel_v":
			targets = []  # Expel affects the emitter itself, making it able to exit the grid
		"lightning":
			targets = _get_random_tiles(emitter_tile, grid_manager, 4)
		"nuclear":
			targets = _get_all_tiles_except(emitter_tile, grid_manager)
		"bowling":
			targets = _get_bowling_line_targets(emitter_tile, grid_manager)
		_:
			targets = []  # block_*, blind, ads don't have tile targets

	return {"emitter": emitter_tile, "targets": targets}


# Get all tiles in the same row (except emitter)
func _get_row_targets(emitter_tile, grid_manager):
	var row 	= emitter_tile.grid_position.y
	var targets = []

	for x in range(grid_manager.grid_size):
		var target = grid_manager.get_tile_at(Vector2i(x, row))
		if target != null and target != emitter_tile:
			targets.append(target)

	return targets


# Get all tiles in the same column (except emitter)
func _get_column_targets(emitter_tile, grid_manager):
	var col = emitter_tile.grid_position.x
	var targets = []

	for y in range(grid_manager.grid_size):
		var target = grid_manager.get_tile_at(Vector2i(col, y))
		if target != null and target != emitter_tile:
			targets.append(target)

	return targets


# Get all tiles in row + column (except emitter)
func _get_cross_targets(emitter_tile, grid_manager):
	var row_targets = _get_row_targets(emitter_tile, grid_manager)
	var col_targets = _get_column_targets(emitter_tile, grid_manager)

	# Combine without duplicates
	var targets = row_targets.duplicate()
	for target in col_targets:
		if target not in targets:
			targets.append(target)

	return targets


# Get adjacent tiles (8 tiles max)
func _get_adjacent_targets(emitter_tile, grid_manager):
	var targets = []
	var pos 	= emitter_tile.grid_position

	var adjacent = [
		Vector2i(pos.x - 1, pos.y - 1), Vector2i(pos.x, pos.y - 1), Vector2i(pos.x + 1, pos.y - 1),
		Vector2i(pos.x - 1, pos.y),                                 Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x - 1, pos.y + 1), Vector2i(pos.x, pos.y + 1), Vector2i(pos.x + 1, pos.y + 1)
	]

	for adj_pos in adjacent:
		if adj_pos.x >= 0 and adj_pos.x < grid_manager.grid_size and adj_pos.y >= 0 and adj_pos.y < grid_manager.grid_size:
			var target = grid_manager.get_tile_at(adj_pos)

			if target != null:
				targets.append(target)

	return targets


# Get horizontal neighbors (left and right)
func _get_horizontal_neighbors(emitter_tile, grid_manager):
	var targets 	= []
	var pos 		= emitter_tile.grid_position
	var left_tile 	= grid_manager.get_tile_at(Vector2i(pos.x - 1, pos.y)) if pos.x > 0 else null
	var right_tile 	= grid_manager.get_tile_at(Vector2i(pos.x + 1, pos.y)) if pos.x < grid_manager.grid_size - 1 else null

	if left_tile != null:
		targets.append(left_tile)

	if right_tile != null:
		targets.append(right_tile)

	return targets



# Get vertical neighbors (up and down)
func _get_vertical_neighbors(emitter_tile, grid_manager):
	var targets 	= []
	var pos 		= emitter_tile.grid_position
	var up_tile 	= grid_manager.get_tile_at(Vector2i(pos.x, pos.y - 1)) if pos.y > 0 else null
	var down_tile 	= grid_manager.get_tile_at(Vector2i(pos.x, pos.y + 1)) if pos.y < grid_manager.grid_size - 1 else null

	if up_tile != null:
		targets.append(up_tile)

	if down_tile != null:
		targets.append(down_tile)

	return targets


# Get N random tiles (except emitter)
func _get_random_tiles(emitter_tile, grid_manager, count: int):
	var all_tiles = _get_all_tiles_except(emitter_tile, grid_manager)
	all_tiles.shuffle()

	return all_tiles.slice(0, mini(count, all_tiles.size()))


# Get all tiles except emitter
func _get_all_tiles_except(emitter_tile, grid_manager):
	var targets = []

	for y in range(grid_manager.grid_size):
		for x in range(grid_manager.grid_size):
			var tile = grid_manager.get_tile_at(Vector2i(x, y))
			if tile != null and tile != emitter_tile:
				targets.append(tile)

	return targets


# Get bowling line targets (random direction)
func _get_bowling_line_targets(emitter_tile, grid_manager):
	var pos = emitter_tile.grid_position
	var targets = []
	var direction = randi() % 4
	var dx = 0
	var dy = 0

	match direction:
		0: dy = -1  # Up
		1: dy = 1   # Down
		2: dx = -1  # Left
		3: dx = 1   # Right

	var current = Vector2i(pos.x + dx, pos.y + dy)
	while current.x >= 0 and current.x < grid_manager.grid_size and current.y >= 0 and current.y < grid_manager.grid_size:
		var target = grid_manager.get_tile_at(current)
		if target != null:
			targets.append(target)
		current.x += dx
		current.y += dy

	return targets


# ============================
# Main Power Activation
# ============================

# Activate a power
func activate_power(power_type: String, tile, grid_manager):
	if power_type == "":
		return

	print("🔥 Activating power: %s" % power_type)
	power_activated.emit(power_type, tile)
	AudioManager.play_sfx_power(power_type)

	# Get targets for this power
	var power_info = get_power_targets(power_type, tile, grid_manager)
	var emitter = power_info.emitter
	var targets = power_info.targets

	# Track current animation state
	is_power_animating = true
	current_emitter_tile = emitter
	current_target_tiles = targets.duplicate()
	power_animation_started.emit()

	# Execute power based on type
	match power_type:
		"fire_h":
			await _execute_fire_power(emitter, targets, true, grid_manager)
		"fire_v":
			await _execute_fire_power(emitter, targets, false, grid_manager)
		"fire_cross":
			await _execute_fire_cross_power(emitter, targets, grid_manager)
		"bomb":
			await _execute_bomb_power(emitter, targets, grid_manager)
		"ice":
			await _execute_ice_power(emitter, grid_manager)
		"switch_h", "switch_v":
			await _execute_switch_power(emitter, targets, grid_manager)
		"teleport":
			await _execute_teleport_power(emitter, targets, grid_manager)
		"expel_h":
			await _execute_expel_power(emitter, "expel_h", grid_manager)
		"expel_v":
			await _execute_expel_power(emitter, "expel_v", grid_manager)
		"block_up":
			_execute_block_direction_power(GridManager.Direction.UP)
		"block_down":
			_execute_block_direction_power(GridManager.Direction.DOWN)
		"block_left":
			_execute_block_direction_power(GridManager.Direction.LEFT)
		"block_right":
			_execute_block_direction_power(GridManager.Direction.RIGHT)
		"lightning":
			await _execute_lightning_power(emitter, targets, grid_manager)
		"nuclear":
			await _execute_nuclear_power(emitter, targets, grid_manager)
		"blind":
			await _execute_blind_power(emitter)
		"bowling":
			await _execute_bowling_power(emitter, targets, grid_manager)
		"ads":
			_execute_ads_power(emitter)

	# Remove power from tile after activation
	if tile != null and is_instance_valid(tile):
		tile.power_type = ""
		tile.update_visual()

	# Reset animation state
	is_power_animating = false
	current_emitter_tile = null
	current_target_tiles.clear()

	power_effect_completed.emit(power_type)


# ============================
# Visual Effects Helpers
# ============================

# Start visual effects on emitter and targets (parallel)
func _start_tile_visual_effects(emitter, targets: Array, duration: float = 2.0):
	# Emitter effect
	if emitter != null and is_instance_valid(emitter):
		emitter.start_emitter_effect(duration)

	# Target effects
	for target in targets:
		if is_instance_valid(target):
			target.start_target_effect(duration)


# Stop all tile visual effects
func _stop_tile_visual_effects(emitter, targets: Array):
	if emitter != null and is_instance_valid(emitter):
		emitter.stop_all_power_effects()

	for target in targets:
		if is_instance_valid(target):
			target.stop_all_power_effects()


# Common pattern: animate then destroy targets
func _execute_destroy_targets_power(emitter, targets: Array, grid_manager, duration: float, effect_callback: Callable = Callable()):
	# Start visual effects
	_start_tile_visual_effects(emitter, targets, duration)

	# Optional additional visual effect
	if effect_callback.is_valid():
		effect_callback.call()

	# Wait for animation
	await get_tree().create_timer(duration).timeout

	# Stop visual effects
	_stop_tile_visual_effects(emitter, targets)

	# Destroy targets
	for target in targets:
		if is_instance_valid(target):
			grid_manager.destroy_tile(target)


# Common pattern: animate then swap tiles
func _execute_swap_power(emitter, targets: Array, grid_manager, duration: float = 0.3):
	if targets.size() < 2:
		return

	# Start visual effects
	_start_tile_visual_effects(emitter, targets, duration)

	await get_tree().create_timer(duration).timeout

	_stop_tile_visual_effects(emitter, targets)

	# Swap the tiles
	grid_manager.swap_tiles(targets[0], targets[1])


# ============================
# Power Execution Methods
# ============================

# Fire power (horizontal or vertical)
func _execute_fire_power(emitter, targets: Array, is_horizontal: bool, grid_manager):
	print("  🔥 Fire %s: %d targets" % ["horizontal" if is_horizontal else "vertical", targets.size()])

	if emitter == null:
		return

	# Launch fireballs
	var grid_node = get_tree().get_first_node_in_group("grid")
	var effect = func():
		if grid_node:
			if is_horizontal:
				PowerEffect._create_fireball(grid_node, emitter, Vector2.RIGHT)
				PowerEffect._create_fireball(grid_node, emitter, Vector2.LEFT)
			else:
				PowerEffect._create_fireball(grid_node, emitter, Vector2.DOWN)
				PowerEffect._create_fireball(grid_node, emitter, Vector2.UP)

	await _execute_destroy_targets_power(emitter, targets, grid_manager, 1.0, effect)


# Fire cross power
func _execute_fire_cross_power(emitter, targets: Array, grid_manager):
	print("  🔥 Fire cross: %d targets" % targets.size())

	if emitter == null:
		return

	# Launch fireballs in all 4 directions
	var grid_node = get_tree().get_first_node_in_group("grid")
	var effect = func():
		if grid_node:
			PowerEffect._create_fireball(grid_node, emitter, Vector2.RIGHT)
			PowerEffect._create_fireball(grid_node, emitter, Vector2.LEFT)
			PowerEffect._create_fireball(grid_node, emitter, Vector2.DOWN)
			PowerEffect._create_fireball(grid_node, emitter, Vector2.UP)

	await _execute_destroy_targets_power(emitter, targets, grid_manager, 1.0, effect)


# Bomb power
func _execute_bomb_power(emitter, targets: Array, grid_manager):
	print("  💣 Bomb: %d targets" % targets.size())

	var effect = func():
		if emitter != null:
			PowerEffect.explosion_effect(emitter.position)

	await _execute_destroy_targets_power(emitter, targets, grid_manager, 0.3, effect)


# Ice power
func _execute_ice_power(emitter, grid_manager):
	print("  ❄️ Ice: icing emitter")

	if emitter != null and is_instance_valid(emitter):
		emitter.start_emitter_effect(3.0)

	PowerEffect.ice_effect(emitter)

	if emitter != null and emitter.has_method("set_iced"):
		emitter.set_iced(true, 2)


# Switch power (uses factorized swap helper)
func _execute_switch_power(emitter, targets: Array, grid_manager):
	if targets.size() < 2:
		print("  🔄 Switch: not enough targets")
		return

	print("  🔄 Switch: swapping 2 tiles")
	await _execute_swap_power(emitter, targets, grid_manager, 0.3)


# Teleport power (uses factorized swap helper)
func _execute_teleport_power(emitter, targets: Array, grid_manager):
	if targets.size() < 2:
		print("  🌀 Teleport: not enough targets")
		return

	print("  🌀 Teleport: swapping 2 random tiles")
	await _execute_swap_power(emitter, targets, grid_manager, 0.3)


# Expel power (marks emitter tile to be able to exit grid)
func _execute_expel_power(emitter, power_type: String, grid_manager):
	if emitter == null or not is_instance_valid(emitter):
		print("  🚀 Expel: no valid emitter")
		return

	# Determine direction
	var direction = "h" if power_type == "expel_h" else "v"
	print("  🚀 Expel %s: marking emitter tile" % direction)

	# Start visual effect on emitter
	emitter.start_emitter_effect(0.3)
	await get_tree().create_timer(0.3).timeout
	emitter.stop_all_power_effects()

	# Mark tile with expel direction
	if emitter.has_method("set"):
		emitter.expel_direction = direction
		emitter.update_visual()  # Apply transparency effect
		print("  🚀 Emitter tile can now exit the grid on %s movements" % ("horizontal" if direction == "h" else "vertical"))


# Block direction power (uses GameManager for state)
func _execute_block_direction_power(direction: int):
	print("  🧊 Block direction: %d" % direction)
	GameManager.block_direction(direction, GameManager.DEFAULT_BLOCK_TURNS)


# Lightning power
func _execute_lightning_power(emitter, targets: Array, grid_manager):
	print("  ⚡ Lightning: %d targets" % targets.size())

	var effect = func():
		for target in targets:
			if is_instance_valid(target):
				PowerEffect.lightning_strike_effect(target)

	await _execute_destroy_targets_power(emitter, targets, grid_manager, 0.3, effect)


# Nuclear power
func _execute_nuclear_power(emitter, targets: Array, grid_manager):
	print("  ☢️ Nuclear: %d targets" % targets.size())

	_start_tile_visual_effects(emitter, targets, 1.5)
	await PowerEffect.nuclear_flash(emitter, targets, grid_manager)
	_stop_tile_visual_effects(emitter, targets)


# Blind power (uses GameManager for state)
func _execute_blind_power(emitter):
	print("  👁️ Blind: activating")

	if emitter != null and is_instance_valid(emitter):
		emitter.start_emitter_effect(4.0)

	GameManager.activate_blind(GameManager.DEFAULT_BLIND_TURNS)


# Bowling power (uses factorized destroy helper)
func _execute_bowling_power(emitter, targets: Array, grid_manager):
	print("  🎳 Bowling: %d targets" % targets.size())
	await _execute_destroy_targets_power(emitter, targets, grid_manager, 0.5)


# Ads power (placeholder)
func _execute_ads_power(emitter):
	print("  📺 Ads: showing ad (placeholder)")


# ============================
# Utility Methods
# ============================

# Get animation duration for a power type
func get_power_animation_duration(power_type: String):
	var power_info = POWERS.get(power_type, {})
	return power_info.get("duration", 1.0)


# Get power info
func get_power_info(power_type: String):
	return POWERS.get(power_type, {})
