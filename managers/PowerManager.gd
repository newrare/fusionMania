# PowerManager for Fusion Mania
# Manages the 20 power types and their activation
extends Node

# Load PowerEffect for visual effects
const PowerEffect = preload("res://visuals/PowerEffect.gd")

# Power data with spawn rates
const POWER_DATA = {
	"empty":        {"name": "Empty",           "spawn_rate": 30, "type": "none"},
	"fire_h":       {"name": "Fire Row",        "spawn_rate": 5,  "type": "bonus"},
	"fire_v":       {"name": "Fire Column",     "spawn_rate": 5,  "type": "bonus"},
	"fire_cross":   {"name": "Fire Cross",      "spawn_rate": 5,  "type": "bonus"},
	"bomb":         {"name": "Bomb",            "spawn_rate": 5,  "type": "bonus"},
	"ice":          {"name": "Ice",             "spawn_rate": 6,  "type": "malus"},
	"switch_h":     {"name": "Switch H",        "spawn_rate": 5,  "type": "bonus"},
	"switch_v":     {"name": "Switch V",        "spawn_rate": 5,  "type": "bonus"},
	"teleport":     {"name": "Teleport",        "spawn_rate": 2,  "type": "bonus"},
	"expel_h":      {"name": "Expel H",         "spawn_rate": 5,  "type": "bonus"},
	"expel_v":      {"name": "Expel V",         "spawn_rate": 5,  "type": "bonus"},
	"freeze_up":    {"name": "Freeze Up",       "spawn_rate": 5,  "type": "malus"},
	"freeze_down":  {"name": "Freeze Down",     "spawn_rate": 5,  "type": "malus"},
	"freeze_left":  {"name": "Freeze Left",     "spawn_rate": 5,  "type": "malus"},
	"freeze_right": {"name": "Freeze Right",    "spawn_rate": 5,  "type": "malus"},
	"lightning":    {"name": "Lightning",       "spawn_rate": 2,  "type": "bonus"},
	"nuclear":      {"name": "Nuclear",         "spawn_rate": 1,  "type": "bonus"},
	"blind":        {"name": "Blind",           "spawn_rate": 2,  "type": "malus"},
	"bowling":      {"name": "Bowling",         "spawn_rate": 2,  "type": "bonus"},
	"ads":          {"name": "Ads",             "spawn_rate": 5,  "type": "malus"}
}

# Signals
signal power_activated(power_type: String, tile)
signal power_effect_completed(power_type: String)

func _ready():
	print("⚡ PowerManager ready with %d powers" % POWER_DATA.size())


# Get a random power based on spawn rates
func get_random_power() -> String:
	var total_rate = 0
	for power_key in POWER_DATA.keys():
		total_rate += POWER_DATA[power_key].spawn_rate

	var random_value = randf() * total_rate
	var current_sum = 0

	for power_key in POWER_DATA.keys():
		current_sum += POWER_DATA[power_key].spawn_rate
		if random_value <= current_sum:
			return power_key if power_key != "empty" else ""

	return ""  # Default: no power


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
	var rate1 = POWER_DATA.get(power1, {}).get("spawn_rate", 100)
	var rate2 = POWER_DATA.get(power2, {}).get("spawn_rate", 100)

	if rate1 < rate2:
		return power1  # power1 is rarer
	elif rate2 < rate1:
		return power2  # power2 is rarer
	else:
		# Same rarity: keep the one from the initiating tile (handled by caller)
		return power1


# Activate a power
func activate_power(power_type: String, tile, grid_manager):
	if power_type == "" or power_type == "empty":
		return

	print("🔥 Activating power: %s" % power_type)
	power_activated.emit(power_type, tile)
	AudioManager.play_sfx_power()

	# Switch case for all 20 powers (placeholder implementations for Phase 2)
	match power_type:
		"fire_h":
			activate_fire_horizontal(tile, grid_manager)
		"fire_v":
			activate_fire_vertical(tile, grid_manager)
		"fire_cross":
			activate_fire_cross(tile, grid_manager)
		"bomb":
			activate_bomb(tile, grid_manager)
		"ice":
			activate_ice(tile, grid_manager)
		"switch_h":
			activate_switch_horizontal(tile, grid_manager)
		"switch_v":
			activate_switch_vertical(tile, grid_manager)
		"teleport":
			activate_teleport(tile, grid_manager)
		"expel_h":
			activate_expel_horizontal(tile, grid_manager)
		"expel_v":
			activate_expel_vertical(tile, grid_manager)
		"freeze_up":
			activate_freeze_direction(GridManager.Direction.UP, grid_manager)
		"freeze_down":
			activate_freeze_direction(GridManager.Direction.DOWN, grid_manager)
		"freeze_left":
			activate_freeze_direction(GridManager.Direction.LEFT, grid_manager)
		"freeze_right":
			activate_freeze_direction(GridManager.Direction.RIGHT, grid_manager)
		"lightning":
			activate_lightning(tile, grid_manager)
		"nuclear":
			activate_nuclear(tile, grid_manager)
		"blind":
			activate_blind(tile, grid_manager)
		"bowling":
			activate_bowling(tile, grid_manager)
		"ads":
			activate_ads(tile, grid_manager)

	power_effect_completed.emit(power_type)


