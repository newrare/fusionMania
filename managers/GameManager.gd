# GameManager for Fusion Mania
# Reviewed
extends Node

const STATES = {
	"MENU": 	"menu",
	"PLAYING": 	"playing",
}

const MODES = {
	"MANIA": 	"mania",	# Powers activated by enemy spawn
	"CLASSIC": 	"classic",  # No powers, no enemies
	"FREE": 	"free"     	# Powers chosen by player and tile spawn with powers already set, no enemies
}

var powers = {
	"none": 		"none",
	"blind": 		{"active": false, "move": 3, "remaining": 0},
	"ice": 			{"active": false, "move": 2, "remaining": 0},
	"block_up": 	{"active": false, "move": 3, "remaining": 0},
	"block_down": 	{"active": false, "move": 3, "remaining": 0},
	"block_left": 	{"active": false, "move": 3, "remaining": 0},
	"block_right": 	{"active": false, "move": 3, "remaining": 0}
}

var currents = {
	"state":	STATES.MENU,
	"mode": 	MODES.MANIA,
	"power":	powers.none
}

var party_started: bool = false
var start_after_reload: bool = false  # Flag to indicate game should start after scene reload


# Signals (minimal required)
signal game_started()
signal game_ended(victory: bool)
signal game_paused()
signal game_resumed()
signal blind_started()
signal blind_ended()
signal direction_blocked(direction: int, turns: int)
signal direction_unblocked(direction: int)

func _ready():
	print("GameManager ready")


# Start a new game
func start():
	# Reset persistent power states
	power_reset()

	# Initialize game session data in SaveManager
	SaveManager.init_game_session()

	# Mark game as started
	party_started = true

	# Reset score and grid (this clears visual tiles and spawns new ones)
	ScoreManager.start_game()
	GridManager.start_new_game()

	# Update state and emit signal
	currents["state"] = STATES.PLAYING
	game_started.emit()

# Check party started
func is_party_started():
	return party_started

# Check states
func is_state_playing():
	return currents["state"] == STATES.PLAYING

func is_state_in_menu():
	return currents["state"] == STATES.MENU


# Check mode
func is_mode_mania():
	return currents["mode"] == MODES.MANIA

func is_mode_classic():
	return currents["mode"] == MODES.CLASSIC

func is_mode_free():
	return currents["mode"] == MODES.FREE


# Check active powers
func is_power_blind():
	return powers["blind"]["active"]

func is_power_ice():
	return powers["ice"]["active"]

func is_power_block_up():
	return powers["block_up"]["active"]

func is_power_block_down():
	return powers["block_down"]["active"]

func is_power_block_left():
	return powers["block_left"]["active"]

func is_power_block_right():
	return powers["block_right"]["active"]

func is_power_block_by_string(direction: String):
	direction = direction.to_lower()
	return powers["block_" + direction]["active"]

func is_power_block_by_int(direction: int):
	match direction:
		0: return is_power_block_up()
		1: return is_power_block_down()
		2: return is_power_block_left()
		3: return is_power_block_right()
		_: return false

func is_power_none():
	return currents["power"] == powers.none


# Power setter
func power_activate(power_name: String):
	if powers.has(power_name):
		powers[power_name]["active"] 	= true
		powers[power_name]["remaining"] = powers[power_name]["move"]

		# Emit signals for specific powers
		if power_name == "blind":
			blind_started.emit()
		elif power_name in ["block_up", "block_down", "block_left", "block_right"]:
			var direction_map = {"block_up": 0, "block_down": 1, "block_left": 2, "block_right": 3}
			if direction_map.has(power_name):
				direction_blocked.emit(direction_map[power_name], powers[power_name]["move"])


# Power remaining
func power_decrement():
	for key in powers.keys():
		var power = powers[key]
		if typeof(power) != TYPE_DICTIONARY:
			continue

		if not power.has("active") or not power["active"]:
			continue

		if power["remaining"] > 0:
			power["remaining"] -= 1

			if power["remaining"] == 0:
				power["active"] = false

				# Emit signals when powers end
				if key == "blind":
					blind_ended.emit()
				elif key in ["block_up", "block_down", "block_left", "block_right"]:
					var direction_map = {"block_up": 0, "block_down": 1, "block_left": 2, "block_right": 3}
					if direction_map.has(key):
						direction_unblocked.emit(direction_map[key])

# Reset all persistent power states
func power_reset():
	powers["blind"]["active"] 			= false
	powers["blind"]["remaining"] 		= 0
	powers["block_up"]["active"] 		= false
	powers["block_up"]["remaining"] 	= 0
	powers["block_down"]["active"] 		= false
	powers["block_down"]["remaining"] 	= 0
	powers["block_left"]["active"] 		= false
	powers["block_left"]["remaining"] 	= 0
	powers["block_right"]["active"] 	= false
	powers["block_right"]["remaining"] 	= 0
	powers["ice"]["active"] 			= false
	powers["ice"]["remaining"] 			= 0

# Enter Mania Mode (powers activated by enemy spawn)
func set_mode_mania():
	if currents["mode"] == MODES.MANIA:
		return

	# Set mode
	currents["mode"] = MODES.MANIA


# Enter Classic Mode (no powers, no enemies)
func set_mode_classic():
	if currents["mode"] == MODES.CLASSIC:
		return

	# Set mode
	currents["mode"] = MODES.CLASSIC

	# Force no powers
	PowerManager.set_no_powers()

	# Force no enemies


# Enter Free Mode (powers automatically assigned to tiles, no enemies)
func set_mode_free(selected_powers = []):
	if currents["mode"] == MODES.FREE:
		return

	# Set mode
	currents["mode"] = MODES.FREE

	# Force spawn rates
	PowerManager.set_custom_spawn_rates(selected_powers)


# Enter Menu
func set_state_menu():
	if currents["state"] == STATES.PLAYING:
		currents["state"] = STATES.MENU
		game_paused.emit()


# Enter Playing
func set_state_playing():
	if currents["state"] == STATES.MENU:
		currents["state"] = STATES.PLAYING
		game_resumed.emit()
