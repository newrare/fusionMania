# EnemyManager for Fusion Mania
# Manages enemy spawning, combat, and respawn logic
extends Node

# Enemy levels matching tile values
const ENEMY_LEVELS = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]

# HP values for each enemy level (doubling each level)
const HP_BY_LEVEL = {
	2: 10,
	4: 20,
	8: 40,
	16: 80,
	32: 160,
	64: 320,
	128: 640,
	256: 1280,
	512: 2560,
	1024: 5120,
	2048: 10240
}

# 100 math-themed funny enemy names
const ENEMY_NAMES = [
	# Mathematicians Puns
	"Pythagoron", "Euclidor", "Archimedon", "Fibonaccio", "Gaussinator",
	"Eulerix", "Newtonix", "Leibnizor", "Fermatron", "Riemannox",
	"Lovelacix", "Turingbot", "Babbagon", "Pascalor", "Descartox",

	# Number Puns
	"Infinitron", "Zeronator", "Primox", "Divisor", "Factorion",
	"Modulox", "Integerix", "Decimalon", "Fractionor", "Radicalix",

	# Operation Puns
	"Addinator", "Subtractron", "Multiplox", "Dividron", "Exponix",
	"Sqrootox", "Logarix", "Derivator", "Integron", "Limitron",

	# Shape Puns
	"Trianglor", "Squarox", "Circleon", "Hexagonix", "Polygonor",
	"Cubixon", "Spherion", "Pyramidex", "Cylindrix", "Conixor",

	# Algebra Puns
	"Variablex", "Constantor", "Coefficix", "Polynomor", "Equatron",
	"Formulix", "Theoremon", "Axiomox", "Postulator", "Lemmatron",

	# Geometry Puns
	"Angulator", "Perpendix", "Parallelon", "Tangentrix", "Secantox",
	"Vectorix", "Matrixor", "Tensoron", "Dimensior", "Planeton",

	# Calculus Puns
	"Deltarix", "Epsilonor", "Sigmator", "Thetanox", "Omegabot",
	"Infinitix", "Asymptron", "Convergix", "Divergon", "Seriestor",

	# Statistics Puns
	"Meanator", "Medianox", "Modexor", "Deviatron", "Variancix",
	"Probabilor", "Randomix", "Sampleton", "Correlator", "Regrexor",

	# Logic Puns
	"Booleanix", "Andgator", "Orgonix", "Notronix", "Xorinator",
	"Nandexor", "Normatron", "Implicor", "Biconditrix", "Negator",

	# Set Theory Puns
	"Unionix", "Intersector", "Subsetron", "Complementor", "Emptixor",
	"Cardinalix", "Ordinalon", "Powersetor", "Bijector", "Surjexor",

	# Famous Numbers
	"Piratrix", "Eulerion", "Goldenox", "Avogadrix", "Plancktor",
	"Imaginarix", "Complexor", "Rationalon", "Irrationalix", "Transcendor"
]

# Available powers by enemy level
const ENEMY_POWERS_BY_LEVEL = {
	2: 		["block_up", "block_down", "block_left", "block_right"],
	4: 		["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v"],
	8: 		["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport"],
	16: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice"],
	32: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v"],
	64: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb"],
	128: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v"],
	256: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind"],
	512: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind", "lightning"],
	1024: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind", "lightning", "fire_cross"],
	2048: 	["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind", "lightning", "fire_cross", "nuclear"]
}

# Signals
signal enemy_spawned(enemy_data: Dictionary)
signal enemy_damaged(damage: int, remaining_hp: int)
signal enemy_sprite_updated(new_sprite_path: String)
signal enemy_defeated(enemy_level: int, score_bonus: int)
signal respawn_timer_updated(moves_remaining: int)
signal power_applied_to_tile(power_type: String, tile_position: Vector2i)
signal power_ball_animation_requested(power_type: String, tile_position: Vector2i)
signal cancel_power_animations()

# Active enemy tracking
var active_enemy: Dictionary = {}
var moves_until_respawn: int = 0
var enemy_defeated_flag: bool = false
var first_fusion_occurred: bool = false
var spawn_protection: bool = false


func _ready():
	print("👾 EnemyManager ready")

	# Connect to GameManager signal for reset
	GameManager.game_started.connect(reset)


# Spawn a new enemy based on current grid state
func spawn_enemy():
	# Do not spawn enemies in Free Mode
	if GameManager.is_free_mode():
		print("🚫 Cannot spawn enemy in FREE mode")
		return

	# Mark first fusion as occurred
	first_fusion_occurred = true

	var max_tile = get_max_tile_value()
	var level = select_random_level(max_tile)
	var enemy_name = get_random_name()
	var max_hp = HP_BY_LEVEL.get(level, 10)
	var sprite_variant = select_random_sprite_variant(level)
	var sprite_path = get_sprite_path_for_health(level, "hight", sprite_variant)
	var available_powers = ENEMY_POWERS_BY_LEVEL.get(level, [])

	active_enemy = {
		"level": level,
		"name": enemy_name,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"sprite_path": sprite_path,
		"sprite_variant": sprite_variant,
		"health_state": "hight",
		"powers": available_powers
	}

	print("👾 Enemy spawned: %s (Lv.%d, HP:%d)" % [enemy_name, level, max_hp])
	enemy_spawned.emit(active_enemy)

	# Enter Fight Mode
	GameManager.enter_fight_mode()

	# Apply first power to a random tile
	apply_power_to_random_tile()


