# PowerManager for Fusion Mania
# Manages the 20 power types and their activation
extends Node

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
func resolve_power_merge(power1: String, power2: String) -> String:
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


# Activate a power (placeholder - will be implemented in Phase 3)
func activate_power(power_type: String, tile, grid_manager):
	if power_type == "":
		return
	
	print("🔥 Activating power: %s" % power_type)
	power_activated.emit(power_type, tile)
	AudioManager.play_sfx_power()
	
	# TODO: Implement individual power effects in Phase 3
	
	power_effect_completed.emit(power_type)


# Get power data
func get_power_data(power_type: String) -> Dictionary:
	return POWER_DATA.get(power_type, {})