# ============================
# Power Implementations
# (Placeholder for Phase 2)
# ============================

# Fire Horizontal - Destroys entire row
func activate_fire_horizontal(tile, grid_manager):
	var row = tile.grid_position.y

	# Destroy entire row
	for x in range(grid_manager.grid_size):
		var target = grid_manager.get_tile_at(Vector2i(x, row))
		if target != null and target != tile:
			grid_manager.destroy_tile(target)

	# Visual effect
	PowerEffect.fire_line_effect(row, true)  # true = horizontal


# Fire Vertical - Destroys entire column
func activate_fire_vertical(tile, grid_manager):
	var col = tile.grid_position.x

	# Destroy entire column
	for y in range(grid_manager.grid_size):
		var target = grid_manager.get_tile_at(Vector2i(col, y))
		if target != null and target != tile:
			grid_manager.destroy_tile(target)

	# Visual effect
	PowerEffect.fire_line_effect(col, false)  # false = vertical


# Fire Cross - Destroys row AND column
func activate_fire_cross(tile, grid_manager):
	var row = tile.grid_position.y
	var col = tile.grid_position.x

	# Destroy entire row
	for x in range(grid_manager.grid_size):
		var target = grid_manager.get_tile_at(Vector2i(x, row))
		if target != null and target != tile:
			grid_manager.destroy_tile(target)

	# Destroy entire column
	for y in range(grid_manager.grid_size):
		var target = grid_manager.get_tile_at(Vector2i(col, y))
		if target != null and target != tile:
			grid_manager.destroy_tile(target)

	# Visual effects
	PowerEffect.fire_line_effect(row, true)   # horizontal
	PowerEffect.fire_line_effect(col, false)  # vertical


# Bomb - Destroys adjacent tiles (8 directions)
func activate_bomb(tile, grid_manager):
	var pos = tile.grid_position

	# Adjacent positions (8 directions)
	var adjacent = [
		Vector2i(pos.x - 1, pos.y - 1), Vector2i(pos.x, pos.y - 1), Vector2i(pos.x + 1, pos.y - 1),
		Vector2i(pos.x - 1, pos.y),                                 Vector2i(pos.x + 1, pos.y),
		Vector2i(pos.x - 1, pos.y + 1), Vector2i(pos.x, pos.y + 1), Vector2i(pos.x + 1, pos.y + 1)
	]

	for adj_pos in adjacent:
		# Check bounds
		if adj_pos.x >= 0 and adj_pos.x < grid_manager.grid_size and adj_pos.y >= 0 and adj_pos.y < grid_manager.grid_size:
			var target = grid_manager.get_tile_at(adj_pos)
			if target != null:
				grid_manager.destroy_tile(target)

	# Visual effect
	PowerEffect.explosion_effect(tile.position)


# Ice - Freezes tile for 5 turns
func activate_ice(tile, grid_manager):
	if tile.has_method("set_frozen"):
		tile.set_frozen(true, 5)
	PowerEffect.freeze_effect(tile)


# Switch Horizontal - Swaps 2 random horizontal adjacent tiles
func activate_switch_horizontal(tile, grid_manager):
	var pos    = tile.grid_position
	var left   = Vector2i(pos.x - 1, pos.y)
	var right  = Vector2i(pos.x + 1, pos.y)

	var left_tile  = grid_manager.get_tile_at(left) if pos.x > 0 else null
	var right_tile = grid_manager.get_tile_at(right) if pos.x < grid_manager.grid_size - 1 else null

	# Swap the tiles if both exist
	if left_tile != null and right_tile != null:
		grid_manager.swap_tiles(left_tile, right_tile)


# Switch Vertical - Swaps 2 random vertical adjacent tiles
func activate_switch_vertical(tile, grid_manager):
	var pos   = tile.grid_position
	var up    = Vector2i(pos.x, pos.y - 1)
	var down  = Vector2i(pos.x, pos.y + 1)

	var up_tile   = grid_manager.get_tile_at(up) if pos.y > 0 else null
	var down_tile = grid_manager.get_tile_at(down) if pos.y < grid_manager.grid_size - 1 else null

	# Swap the tiles if both exist
	if up_tile != null and down_tile != null:
		grid_manager.swap_tiles(up_tile, down_tile)