# Get maximum tile value from grid
func get_max_tile_value():
	var max_value = 2

	# Query GridManager for all tiles
	for y in range(GridManager.grid_size):
		for x in range(GridManager.grid_size):
			var tile = GridManager.grid[y][x]
			if tile != null and tile.value > max_value:
				max_value = tile.value

	return max_value


# Get available levels based on max tile value
func get_available_levels(max_tile: int):
	var available = []
	for level in ENEMY_LEVELS:
		if level <= max_tile:
			available.append(level)
	return available


# Select random level from available levels
func select_random_level(max_tile: int):
	var available = get_available_levels(max_tile)
	if available.is_empty():
		return 2
	return available[randi() % available.size()]


# Get random enemy name
func get_random_name():
	return ENEMY_NAMES[randi() % ENEMY_NAMES.size()]


# Select a random sprite variant for the enemy (picks the specific numbered image)
func select_random_sprite_variant(level: int) -> int:
	# Count available variants for this level and health state
	var prefix = "enemy_boss_" if level == 2048 else "enemy_basic_"
	var health_state = "hight"  # Start with hight variants
	var search_prefix = prefix + health_state + "_"
	
	var dir = DirAccess.open("res://assets/images/")
	if dir == null:
		print("⚠️ Could not open assets/images/ directory")
		return 1
	
	var variants = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.begins_with(search_prefix) and file_name.ends_with(".png"):
			# Extract variant number from filename (e.g., "enemy_basic_hight_01.png" -> 1)
			var parts = file_name.replace(".png", "").split("_")
			if parts.size() >= 4:
				var variant_num = int(parts[3])
				if variant_num > 0 and not variants.has(variant_num):
					variants.append(variant_num)
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Return random variant or 1 as fallback
	if variants.is_empty():
		return 1
	return variants[randi() % variants.size()]


# Get sprite path for specific health state
func get_sprite_path_for_health(level: int, health_state: String, variant: int) -> String:
	var prefix = "enemy_boss_" if level == 2048 else "enemy_basic_"
	return "res://assets/images/%s%s_%02d.png" % [prefix, health_state, variant]


# Update enemy sprite based on current health percentage
func update_enemy_sprite_for_health():
	if not is_enemy_active():
		return
	
	var health_percent = float(active_enemy.current_hp) / float(active_enemy.max_hp)
	var new_health_state = ""
	
	# Determine health state based on HP percentage
	if health_percent > 0.66:
		new_health_state = "hight"
	elif health_percent > 0.33:
		new_health_state = "middle"
	else:
		new_health_state = "low"
	
	# Only update if state changed
	if new_health_state != active_enemy.get("health_state", "hight"):
		active_enemy.health_state = new_health_state
		var new_sprite_path = get_sprite_path_for_health(
			active_enemy.level,
			new_health_state,
			active_enemy.sprite_variant
		)
		active_enemy.sprite_path = new_sprite_path
		
		print("🔄 Enemy health state changed to '%s': %s" % [new_health_state, new_sprite_path])
		enemy_sprite_updated.emit(new_sprite_path)


# Apply damage to active enemy
func damage_enemy(amount: int):
	if not is_enemy_active():
		return

	active_enemy.current_hp -= amount
	active_enemy.current_hp = max(0, active_enemy.current_hp)

	print("⚔️ Enemy damaged: -%d HP (remaining: %d/%d)" % [amount, active_enemy.current_hp, active_enemy.max_hp])
	enemy_damaged.emit(amount, active_enemy.current_hp)

	# Update sprite based on health state
	update_enemy_sprite_for_health()

	# Check if enemy is defeated
	if active_enemy.current_hp <= 0:
		defeat_enemy()


# Defeat current enemy
func defeat_enemy():
	if not is_enemy_active():
		return

	var enemy_level = active_enemy.level
	var score_bonus = calculate_score_bonus(enemy_level)

	print("💀 Enemy defeated: %s (Lv.%d)" % [active_enemy.name, enemy_level])
	print("🎉 Score bonus: %d (Score: %d × Level: %d)" % [score_bonus, ScoreManager.get_current_score(), enemy_level])

	# Add bonus to score
	ScoreManager.add_score(score_bonus)

	# Clear active enemy
	active_enemy = {}

	# Start respawn timer
	enemy_defeated_flag = true
	moves_until_respawn = 10

	# Return to Classic Mode (this clears all tile powers)
	GameManager.enter_classic_mode()

	# Emit defeat signal
	enemy_defeated.emit(enemy_level, score_bonus)


