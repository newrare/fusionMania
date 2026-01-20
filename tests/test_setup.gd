# Test Scene for verifying project setup
extends Node

func _ready():
	print("\n=== Fusion Mania Configuration Test ===\n")
	
	# Test AutoLoads
	test_autoloads()
	
	# Test Display Settings
	test_display()
	
	# Test Input Configuration
	test_input()
	
	print("\n=== Test Complete ===\n")


func test_autoloads():
	print("📦 Testing AutoLoads:")
	
	var managers = [
		{"name": "AudioManager", "ref": AudioManager},
		{"name": "LanguageManager", "ref": LanguageManager},
		{"name": "ScoreManager", "ref": ScoreManager},
		{"name": "GameManager", "ref": GameManager},
		{"name": "GridManager", "ref": GridManager},
		{"name": "PowerManager", "ref": PowerManager},
		{"name": "SaveManager", "ref": SaveManager},
		{"name": "ToolsManager", "ref": ToolsManager}
	]
	
	for manager in managers:
		var status = "✅" if manager.ref != null else "❌"
		print("  %s %s" % [status, manager.name])


func test_display():
	print("\n🖥️ Testing Display Settings:")
	
	var viewport_size	= get_viewport().size
	var window_size		= DisplayServer.window_get_size()
	
	print("  Viewport size: %s" % viewport_size)
	print("  Window size: %s" % window_size)
	print("  Stretch mode: %s" % ProjectSettings.get_setting("display/window/stretch/mode"))
	print("  Orientation: %s" % ProjectSettings.get_setting("display/window/handheld/orientation"))


func test_input():
	print("\n🎮 Testing Input Configuration:")
	
	var actions = ["move_up", "move_down", "move_left", "move_right", "pause"]
	
	for action in actions:
		var has_action = InputMap.has_action(action)
		var status = "✅" if has_action else "❌"
		print("  %s %s" % [status, action])
	
	# Test touch settings
	var touch_from_mouse = ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse")
	var mouse_from_touch = ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")
	
	print("\n📱 Touch Settings:")
	print("  Emulate touch from mouse: %s" % touch_from_mouse)
	print("  Emulate mouse from touch: %s" % mouse_from_touch)


func test_platform():
	print("\n🌍 Platform Detection:")
	print("  OS: %s" % OS.get_name())
	print("  Is Mobile: %s" % ToolsManager.get_is_mobile())
