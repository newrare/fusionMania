# PowerEffect - Visual effects for power activations
# Handles all visual feedback for powers
extends Node

# Preload textures to avoid loading delays
const ICE_OVERLAY_TEXTURE = preload("res://assets/images/ice_overlay.png")

# Fire line sequence (new version with particles and blinking)
static func fire_line_sequence(emitter_tile, target_tiles: Array, is_horizontal: bool, grid_manager):
	print("  🔥 Fire line sequence: %s, %d targets" % ["horizontal" if is_horizontal else "vertical", target_tiles.size()])

	if emitter_tile == null:
		return

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	# Start blinking target tiles (1 second total)
	for target in target_tiles:
		_blink_tile(target, 1.0)

	# Phase 1: Fire ray effect (0.5 second)
	_create_fire_ray(grid_node, emitter_tile, is_horizontal)

	# Phase 2: Particle explosions after 0.5 second
	await grid_node.get_tree().create_timer(0.5).timeout
	for target in target_tiles:
		_create_explosion_particles(grid_node, target)

	# Phase 3: Destroy tiles after 1 second total
	await grid_node.get_tree().create_timer(0.5).timeout
	for target in target_tiles:
		if is_instance_valid(target):
			grid_manager.destroy_tile(target)


# Fire cross sequence (horizontal + vertical)
static func fire_cross_sequence(emitter_tile, target_tiles: Array, grid_manager):
	print("  🔥 Fire cross sequence: %d targets" % target_tiles.size())

	if emitter_tile == null:
		return

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	# Start blinking target tiles (1 second total)
	for target in target_tiles:
		_blink_tile(target, 1.0)

	# Phase 1: Fire rays (both horizontal and vertical) (0.5 second)
	var emitter_pos = emitter_tile.grid_position
	_create_fire_ray(grid_node, emitter_tile, true)   # horizontal
	_create_fire_ray(grid_node, emitter_tile, false)  # vertical

	# Phase 2: Particle explosions after 0.5 second
	await grid_node.get_tree().create_timer(0.5).timeout
	for target in target_tiles:
		_create_explosion_particles(grid_node, target)

	# Phase 3: Destroy tiles after 1 second total
	await grid_node.get_tree().create_timer(0.5).timeout
	for target in target_tiles:
		if is_instance_valid(target):
			grid_manager.destroy_tile(target)