# Calculate score bonus for defeating enemy
func calculate_score_bonus(enemy_level: int):
	var current_score = ScoreManager.get_current_score()
	return current_score * enemy_level


# Check if enemy is currently active
func is_enemy_active():
	return not active_enemy.is_empty()


# Handle move completion (called after each player move)
func on_move_completed():
	print("🎮 on_move_completed called - enemy_defeated_flag=%s, moves_until_respawn=%d" % [enemy_defeated_flag, moves_until_respawn])

	# In Free Mode, no enemy logic
	if GameManager.is_free_mode():
		return

	# If enemy is active, apply a new power to a random tile
	if is_enemy_active():
		apply_power_to_random_tile()

	# Handle respawn timer
	if enemy_defeated_flag and moves_until_respawn > 0:
		moves_until_respawn -= 1
		print("⏳ Respawn in %d moves" % moves_until_respawn)
		respawn_timer_updated.emit(moves_until_respawn)

		if moves_until_respawn == 0:
			print("🔄 Spawning new enemy!")
			enemy_defeated_flag = false
			spawn_enemy()


# Reset enemy system (for new game)
func reset():
	print("🔄 EnemyManager reset")
	active_enemy = {}
	first_fusion_occurred = false
	enemy_defeated_flag = false
	moves_until_respawn = 0


# Apply a random power from enemy's available powers to a random tile without power
func apply_power_to_random_tile():
	if not is_enemy_active():
		return

	var available_powers = active_enemy.get("powers", [])
	if available_powers.is_empty():
		print("⚠️ Enemy has no available powers")
		return

	# Get all tiles without power
	var tiles_without_power = []
	for y in range(GridManager.grid_size):
		for x in range(GridManager.grid_size):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile != null and tile.power_type == "":
				tiles_without_power.append({"tile": tile, "position": Vector2i(x, y)})
	
	print("🔍 Debug: Found %d tiles without power out of %d total tiles" % [tiles_without_power.size(), GridManager.grid_size * GridManager.grid_size])
	
	# Debug: Print power types of all tiles
	for y in range(GridManager.grid_size):
		for x in range(GridManager.grid_size):
			var tile = GridManager.get_tile_at(Vector2i(x, y))
			if tile != null:
				print("  Tile(%d,%d): value=%d, power='%s'" % [x, y, tile.value, tile.power_type])

	if tiles_without_power.is_empty():
		print("⚠️ No tiles available for power assignment")
		return

	# Select random tile and power
	var random_tile_data = tiles_without_power[randi() % tiles_without_power.size()]
	var random_power = available_powers[randi() % available_powers.size()]

	# Apply power to tile IMMEDIATELY (before animation)
	random_tile_data.tile.power_type = random_power
	random_tile_data.tile.update_visual()

	# Emit signal for power ball animation AFTER applying power
	power_ball_animation_requested.emit(random_power, random_tile_data.position)

	print("⚡ Enemy applied power '%s' to tile at %s" % [random_power, random_tile_data.position])
	power_applied_to_tile.emit(random_power, random_tile_data.position)


# Get save data for persistence
func get_save_data():
	return {
		"has_enemy": is_enemy_active(),
		"enemy_level": active_enemy.get("level", 0),
		"enemy_name": active_enemy.get("name", ""),
		"enemy_sprite_path": active_enemy.get("sprite_path", ""),
		"enemy_hp": active_enemy.get("current_hp", 0),
		"enemy_max_hp": active_enemy.get("max_hp", 0),
		"moves_until_respawn": moves_until_respawn,
		"first_fusion_occurred": first_fusion_occurred
	}


# Load save data
func load_save_data(data: Dictionary):
	first_fusion_occurred = data.get("first_fusion_occurred", false)
	moves_until_respawn = data.get("moves_until_respawn", 0)
	enemy_defeated_flag = moves_until_respawn > 0

	if data.get("has_enemy", false):
		var level = data.get("enemy_level", 2)
		var sprite_path = data.get("enemy_sprite_path", "")
		# Extract variant from sprite path if possible, otherwise use 1
		var sprite_variant = 1
		if sprite_path != "":
			var parts = sprite_path.get_file().replace(".png", "").split("_")
			if parts.size() >= 4:
				sprite_variant = int(parts[3])
		
		active_enemy = {
			"level": level,
			"name": data.get("enemy_name", "Unknown"),
			"max_hp": data.get("enemy_max_hp", HP_BY_LEVEL.get(level, 10)),
			"current_hp": data.get("enemy_hp", 10),
			"sprite_path": sprite_path,
			"sprite_variant": sprite_variant,
			"health_state": "hight",
			"powers": ENEMY_POWERS_BY_LEVEL.get(level, [])
		}
		# Update sprite for current health after loading
		update_enemy_sprite_for_health()
		print("📂 Enemy restored: %s (Lv.%d, HP:%d/%d)" % [active_enemy.name, level, active_enemy.current_hp, active_enemy.max_hp])
		enemy_spawned.emit(active_enemy)