# Teleport - Player chooses 2 tiles to swap (simplified: random swap)
func activate_teleport(tile, grid_manager):
	# Get all tiles
	var all_tiles = []
	for y in range(grid_manager.grid_size):
		for x in range(grid_manager.grid_size):
			var t = grid_manager.get_tile_at(Vector2i(x, y))
			if t != null and t != tile:
				all_tiles.append(t)

	# Swap two random tiles if we have at least 2
	if all_tiles.size() >= 2:
		all_tiles.shuffle()
		grid_manager.swap_tiles(all_tiles[0], all_tiles[1])


# Expel Horizontal - Ejects edge tile horizontally
func activate_expel_horizontal(tile, grid_manager):
	var pos = tile.grid_position

	# Choose left or right edge tile
	var left_tile  = grid_manager.get_tile_at(Vector2i(0, pos.y))
	var right_tile = grid_manager.get_tile_at(Vector2i(grid_manager.grid_size - 1, pos.y))

	# Destroy whichever exists (prioritize left)
	if left_tile != null and left_tile != tile:
		grid_manager.destroy_tile(left_tile)
	elif right_tile != null and right_tile != tile:
		grid_manager.destroy_tile(right_tile)


# Expel Vertical - Ejects edge tile vertically
func activate_expel_vertical(tile, grid_manager):
	var pos = tile.grid_position

	# Choose top or bottom edge tile
	var top_tile    = grid_manager.get_tile_at(Vector2i(pos.x, 0))
	var bottom_tile = grid_manager.get_tile_at(Vector2i(pos.x, grid_manager.grid_size - 1))

	# Destroy whichever exists (prioritize top)
	if top_tile != null and top_tile != tile:
		grid_manager.destroy_tile(top_tile)
	elif bottom_tile != null and bottom_tile != tile:
		grid_manager.destroy_tile(bottom_tile)


# Freeze Direction - Blocks movement in one direction for 2 turns
func activate_freeze_direction(direction, grid_manager):
	grid_manager.freeze_direction(direction, 2)


# Lightning - Destroys 4 random tiles
func activate_lightning(tile, grid_manager):
	var all_tiles = []

	# Get all tiles except source
	for y in range(grid_manager.grid_size):
		for x in range(grid_manager.grid_size):
			var t = grid_manager.get_tile_at(Vector2i(x, y))
			if t != null and t != tile:
				all_tiles.append(t)

	# Choose up to 4 random tiles
	all_tiles.shuffle()
	var targets = all_tiles.slice(0, mini(4, all_tiles.size()))

	# Destroy with effect
	for target in targets:
		PowerEffect.lightning_strike_effect(target)
		grid_manager.destroy_tile(target)


# Nuclear - Destroys all tiles
func activate_nuclear(tile, grid_manager):
	PowerEffect.nuclear_flash()

	# Destroy all tiles except source
	for y in range(grid_manager.grid_size):
		for x in range(grid_manager.grid_size):
			var t = grid_manager.get_tile_at(Vector2i(x, y))
			if t != null and t != tile:
				grid_manager.destroy_tile(t)


# Blind - Black grid for 2 turns
func activate_blind(tile, grid_manager):
	grid_manager.set_blind_mode(true, 2)
	PowerEffect.blind_overlay(2.0)


# Bowling - Ball crosses and destroys tiles in a line
func activate_bowling(tile, grid_manager):
	var pos       = tile.grid_position
	var direction = randi() % 4  # Random direction
	var dx        = 0
	var dy        = 0

	match direction:
		0: dy = -1  # Up
		1: dy = 1   # Down
		2: dx = -1  # Left
		3: dx = 1   # Right

	# Destroy tiles in that direction
	var current = Vector2i(pos.x + dx, pos.y + dy)
	while current.x >= 0 and current.x < grid_manager.grid_size and \
		  current.y >= 0 and current.y < grid_manager.grid_size:
		var target = grid_manager.get_tile_at(current)
		if target != null:
			grid_manager.destroy_tile(target)
		current.x += dx
		current.y += dy


# Ads - Shows ad for X seconds (simplified: just delay)
func activate_ads(tile, grid_manager):
	# In a real implementation, this would show an ad
	# For now, just print a message
	print("  📺 Showing ad... (placeholder)")


# Get power data
func get_power_data(power_type: String) -> Dictionary:
	return POWER_DATA.get(power_type, {})
