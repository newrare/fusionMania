# AudioManager for Fusion Mania
# Manages all audio and music for the game
extends Node

# Default volume off for Godot (best practice)
var volume_off: 	float = -80.0
var volume_reduced: float = -40.0

# Sound dictionary - adapted for Fusion Mania
var sounds = {
	"music_background":	{"stream": null, "audio": null, "file": "res://assets/sounds/music_background.mp3", 	"volume": -19.0},
	"sfx_move":			{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_move.wav",			"volume": -10.0},
	"sfx_fusion":		{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_fusion.wav",			"volume": -5.0},
	"sfx_power":		{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_power.wav",			"volume": -5.0},
	"sfx_game_over":	{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_game_over.mp3",		"volume": -5.0},
	"sfx_win":			{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_win.mp3",				"volume": -5.0},
	"sfx_button_hover":	{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_button_hover.wav",		"volume": -10.0},
	"sfx_button_click":	{"stream": null, "audio": null, "file": "res://assets/sounds/sfx_button_click.wav",		"volume": -10.0}
}

# Mute state flags
var is_music_muted:		bool = false
var is_sfx_muted:		bool = false
var is_cleaned_up:		bool = false

# Settings file path
const SETTINGS_PATH = "user://audio_settings.cfg"



##################
### METHODS GD ###
##################

# Load
func _ready():
	load_settings()
	setup_audio_players()
	load_audio_resources()
	start_music_background()

	print("🎵 AudioManager ready")


# Cleanup - called when the node is about to be removed
func _exit_tree():
	cleanup()


# Also catch window close events
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		cleanup()
		get_tree().quit()
	elif what == NOTIFICATION_PREDELETE:
		cleanup()

# Stop and disconnect all audio players
func cleanup():
	# Prevent double cleanup
	if is_cleaned_up:
		return

	is_cleaned_up = true

	print("🧹 AudioManager cleanup starting...")

	for key in sounds.keys():
		var sound = sounds[key]

		if sound["audio"]:
			# Disconnect signals
			if key == "music_background" and sound["audio"].finished.is_connected(_on_music_finished):
				sound["audio"].finished.disconnect(_on_music_finished)

			# CRITICAL: Stop playback first
			if sound["audio"].playing:
				sound["audio"].stop()

			# Clear stream from player BEFORE removing from tree
			sound["audio"].stream = null

			# Remove from tree and free immediately (not deferred)
			if sound["audio"].get_parent():
				remove_child(sound["audio"])

			# Use free() instead of queue_free() during cleanup to ensure immediate deallocation
			sound["audio"].free()
			sound["audio"] = null

		# This is crucial for preventing resource leaks with loaded audio files
		if sound["stream"]:
			sound["stream"] = null

	# Clear the entire sounds dictionary
	sounds.clear()

	print("✓ AudioManager cleanup completed")

# Event
func _on_music_finished():
	var music = sounds["music_background"]

	if music["audio"] and music["stream"]:
		music["audio"].play()
		print("🔄 Background music looped")



###############
### METHODS ###
###############

# Set player
func setup_audio_players():
	for key in sounds.keys():
		var sound			= sounds[key]
		var audio			= AudioStreamPlayer.new()

		audio.name			= key
		audio.volume_db		= sound["volume"]
		audio.process_mode	= Node.PROCESS_MODE_ALWAYS
		sound["audio"]		= audio

		add_child(audio)

# Set file
func load_audio_resources():
	for key in sounds.keys():
		var sound	= sounds[key]
		var path	= sound["file"]

		if ResourceLoader.exists(path):
			# Load with default cache mode (Godot handles cleanup automatically)
			var stream: AudioStream = load(path)

			if stream:
				sound["stream"] = stream
				if sound["audio"]:
					sound["audio"].stream = stream
				print("✅ Loaded: %s" % path)
			else:
				print("❌ Failed to load %s" % path)
		else:
			print("❌ File not found: %s" % path)



# Start music
func start_music_background():
	var music = sounds["music_background"]

	if not music["audio"] or not music["stream"]:
		print("❌ Cannot start music background: missing audio player or stream")
		return

	music["audio"].stream = music["stream"]

	# Connect signal only if not already connected
	if not music["audio"].finished.is_connected(_on_music_finished):
		music["audio"].finished.connect(_on_music_finished)

	# Apply mute state before playing
	if is_music_muted:
		music["audio"].volume_db = volume_off
		print("🔇 Music background started (muted)")
	else:
		music["audio"].volume_db = music["volume"]
		print("🎵 Music background started")

	music["audio"].play()



# Play sfx move (tile movement)
func play_sfx_move():
	if is_sfx_muted:
		return

	var move = sounds["sfx_move"]
	if not move["audio"] or not move["stream"]:
		print("❌ Cannot play move sfx: missing audio player or stream")
		return

	move["audio"].play()

# Play sfx fusion (tile merge)
func play_sfx_fusion():
	if is_sfx_muted:
		return

	var fusion = sounds["sfx_fusion"]
	if not fusion["audio"] or not fusion["stream"]:
		print("❌ Cannot play fusion sfx: missing audio player or stream")
		return

	fusion["audio"].play()

# Play sfx power (power activation)
func play_sfx_power():
	if is_sfx_muted:
		return

	var power = sounds["sfx_power"]
	if not power["audio"] or not power["stream"]:
		print("❌ Cannot play power sfx: missing audio player or stream")
		return

	power["audio"].play()

# Play sfx button hover
func play_sfx_button_hover():
	if is_sfx_muted:
		return

	var hover = sounds["sfx_button_hover"]

	if not hover["audio"] or not hover["stream"]:
		print("❌ Cannot play button hover sfx: missing audio player or stream")
		return

	hover["audio"].play()

# Play sfx button click
func play_sfx_button_click():
	if is_sfx_muted:
		return

	var click = sounds["sfx_button_click"]

	if not click["audio"] or not click["stream"]:
		print("❌ Cannot play button click sfx: missing audio player or stream")
		return

	click["audio"].play()

# Play game over sound
func play_sfx_game_over():
	if is_sfx_muted:
		return

	var game_over = sounds["sfx_game_over"]

	if not game_over["audio"] or not game_over["stream"]:
		print("❌ Cannot play game over sfx: missing audio player or stream")
		return

	game_over["audio"].play()

# Play win sound
func play_sfx_win():
	if is_sfx_muted:
		return

	var win = sounds["sfx_win"]

	if not win["audio"] or not win["stream"]:
		print("❌ Cannot play win sfx: missing audio player or stream")
		return

	win["audio"].play()

# Music control
func toggle_music():
	is_music_muted = !is_music_muted
	var music = sounds["music_background"]

	if is_music_muted:
		music["audio"].volume_db = volume_off
		print("🔇 Music muted")
	else:
		music["audio"].volume_db = music["volume"]
		print("🎵 Music unmuted")

	save_settings()

# SFX control
func toggle_sfx():
	is_sfx_muted = !is_sfx_muted

	if is_sfx_muted:
		print("🔇 SFX muted")
	else:
		print("🔊 SFX unmuted")

	save_settings()

# Load settings
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err == OK:
		is_music_muted = config.get_value("audio", "music_muted", false)
		is_sfx_muted = config.get_value("audio", "sfx_muted", false)
		print("✅ Audio settings loaded")
	else:
		print("ℹ️ No audio settings file found, using defaults")

# Save settings
func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music_muted", is_music_muted)
	config.set_value("audio", "sfx_muted", is_sfx_muted)

	var err = config.save(SETTINGS_PATH)
	if err == OK:
		print("✅ Audio settings saved")
	else:
		print("❌ Failed to save audio settings: error %d" % err)

# Getters for UI
func is_music_enabled():
	return not is_music_muted

func is_sfx_enabled():
	return not is_sfx_muted