# Create fire ray on entire line/column except emitter cell
static func _create_fire_ray(grid_node: Node, emitter_tile, is_horizontal: bool):
	if emitter_tile == null:
		return

	const TILE_SIZE = 240
	const TILE_SPACING = 20
	const CELL_SIZE = TILE_SIZE + TILE_SPACING
	const RAY_THICKNESS = 40
	const GRID_SIZE = 4

	var emitter_pos = emitter_tile.grid_position

	if is_horizontal:
		# Horizontal ray - two parts: left and right of emitter
		var center_y = emitter_pos.y * CELL_SIZE + TILE_SIZE / 2

		# Left part (from 0 to emitter cell)
		if emitter_pos.x > 0:
			var ray_left = ColorRect.new()
			ray_left.color = Color(1, 0.3, 0, 0.9)  # Orange fire
			ray_left.size = Vector2(emitter_pos.x * CELL_SIZE, RAY_THICKNESS)
			ray_left.position = Vector2(0, center_y - RAY_THICKNESS / 2.0)
			grid_node.add_child(ray_left)

			var tween_left = grid_node.create_tween()
			tween_left.tween_property(ray_left, "modulate:a", 0.0, 0.5)
			tween_left.tween_callback(ray_left.queue_free)

		# Right part (from emitter cell + 1 to end)
		if emitter_pos.x < GRID_SIZE - 1:
			var start_x = (emitter_pos.x + 1) * CELL_SIZE
			var end_x = GRID_SIZE * CELL_SIZE - TILE_SPACING
			var ray_right = ColorRect.new()
			ray_right.color = Color(1, 0.3, 0, 0.9)  # Orange fire
			ray_right.size = Vector2(end_x - start_x, RAY_THICKNESS)
			ray_right.position = Vector2(start_x, center_y - RAY_THICKNESS / 2.0)
			grid_node.add_child(ray_right)

			var tween_right = grid_node.create_tween()
			tween_right.tween_property(ray_right, "modulate:a", 0.0, 0.5)
			tween_right.tween_callback(ray_right.queue_free)
	else:
		# Vertical ray - two parts: top and bottom of emitter
		var center_x = emitter_pos.x * CELL_SIZE + TILE_SIZE / 2

		# Top part (from 0 to emitter cell)
		if emitter_pos.y > 0:
			var ray_top = ColorRect.new()
			ray_top.color = Color(1, 0.3, 0, 0.9)  # Orange fire
			ray_top.size = Vector2(RAY_THICKNESS, emitter_pos.y * CELL_SIZE)
			ray_top.position = Vector2(center_x - RAY_THICKNESS / 2.0, 0)
			grid_node.add_child(ray_top)

			var tween_top = grid_node.create_tween()
			tween_top.tween_property(ray_top, "modulate:a", 0.0, 0.5)
			tween_top.tween_callback(ray_top.queue_free)

		# Bottom part (from emitter cell + 1 to end)
		if emitter_pos.y < GRID_SIZE - 1:
			var start_y = (emitter_pos.y + 1) * CELL_SIZE
			var end_y = GRID_SIZE * CELL_SIZE - TILE_SPACING
			var ray_bottom = ColorRect.new()
			ray_bottom.color = Color(1, 0.3, 0, 0.9)  # Orange fire
			ray_bottom.size = Vector2(RAY_THICKNESS, end_y - start_y)
			ray_bottom.position = Vector2(center_x - RAY_THICKNESS / 2.0, start_y)
			grid_node.add_child(ray_bottom)

			var tween_bottom = grid_node.create_tween()
			tween_bottom.tween_property(ray_bottom, "modulate:a", 0.0, 0.5)
			tween_bottom.tween_callback(ray_bottom.queue_free)


# Create explosion particles (red) - 32 small particles
static func _create_explosion_particles(grid_node: Node, tile):
	if not is_instance_valid(tile):
		return

	const TILE_SIZE = 240
	const TILE_SPACING = 20
	const CELL_SIZE = TILE_SIZE + TILE_SPACING

	# Get tile center position
	var tile_center = Vector2(
		tile.grid_position.x * CELL_SIZE + TILE_SIZE / 2,
		tile.grid_position.y * CELL_SIZE + TILE_SIZE / 2
	)

	# Create 32 small particles
	for i in range(32):
		var particle = ColorRect.new()
		particle.color = Color(1, 0, 0, 0.8)  # Red
		var size = randf_range(5, 10)  # 4x smaller
		particle.size = Vector2(size, size)
		particle.pivot_offset = Vector2(size / 2, size / 2)

		# Random offset from center
		var angle = randf() * TAU
		var distance = randf_range(0, 30)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		particle.position = tile_center + offset - Vector2(size / 2, size / 2)

		grid_node.add_child(particle)

		# Animate: move outward far (can go beyond grid), scale down, fade out
		var tween = grid_node.create_tween()
		var end_distance = randf_range(150, 300)  # Much farther
		var end_offset = Vector2(cos(angle), sin(angle)) * end_distance
		tween.tween_property(particle, "position", tile_center + end_offset - Vector2(size / 2, size / 2), 0.5)
		tween.parallel().tween_property(particle, "scale", Vector2(0.1, 0.1), 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)


