# Test script for TitleMenu overlay
extends Node2D

var title_menu: CanvasLayer
var signal_received: String = ""

func _ready():
	print("\n=== TitleMenu Overlay Tests ===\n")

	# Instantiate title menu
	title_menu = preload("res://overlays/TitleMenu.tscn").instantiate()
	add_child(title_menu)

	# Connect signals
	title_menu.new_game_pressed.connect(_on_signal_received.bind("new_game"))
	title_menu.resume_pressed.connect(_on_signal_received.bind("resume"))
	title_menu.ranking_pressed.connect(_on_signal_received.bind("ranking"))
	title_menu.options_pressed.connect(_on_signal_received.bind("options"))
	title_menu.quit_pressed.connect(_on_signal_received.bind("quit"))

	# Give nodes time to initialize
	await get_tree().process_frame
	await get_tree().process_frame

	test_initial_state()
	await test_show_hide()
	await test_button_signals()
	test_translations()
	test_resume_button_visibility()

	print("\n=== All TitleMenu Tests Complete ===\n")
	get_tree().quit()


# Test 1: Initial state
func test_initial_state():
	print("Test 1: Initial State")

	if not title_menu.visible:
		print("  ✅ Menu initially hidden")
	else:
		print("  ❌ Menu should be hidden initially")

	# Check nodes exist
	if title_menu.has_node("OverlayBackground"):
		print("  ✅ Overlay background exists")
	else:
		print("  ❌ Overlay background missing")

	if title_menu.has_node("MenuContainer"):
		print("  ✅ Menu container exists")
	else:
		print("  ❌ Menu container missing")

	# Check buttons exist
	var buttons = ["BtnNewGame", "BtnResume", "BtnRanking", "BtnOptions", "BtnQuit"]
	var all_buttons_exist = true
	for btn_name in buttons:
		if not title_menu.has_node("MenuContainer/ButtonsContainer/" + btn_name):
			all_buttons_exist = false
			break

	if all_buttons_exist:
		print("  ✅ All 5 buttons exist")
	else:
		print("  ❌ Some buttons missing")


# Test 2: Show/Hide functionality
func test_show_hide():
	print("\nTest 2: Show/Hide Functionality")

	# Show menu
	title_menu.show_menu()
	await get_tree().process_frame

	if title_menu.visible:
		print("  ✅ Menu shown successfully")
	else:
		print("  ❌ Menu not visible after show_menu()")

	# Hide menu
	title_menu.hide_menu()
	await get_tree().process_frame

	if not title_menu.visible:
		print("  ✅ Menu hidden successfully")
	else:
		print("  ❌ Menu still visible after hide_menu()")


# Test 3: Button signals
func test_button_signals():
	print("\nTest 3: Button Signals")

	title_menu.show_menu()
	await get_tree().process_frame

	# Test each button signal
	var buttons_to_test = [
		{"node": "BtnNewGame", "expected": "new_game"},
		{"node": "BtnRanking", "expected": "ranking"},
		{"node": "BtnOptions", "expected": "options"},
		{"node": "BtnQuit", "expected": "quit"}
	]

	for btn_test in buttons_to_test:
		signal_received = ""
		var btn = title_menu.get_node("MenuContainer/ButtonsContainer/" + btn_test.node)
		btn._on_clicked()
		await get_tree().process_frame

		if signal_received == btn_test.expected:
			print("  ✅ %s signal emitted correctly" % btn_test.expected)
		else:
			print("  ❌ %s signal failed (got: %s)" % [btn_test.expected, signal_received])

	title_menu.hide_menu()


# Test 4: Translations
func test_translations():
	print("\nTest 4: Translations")

	title_menu.show_menu()
	await get_tree().process_frame

	# Get current language
	var current_lang = LanguageManager.get_current_language()
	print("  Current language: %s" % current_lang)

	# Check logo text
	var logo = title_menu.get_node("MenuContainer/Logo")
	if logo.text != "":
		print("  ✅ Logo text set: %s" % logo.text)
	else:
		print("  ❌ Logo text empty")

	# Check button texts
	var btn_new_game = title_menu.get_node("MenuContainer/ButtonsContainer/BtnNewGame")
	if btn_new_game.text != "":
		print("  ✅ Button texts updated")
	else:
		print("  ⚠️ Button texts may not be translated")

	title_menu.hide_menu()


# Test 5: Resume button visibility
func test_resume_button_visibility():
	print("\nTest 5: Resume Button Visibility")

	title_menu.show()
	await get_tree().create_timer(0.1).timeout

	var btn_resume = title_menu.get_node("MenuContainer/ButtonsContainer/BtnResume")
	var has_save = SaveManager.has_save()

	print("  Save file exists: %s" % has_save)
	print("  Resume button visible: %s" % btn_resume.visible)

	if btn_resume.visible == has_save:
		print("  ✅ Resume button visibility correct")
	else:
		print("  ❌ Resume button visibility incorrect")

	title_menu.hide()


# Signal receiver
func _on_signal_received(signal_name: String):
	signal_received = signal_name
	print("  [Signal received: %s_pressed]" % signal_name)
