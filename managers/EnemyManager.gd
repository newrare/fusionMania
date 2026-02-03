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
signal enemy_defeated(enemy_level: int, score_bonus: int)
signal respawn_timer_updated(moves_remaining: int)

# Active enemy tracking
var active_enemy: Dictionary = {}
var moves_until_respawn: int = 0
var enemy_defeated_flag: bool = false
var first_fusion_occurred: bool = false


func _ready():
	print("👾 EnemyManager ready")
	
	# Connect to GameManager signal for reset
	GameManager.game_started.connect(reset)


# Spawn a new enemy based on current grid state
func spawn_enemy():
	# Mark first fusion as occurred
	first_fusion_occurred = true
	
	var max_tile = get_max_tile_value()
	var level = select_random_level(max_tile)
	var enemy_name = get_random_name()
	var max_hp = HP_BY_LEVEL.get(level, 10)
	var sprite_path = get_random_sprite_path(level)
	var available_powers = ENEMY_POWERS_BY_LEVEL.get(level, [])

	active_enemy = {
		"level": level,
		"name": enemy_name,
		"max_hp": max_hp,
		"current_hp": max_hp,
		"sprite_path": sprite_path,
		"powers": available_powers
	}

	print("👾 Enemy spawned: %s (Lv.%d, HP:%d)" % [enemy_name, level, max_hp])
	enemy_spawned.emit(active_enemy)


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


# Get random sprite path based on enemy level
func get_random_sprite_path(level: int):
	var sprite_prefix = ""

	if level == 2048:
		sprite_prefix = "enemy_mainboss_"
	elif level == 1024:
		sprite_prefix = "enemy_subboss_"
	else:
		sprite_prefix = "enemy_idle_"

	# Count available sprite variants
	var variant_count = count_sprite_variants(sprite_prefix)
	var random_variant = randi() % variant_count + 1

	# Use %02d for zero-padded format (enemy_idle_01.png, enemy_idle_02.png, etc.)
	return "res://assets/images/%s%02d.png" % [sprite_prefix, random_variant]


# Count available sprite variants in assets/images/
func count_sprite_variants(prefix: String):
	var dir = DirAccess.open("res://assets/images/")
	if dir == null:
		print("⚠️ Could not open assets/images/ directory")
		return 1

	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.begins_with(prefix) and file_name.ends_with(".png"):
			count += 1
		file_name = dir.get_next()

	dir.list_dir_end()

	# Fallback to 1 if no variants found
	return max(count, 1)


# Apply damage to active enemy
func damage_enemy(amount: int):
	if not is_enemy_active():
		return

	active_enemy.current_hp -= amount
	active_enemy.current_hp = max(0, active_enemy.current_hp)

	print("⚔️ Enemy damaged: -%d HP (remaining: %d/%d)" % [amount, active_enemy.current_hp, active_enemy.max_hp])
	enemy_damaged.emit(amount, active_enemy.current_hp)

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
		active_enemy = {
			"level": level,
			"name": data.get("enemy_name", "Unknown"),
			"max_hp": data.get("enemy_max_hp", HP_BY_LEVEL.get(level, 10)),
			"current_hp": data.get("enemy_hp", 10),
			"sprite_path": data.get("enemy_sprite_path", ""),
			"powers": ENEMY_POWERS_BY_LEVEL.get(level, [])
		}
		print("📂 Enemy restored: %s (Lv.%d, HP:%d/%d)" % [active_enemy.name, level, active_enemy.current_hp, active_enemy.max_hp])
		enemy_spawned.emit(active_enemy)