# Make tile blink for duration
static func _blink_tile(tile, duration: float):
	if not is_instance_valid(tile):
		return

	var original_modulate = tile.modulate
	var blink_count = int(duration / 0.2)  # Blink every 0.2s

	var tween = tile.create_tween()
	for i in range(blink_count):
		tween.tween_property(tile, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		tween.tween_property(tile, "modulate", original_modulate, 0.1)
	tween.tween_property(tile, "modulate", original_modulate, 0.0)  # Ensure it ends at original


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

	# Get viewport root
	var viewport_root = tile.get_tree().root

	# Create ice overlay covering entire viewport
	var ice_overlay = TextureRect.new()

	if ICE_OVERLAY_TEXTURE != null:
		ice_overlay.texture = ICE_OVERLAY_TEXTURE
		ice_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ice_overlay.stretch_mode = TextureRect.STRETCH_SCALE

		# Cover entire viewport
		var viewport_size = viewport_root.get_viewport().get_visible_rect().size
		ice_overlay.size = viewport_size
		ice_overlay.position = Vector2.ZERO
		ice_overlay.modulate = Color(1, 1, 1, 0.1)  # Start directly at 30% opacity

		viewport_root.add_child(ice_overlay)

		# Animation: hold for 2 seconds, then fade out
		var tween = viewport_root.create_tween()
		# Hold for 2 seconds
		tween.tween_interval(2.0)
		# Fade out over 1 second
		tween.tween_property(ice_overlay, "modulate:a", 0.0, 1.0)
		# Remove after animation
		tween.tween_callback(ice_overlay.queue_free)
	else:
		print("  ⚠️ Ice overlay texture not found")


# Lightning strike effect with animated lightning bolt
static func lightning_strike_effect(tile):
	print("  ⚡ Lightning strike on tile")

	if tile == null:
		return

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	const TILE_SIZE = 240
	const TILE_SPACING = 20
	const CELL_SIZE = TILE_SIZE + TILE_SPACING
	const ANIMATION_DURATION = 0.3
	const FRAME_COUNT = 5

	# Calculate tile center position (relative to grid)
	var tile_center_x = tile.grid_position.x * CELL_SIZE + TILE_SIZE / 2
	var tile_center_y = tile.grid_position.y * CELL_SIZE + TILE_SIZE / 2

	# Get viewport root to place lightning from true top of screen
	var viewport_root = grid_node.get_tree().root

	# Get tile absolute position in viewport coordinates
	var tile_global_pos = grid_node.global_position + Vector2(tile_center_x, tile_center_y)

	# Start blinking the target tile for 0.5 second
	_blink_tile(tile, ANIMATION_DURATION)

	# Create lightning bolt sprite
	var lightning = TextureRect.new()
	lightning.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lightning.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	# Load first frame
	var texture = load("res://assets/images/lightning_1.png")
	if texture == null:
		print("  ⚠️ Lightning texture not found")
		return

	lightning.texture = texture

	# Calculate size and position
	# The lightning should stretch from top of viewport (y=0) to tile center
	var lightning_height = tile_global_pos.y
	var aspect_ratio = float(texture.get_width()) / float(texture.get_height())
	var lightning_width = lightning_height * aspect_ratio

	lightning.size = Vector2(lightning_width, lightning_height)
	lightning.position = Vector2(tile_global_pos.x - lightning_width / 2, 0)

	viewport_root.add_child(lightning)

	# Animate through frames 1-5 over 0.5 seconds
	var frame_duration = ANIMATION_DURATION / FRAME_COUNT

	for i in range(FRAME_COUNT):
		var frame_number = i + 1
		var frame_texture = load("res://assets/images/lightning_%d.png" % frame_number)

		if frame_texture != null:
			lightning.texture = frame_texture

			# Recalculate size for new texture
			aspect_ratio = float(frame_texture.get_width()) / float(frame_texture.get_height())
			lightning_width = lightning_height * aspect_ratio
			lightning.size = Vector2(lightning_width, lightning_height)
			lightning.position = Vector2(tile_global_pos.x - lightning_width / 2, 0)

		await viewport_root.get_tree().create_timer(frame_duration).timeout

	# Remove lightning after animation
	lightning.queue_free()


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
	var blind 		= ColorRect.new()
	blind.color    	= Color(0, 0, 0, 0.95)
	blind.size     	= grid_node.size
	blind.position 	= Vector2.ZERO
	blind.name     	= "BlindOverlay"

	grid_node.add_child(blind)

	# Note: Actual removal will be handled by GridManager.update_blind_mode()

