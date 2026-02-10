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
func get_is_mobile():
	return is_mobile

