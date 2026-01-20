# PowerEffect - Visual effects for power activations
# Handles all visual feedback for powers
extends Node

# Fire line effect (horizontal or vertical)
static func fire_line_effect(index: int, is_horizontal: bool):
	print("  🔥 Fire line: %s at index %d" % ["horizontal" if is_horizontal else "vertical", index])
	
	# Get grid node for visual effects
	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return
	
	# Create fire line visual
	var line = ColorRect.new()
	line.color = Color(1, 0.3, 0, 0.8)  # Orange fire color
	
	if is_horizontal:
		line.size     = Vector2(grid_node.size.x, 50)
		line.position = Vector2(0, index * 260 + 20)
	else:
		line.size     = Vector2(50, grid_node.size.y)
		line.position = Vector2(index * 260 + 20, 0)
	
	grid_node.add_child(line)
	
	# Fade out animation
	var tween = grid_node.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.tween_callback(line.queue_free)


# Explosion effect at position
static func explosion_effect(position: Vector2):
	print("  💥 Explosion at position (%d, %d)" % [int(position.x), int(position.y)])
	
	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return
	
	# Create explosion circle
	var explosion = ColorRect.new()
	explosion.color    = Color(1, 0.5, 0, 0.9)
	explosion.size     = Vector2(100, 100)
	explosion.position = position - Vector2(50, 50)
	explosion.pivot_offset = Vector2(50, 50)
	grid_node.add_child(explosion)
	
	# Scale up then fade
	var tween = grid_node.create_tween()
	tween.tween_property(explosion, "scale", Vector2(2, 2), 0.2)
	tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)


# Freeze effect on tile
static func freeze_effect(tile):
	print("  ❄️ Freeze effect on tile")
	
	if tile == null:
		return
	
	# Add blue tint to tile
	var original_modulate = tile.modulate
	tile.modulate = Color(0.5, 0.7, 1.0, 1.0)
	
	# Create ice overlay
	var ice = ColorRect.new()
	ice.color    = Color(0.6, 0.8, 1.0, 0.5)
	ice.size     = Vector2(240, 240)
	ice.position = Vector2.ZERO
	tile.add_child(ice)


# Lightning strike effect
static func lightning_strike_effect(tile):
	print("  ⚡ Lightning strike on tile")
	
	if tile == null:
		return
	
	# Flash white
	var original_modulate = tile.modulate
	tile.modulate = Color(1, 1, 0.5, 1)
	
	# Create flash
	var tween = tile.create_tween()
	tween.tween_property(tile, "modulate", Color(1, 1, 1, 1), 0.1)
	tween.tween_property(tile, "modulate", original_modulate, 0.1)


# Nuclear flash effect
static func nuclear_flash():
	print("  ☢️ Nuclear flash")
	
	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return
	
	# Create white flash overlay
	var flash = ColorRect.new()
	flash.color    = Color(1, 1, 1, 0.9)
	flash.size     = grid_node.size
	flash.position = Vector2.ZERO
	grid_node.add_child(flash)
	
	# Fade out
	var tween = grid_node.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)


# Blind overlay effect
static func blind_overlay(duration: float):
	print("  🔳 Blind overlay for %.1f seconds" % duration)
	
	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return
	
	# Create black overlay
	var blind = ColorRect.new()
	blind.color    = Color(0, 0, 0, 0.95)
	blind.size     = grid_node.size
	blind.position = Vector2.ZERO
	blind.name     = "BlindOverlay"
	grid_node.add_child(blind)
	
	# Note: Actual removal will be handled by GridManager.update_blind_mode()

