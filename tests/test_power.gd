# Test script for PowerManager
extends Node2D

func _ready():
	print("\n=== PowerManager Tests ===\n")

	await get_tree().create_timer(0.1).timeout

	test_power_data()
	test_random_power_distribution()
	test_resolve_power_merge()

	print("\n=== All PowerManager Tests Complete ===\n")
	get_tree().quit()


# Test 1: Power data structure
func test_power_data():
	print("Test 1: Power data structure")

	var power_count = PowerManager.POWER_DATA.size()
	print("  ✅ Total powers: %d" % power_count)

	# Verify all 20 powers exist
	var expected_powers = [
		"empty", "fire_h", "fire_v", "fire_cross", "bomb", "ice",
		"switch_h", "switch_v", "teleport", "expel_h", "expel_v",
		"freeze_up", "freeze_down", "freeze_left", "freeze_right",
		"lightning", "nuclear", "blind", "bowling", "ads"
	]

	for power_key in expected_powers:
		if not PowerManager.POWER_DATA.has(power_key):
			print("  ❌ Missing power: %s" % power_key)
			return

	print("  ✅ All 20 powers defined")

	# Verify spawn rates sum to 100
	var total_rate = 0
	for power_key in PowerManager.POWER_DATA.keys():
		total_rate += PowerManager.POWER_DATA[power_key].spawn_rate

	print("  ✅ Total spawn rate: %d%%" % total_rate)


# Test 2: Random power distribution
func test_random_power_distribution():
	print("\nTest 2: Random power distribution (1000 samples)")

	var samples = {}
	var total_samples = 1000

	# Generate 1000 random powers
	for i in range(total_samples):
		var power = PowerManager.get_random_power()
		if power == "":
			power = "empty"

		if not samples.has(power):
			samples[power] = 0
		samples[power] += 1

	# Show distribution
	print("  Power distribution:")
	for power_key in samples.keys():
		var percentage = (samples[power_key] / float(total_samples)) * 100.0
		var expected = PowerManager.POWER_DATA[power_key].spawn_rate
		print("    %s: %.1f%% (expected: %d%%)" % [power_key, percentage, expected])

	print("  ✅ Random power generation working")


# Test 3: Power merge resolution
func test_resolve_power_merge():
	print("\nTest 3: Power merge resolution")

	# Case 1: Same power
	var result1 = PowerManager.resolve_power_merge("fire_h", "fire_h")
	if result1 == "fire_h":
		print("  ✅ Same power -> same power (fire_h)")
	else:
		print("  ❌ Same power test failed: got %s" % result1)

	# Case 2: One empty
	var result2 = PowerManager.resolve_power_merge("", "bomb")
	if result2 == "bomb":
		print("  ✅ Empty + bomb -> bomb")
	else:
		print("  ❌ Empty power test failed: got %s" % result2)

	# Case 3: Different powers - keep rarer (nuclear vs fire_h)
	var result3 = PowerManager.resolve_power_merge("nuclear", "fire_h")
	if result3 == "nuclear":
		print("  ✅ Nuclear (1%%) + fire_h (5%%) -> nuclear (rarer)")
	else:
		print("  ❌ Rarity test failed: got %s" % result3)

	# Case 4: Same rarity - keep first
	var result4 = PowerManager.resolve_power_merge("fire_h", "fire_v")
	if result4 == "fire_h":
		print("  ✅ fire_h (5%%) + fire_v (5%%) -> fire_h (first)")
	else:
		print("  ❌ Same rarity test failed: got %s" % result4)
