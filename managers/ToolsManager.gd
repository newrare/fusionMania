# ToolsManager for Fusion Mania
# Utility functions and platform detection
extends Node

var is_mobile: bool = false

func _ready():
	detect_platform()
	print("🔧 ToolsManager ready")


# Detect the current platform
func detect_platform():
	var os_name = OS.get_name()
	is_mobile = os_name in ["Android", "iOS"]
	
	print("Platform detected: %s (Mobile: %s)" % [os_name, is_mobile])


# Get if running on mobile
func get_is_mobile() -> bool:
	return is_mobile


# Format number with separators (e.g., 1000000 -> 1,000,000)
func format_number(number: int) -> String:
	var text		= str(number)
	var formatted	= ""
	var count		= 0
	
	# Read from right to left
	for i in range(text.length() - 1, -1, -1):
		if count == 3:
			formatted	= "," + formatted
			count		= 0
		formatted	= text[i] + formatted
		count		+= 1
	
	return formatted


# Format time (seconds to MM:SS)
func format_time(seconds: int) -> String:
	var minutes	= seconds / 60
	var secs	= seconds % 60
	return "%02d:%02d" % [minutes, secs]


# Clamp value between min and max
func clamp_value(value: float, min_val: float, max_val: float) -> float:
	return clampf(value, min_val, max_val)


# Linear interpolation
func lerp_value(from: float, to: float, weight: float) -> float:
	return lerpf(from, to, weight)


# Get a random element from an array
func get_random_element(array: Array):
	if array.is_empty():
		return null
	return array[randi() % array.size()]


# Shuffle an array
func shuffle_array(array: Array) -> Array:
	var shuffled = array.duplicate()
	shuffled.shuffle()
	return shuffled
