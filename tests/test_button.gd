# Test script for UIButton widget
extends Node2D

var test_button: Button

func _ready():
	print("\n=== UIButton Widget Tests ===\n")

	# Create test button
	test_button = preload("res://widgets/UIButton.tscn").instantiate()
	test_button.text = "Test Button"
	test_button.position = Vector2(400, 300)
	add_child(test_button)

	# Connect signal to verify it works
	test_button.button_clicked.connect(_on_test_button_clicked)

	await get_tree().create_timer(0.1).timeout

	test_platform_detection()
	await get_tree().create_timer(0.5).timeout

	test_click_animation()
	await get_tree().create_timer(1.0).timeout

	test_signal_emission()
	await get_tree().create_timer(0.5).timeout

	test_programmatic_click()
	await get_tree().create_timer(0.5).timeout

	print("\n=== All UIButton Tests Complete ===\n")
	print("Visual test: Check if button appeared on screen")
	print("Audio test: Listen for click sounds")
	print("Hover test (PC only): Move mouse over button to test hover sound/animation")

	# Quick exit for automated testing
	get_tree().quit()


# Test 1: Platform detection
func test_platform_detection():
	print("Test 1: Platform Detection")

	var is_mobile = ToolsManager.get_is_mobile()
	print("  Platform: %s" % ["Mobile" if is_mobile else "Desktop"])

	if is_mobile:
		print("  ✅ Mobile mode: Hover disabled, click only")
	else:
		print("  ✅ Desktop mode: Hover + Click enabled")

	# Check signal connections
	var hover_connected = test_button.mouse_entered.is_connected(test_button._on_hover_start)
	if is_mobile:
		if not hover_connected:
			print("  ✅ Hover signals NOT connected (correct for mobile)")
		else:
			print("  ❌ Hover signals connected on mobile (should not be)")
	else:
		if hover_connected:
			print("  ✅ Hover signals connected (correct for desktop)")
		else:
			print("  ❌ Hover signals NOT connected on desktop (should be)")


# Test 2: Click animation
func test_click_animation():
	print("\nTest 2: Click Animation")

	var initial_scale = test_button.scale
	print("  Initial scale: (%.2f, %.2f)" % [initial_scale.x, initial_scale.y])

	# Simulate click
	test_button._on_clicked()

	# Wait a frame to see if animation started
	await get_tree().create_timer(0.01).timeout
	var mid_scale = test_button.scale
	print("  Mid-click scale: (%.2f, %.2f)" % [mid_scale.x, mid_scale.y])

	# Wait for animation to complete
	await get_tree().create_timer(0.15).timeout
	var final_scale = test_button.scale
	print("  Final scale: (%.2f, %.2f)" % [final_scale.x, final_scale.y])

	if final_scale.is_equal_approx(Vector2.ONE):
		print("  ✅ Click animation completed, returned to normal scale")
	else:
		print("  ⚠️ Final scale not exactly 1.0 (may still be animating)")


# Test 3: Signal emission
var signal_received = false

func test_signal_emission():
	print("\nTest 3: Signal Emission")

	signal_received = false
	test_button._on_clicked()

	await get_tree().create_timer(0.1).timeout

	if signal_received:
		print("  ✅ button_clicked signal emitted successfully")
	else:
		print("  ❌ button_clicked signal NOT received")


func _on_test_button_clicked():
	signal_received = true
	print("  [Signal received: button_clicked]")


# Test 4: Programmatic click
func test_programmatic_click():
	print("\nTest 4: Programmatic Click")

	signal_received = false
	test_button.trigger_click()

	await get_tree().create_timer(0.1).timeout

	if signal_received:
		print("  ✅ trigger_click() works correctly")
	else:
		print("  ❌ trigger_click() did not emit signal")
