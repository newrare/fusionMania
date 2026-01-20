# PowerEffect - Visual effects for power activations
# Simple placeholder effects for now, will be enhanced later
extends Node

# Fire line effect (horizontal or vertical)
static func fire_line_effect(index: int, is_horizontal: bool):
	print("  [VFX] Fire line: %s at index %d" % ["horizontal" if is_horizontal else "vertical", index])
	# TODO: Add animated fire line effect


# Explosion effect at position
static func explosion_effect(position: Vector2):
	print("  [VFX] Explosion at position (%d, %d)" % [position.x, position.y])
	# TODO: Add explosion particles


# Freeze effect on tile
static func freeze_effect(tile):
	print("  [VFX] Freeze effect on tile")
	# TODO: Add blue icy overlay


# Lightning strike effect
static func lightning_strike_effect(tile):
	print("  [VFX] Lightning strike on tile")
	# TODO: Add lightning animation


# Nuclear flash effect
static func nuclear_flash():
	print("  [VFX] Nuclear flash")
	# TODO: Add white flash across entire grid


# Blind overlay effect
static func blind_overlay(duration: float):
	print("  [VFX] Blind overlay for %.1f seconds" % duration)
	# TODO: Add black overlay hiding grid
