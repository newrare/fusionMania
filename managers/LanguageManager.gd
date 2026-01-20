# LanguageManager for Fusion Mania
# Manages game localization and translations
extends Node

signal language_changed

var current_language 	= "en"
var available_languages = ["fr", "en"]

# Settings file path
const SETTINGS_PATH = "user://language_settings.cfg"



# Load
func _ready():
	load_basic_translations()
	load_settings()  # Load saved language or use default



func load_basic_translations():
	# EN
	var en_translation 		= Translation.new()
	en_translation.locale 	= "en"

	# Menu
	en_translation.add_message("START", 		"New Game")
	en_translation.add_message("RESUME", 		"Resume")
	en_translation.add_message("RANKING", 		"Ranking")
	en_translation.add_message("RANKING_TITLE", "Ranking")
	en_translation.add_message("OPTIONS", 		"Options")
	en_translation.add_message("PAUSE", 		"Pause")
	en_translation.add_message("QUIT", 			"Quit")
	en_translation.add_message("BACK", 			"Back")

	# Game
	en_translation.add_message("SCORE", 		"Score")
	en_translation.add_message("HIGH_SCORE",	"High Score")
	en_translation.add_message("MOVES",			"Moves")
	en_translation.add_message("GAME_OVER",		"Game Over")
	en_translation.add_message("VICTORY",		"Victory!")
	en_translation.add_message("FINAL_SCORE",	"Final Score")

	# Audio
	en_translation.add_message("MUSIC_ACTIVE",		"Switch off music")
	en_translation.add_message("MUSIC_INACTIVE",	"Switch on music")
	en_translation.add_message("SFX_ACTIVE",		"Switch off sound")
	en_translation.add_message("SFX_INACTIVE",		"Switch on sound")

	# Language
	en_translation.add_message("LANGUAGE",	"Language")
	en_translation.add_message("FRENCH",	"Français")
	en_translation.add_message("ENGLISH",	"English")

	# Actions
	en_translation.add_message("RESET_RANKING", "Reset ranking")
	en_translation.add_message("YES",			"Yes")
	en_translation.add_message("NO",			"No")
	en_translation.add_message("SUCCESS", 		"Success!")
	en_translation.add_message("NO_SCORES",		"No scores yet")

	# Powers
	en_translation.add_message("POWER_FIRE_HORIZONTAL",		"Fire Row")
	en_translation.add_message("POWER_FIRE_VERTICAL",		"Fire Column")
	en_translation.add_message("POWER_FIRE_CROSS",			"Fire Cross")
	en_translation.add_message("POWER_BOMB",				"Bomb")
	en_translation.add_message("POWER_ICE",					"Ice")
	en_translation.add_message("POWER_SWITCH_HORIZONTAL",	"Switch ↔")
	en_translation.add_message("POWER_SWITCH_VERTICAL",		"Switch ↕")
	en_translation.add_message("POWER_TELEPORT",			"Teleport")
	en_translation.add_message("POWER_EXPEL_HORIZONTAL",	"Expel →")
	en_translation.add_message("POWER_EXPEL_VERTICAL",		"Expel ↓")
	en_translation.add_message("POWER_FREEZE_UP",			"Freeze ↑")
	en_translation.add_message("POWER_FREEZE_DOWN",			"Freeze ↓")
	en_translation.add_message("POWER_FREEZE_LEFT",			"Freeze ←")
	en_translation.add_message("POWER_FREEZE_RIGHT",		"Freeze →")
	en_translation.add_message("POWER_LIGHTNING",			"Lightning")
	en_translation.add_message("POWER_NUCLEAR",				"Nuclear")
	en_translation.add_message("POWER_BLIND",				"Blind")
	en_translation.add_message("POWER_BOWLING",				"Bowling")
	en_translation.add_message("POWER_ADS",					"Ads")

	TranslationServer.add_translation(en_translation)

	# FR
	var fr_translation 		= Translation.new()
	fr_translation.locale 	= "fr"

	# Menu
	fr_translation.add_message("START", 		"Nouvelle Partie")
	fr_translation.add_message("RESUME", 		"Reprendre")
	fr_translation.add_message("RANKING",		"Classement")
	fr_translation.add_message("RANKING_TITLE",	"Classement")
	fr_translation.add_message("OPTIONS", 		"Options")
	fr_translation.add_message("PAUSE", 		"Pause")
	fr_translation.add_message("QUIT", 			"Quitter")
	fr_translation.add_message("BACK", 			"Retour")

	# Game
	fr_translation.add_message("SCORE",			"Score")
	fr_translation.add_message("HIGH_SCORE",	"Meilleur Score")
	fr_translation.add_message("MOVES",			"Mouvements")
	fr_translation.add_message("GAME_OVER",		"Game Over")
	fr_translation.add_message("VICTORY",		"Victoire !")
	fr_translation.add_message("FINAL_SCORE",	"Score Final")

	# Audio
	fr_translation.add_message("MUSIC_ACTIVE",		"Désactiver la musique")
	fr_translation.add_message("MUSIC_INACTIVE",	"Activer la musique")
	fr_translation.add_message("SFX_ACTIVE",		"Désactiver les bruitages")
	fr_translation.add_message("SFX_INACTIVE",		"Activer les bruitages")

	# Language
	fr_translation.add_message("LANGUAGE",	"Langue")
	fr_translation.add_message("FRENCH",	"Français")
	fr_translation.add_message("ENGLISH",	"English")

	# Actions
	fr_translation.add_message("RESET_RANKING",	"Effacer le classement")
	fr_translation.add_message("YES",			"Oui")
	fr_translation.add_message("NO",			"Non")
	fr_translation.add_message("SUCCESS",		"OK !")
	fr_translation.add_message("NO_SCORES",		"Pas encore de scores")

	# Powers
	fr_translation.add_message("POWER_FIRE_HORIZONTAL",		"Feu Horizontal")
	fr_translation.add_message("POWER_FIRE_VERTICAL",		"Feu Vertical")
	fr_translation.add_message("POWER_FIRE_CROSS",			"Feu Croix")
	fr_translation.add_message("POWER_BOMB",				"Bombe")
	fr_translation.add_message("POWER_ICE",					"Glaçon")
	fr_translation.add_message("POWER_SWITCH_HORIZONTAL",	"Switch ↔")
	fr_translation.add_message("POWER_SWITCH_VERTICAL",		"Switch ↕")
	fr_translation.add_message("POWER_TELEPORT",			"Téléport")
	fr_translation.add_message("POWER_EXPEL_HORIZONTAL",	"Expulsion →")
	fr_translation.add_message("POWER_EXPEL_VERTICAL",		"Expulsion ↓")
	fr_translation.add_message("POWER_FREEZE_UP",			"Gel ↑")
	fr_translation.add_message("POWER_FREEZE_DOWN",			"Gel ↓")
	fr_translation.add_message("POWER_FREEZE_LEFT",			"Gel ←")
	fr_translation.add_message("POWER_FREEZE_RIGHT",		"Gel →")
	fr_translation.add_message("POWER_LIGHTNING",			"Éclair")
	fr_translation.add_message("POWER_NUCLEAR",				"Nucléaire")
	fr_translation.add_message("POWER_BLIND",				"Aveugle")
	fr_translation.add_message("POWER_BOWLING",				"Bowling")
	fr_translation.add_message("POWER_ADS",					"Publicités")

	TranslationServer.add_translation(fr_translation)

# Load language settings from file
func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err == OK:
		var saved_lang = config.get_value("language", "current", "en")
		set_language(saved_lang)
		print("✅ Language settings loaded: %s" % saved_lang)
	else:
		# No saved settings, use default
		set_language("en")
		print("ℹ️ No language settings file found, using default (en)")

# Save language settings to file
func save_settings():
	var config = ConfigFile.new()
	config.set_value("language", "current", current_language)

	var err = config.save(SETTINGS_PATH)
	if err == OK:
		print("✅ Language settings saved: %s" % current_language)
	else:
		print("❌ Failed to save language settings: error %d" % err)

func set_language(lang):
	if lang in available_languages:
		current_language = lang
		TranslationServer.set_locale(lang)
		language_changed.emit()
		save_settings()  # Save after changing language
	else:
		print("❌ ERROR: Unsupported language '", lang, "'. Available languages: ", available_languages)

func get_current_language():
	return current_language

func toggle_language(lang: String):
	if lang in available_languages:
		set_language(lang)
