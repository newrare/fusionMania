# PowerEffect - Visual effects for power activations
# Handles all visual feedback for powers
extends Node

# Preload textures to avoid loading delays
const ICE_OVERLAY_TEXTURE = preload("res://assets/images/ice_overlay.png")

# Fire line sequence (new version with fireball sprites)
static func fire_line_sequence(emitter_tile, target_tiles: Array, is_horizontal: bool, grid_manager):
	print("  🔥 Fire line sequence: %s, %d targets" % ["horizontal" if is_horizontal else "vertical", target_tiles.size()])

	if emitter_tile == null:
		return

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	# Highlight emitter tile (icon blink + blue text for 1 second)
	highlight_emitter_tile(emitter_tile, 1.0)

	# Start blinking target tiles (1 second total)
	for target in target_tiles:
		_blink_tile(target, 1.0)

	# Launch fireballs in both directions
	if is_horizontal:
		_create_fireball(grid_node, emitter_tile, Vector2.RIGHT)  # Right
		_create_fireball(grid_node, emitter_tile, Vector2.LEFT)   # Left
	else:
		_create_fireball(grid_node, emitter_tile, Vector2.DOWN)   # Down
		_create_fireball(grid_node, emitter_tile, Vector2.UP)     # Up

	# Destroy tiles after 1 second
	await grid_node.get_tree().create_timer(1.0).timeout
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

	# Highlight emitter tile (icon blink + blue text for 1 second)
	highlight_emitter_tile(emitter_tile, 1.0)

	# Start blinking target tiles (1 second total)
	for target in target_tiles:
		_blink_tile(target, 1.0)

	# Launch fireballs in all 4 directions
	_create_fireball(grid_node, emitter_tile, Vector2.RIGHT)  # Right
	_create_fireball(grid_node, emitter_tile, Vector2.LEFT)   # Left
	_create_fireball(grid_node, emitter_tile, Vector2.DOWN)   # Down
	_create_fireball(grid_node, emitter_tile, Vector2.UP)     # Up

	# Destroy tiles after 1 second
	await grid_node.get_tree().create_timer(1.0).timeout
	for target in target_tiles:
		if is_instance_valid(target):
			grid_manager.destroy_tile(target)


# Create animated fireball sprite moving in a direction
static func _create_fireball(grid_node: Node, emitter_tile, direction: Vector2):
	if emitter_tile == null:
		return

	const TILE_SIZE = 240
	const TILE_SPACING = 20
	const CELL_SIZE = TILE_SIZE + TILE_SPACING
	const FIREBALL_SIZE = 120  # Size of fireball sprite
	const FIREBALL_SPEED = 800  # Pixels per second

	# Calculate center of emitter tile
	var emitter_pos = emitter_tile.grid_position
	var center_pos = Vector2(
		emitter_pos.x * CELL_SIZE + TILE_SIZE / 2.0,
		emitter_pos.y * CELL_SIZE + TILE_SIZE / 2.0
	)

	# Calculate starting position (at edge of tile based on direction)
	var start_pos = center_pos
	var rotation_degrees = 0.0

	if direction == Vector2.RIGHT:
		start_pos.x += TILE_SIZE / 2.0  # Right edge
		rotation_degrees = 180.0
	elif direction == Vector2.LEFT:
		start_pos.x -= TILE_SIZE / 2.0  # Left edge
		rotation_degrees = 0.0
	elif direction == Vector2.UP:
		start_pos.y -= TILE_SIZE / 2.0  # Top edge
		rotation_degrees = 90.0
	elif direction == Vector2.DOWN:
		start_pos.y += TILE_SIZE / 2.0  # Bottom edge
		rotation_degrees = 270.0

	# Calculate end position (far outside the scene)
	var scene_size = 4 * CELL_SIZE  # Grid is 4x4
	var travel_distance = scene_size * 2  # Go twice the grid size to ensure it's off-screen
	var end_pos = start_pos + direction * travel_distance

	# Create animated sprite
	var fireball = AnimatedSprite2D.new()
	fireball.position = start_pos
	fireball.rotation_degrees = rotation_degrees

	# Create sprite frames
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("burn")

	# Load all 8 fire frames
	for i in range(1, 9):
		var texture = load("res://assets/images/fire_%d.png" % i)
		sprite_frames.add_frame("burn", texture)

	sprite_frames.set_animation_speed("burn", 12.0)  # 12 FPS animation
	sprite_frames.set_animation_loop("burn", true)

	fireball.sprite_frames = sprite_frames
	fireball.animation = "burn"
	fireball.scale = Vector2(FIREBALL_SIZE / 512.0, FIREBALL_SIZE / 512.0)  # Assuming original is 512x512
	fireball.centered = true

	grid_node.add_child(fireball)
	fireball.play("burn")

	# Animate movement
	var duration = travel_distance / FIREBALL_SPEED
	var tween = grid_node.create_tween()
	tween.tween_property(fireball, "position", end_pos, duration)
	tween.tween_callback(fireball.queue_free)


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


# Highlight emitter tile (blink icon + change value color to blue)
static func highlight_emitter_tile(emitter_tile, duration: float):
	if not is_instance_valid(emitter_tile):
		return

	# Blink power icon by scaling it (if it exists)
	if emitter_tile.power_icon != null and emitter_tile.power_icon.visible:
		var original_scale = emitter_tile.power_icon.scale
		var blink_count = int(duration / 0.2)

		var icon_tween = emitter_tile.power_icon.create_tween()
		for i in range(blink_count):
			icon_tween.tween_property(emitter_tile.power_icon, "scale", original_scale * 1.3, 0.1)
			icon_tween.tween_property(emitter_tile.power_icon, "scale", original_scale, 0.1)
		icon_tween.tween_property(emitter_tile.power_icon, "scale", original_scale, 0.0)

	# Change value label color to blue during animation
	if emitter_tile.value_label != null:
		var original_label_color = emitter_tile.value_label.modulate
		var label_tween = emitter_tile.value_label.create_tween()

		# Change to blue
		label_tween.tween_property(emitter_tile.value_label, "modulate", Color(0.3, 0.5, 1, 1), 0.1)
		# Hold blue color for duration
		label_tween.tween_interval(duration - 0.2)
		# Return to original color
		label_tween.tween_property(emitter_tile.value_label, "modulate", original_label_color, 0.1)


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


# Ice effect on tile
static func ice_effect(tile):
	print("  ❄️ Ice effect on tile")

	if tile == null:
		return

	# Highlight emitter tile (icon blink + blue text for 3 seconds)
	highlight_emitter_tile(tile, 3.0)

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

	# Highlight emitter tile (icon blink + blue text for 0.3 seconds)
	highlight_emitter_tile(tile, 0.3)

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
static func nuclear_flash(emitter_tile, target_tiles: Array = [], grid_manager = null):
	print("  ☢️ Nuclear flash")

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	# Highlight emitter tile (icon blink + blue text for 1.5 seconds)
	if emitter_tile != null:
		highlight_emitter_tile(emitter_tile, 1.5)

	# Start blinking target tiles for animation + flash duration (1s animation + 0.5s flash fade = 1.5s)
	for target in target_tiles:
		_blink_tile(target, 1.5)

	# Play nuclear animation first (1 second)
	await _play_nuclear_animation(grid_node)

	# Then create white flash overlay
	var flash = ColorRect.new()
	flash.color    = Color(1, 1, 1, 0.9)
	flash.size     = grid_node.size
	flash.position = Vector2.ZERO
	grid_node.add_child(flash)

	# Fade out flash
	var tween = grid_node.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)

	# Destroy target tiles after flash fades
	tween.tween_callback(func():
		if grid_manager != null:
			for target in target_tiles:
				if is_instance_valid(target):
					grid_manager.destroy_tile(target)
	)


# Play nuclear explosion animation (10 frames over 1 second)
static func _play_nuclear_animation(grid_node: Node):
	print("  💥 Nuclear animation sequence")

	var viewport_root = grid_node.get_tree().root

	# Create nuclear animation sprite covering entire screen
	var nuclear_sprite = TextureRect.new()
	nuclear_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nuclear_sprite.stretch_mode = TextureRect.STRETCH_SCALE

	# Get viewport size
	var viewport_size = viewport_root.get_viewport().get_visible_rect().size
	nuclear_sprite.size = viewport_size
	nuclear_sprite.position = Vector2(0, -300)  # Move up 300px

	viewport_root.add_child(nuclear_sprite)

	# Animate through frames 1-10 over 1 second
	const FRAME_COUNT = 10
	const ANIMATION_DURATION = 1.0
	var frame_duration = ANIMATION_DURATION / FRAME_COUNT

	for i in range(FRAME_COUNT):
		var frame_number = i + 1
		var frame_texture = load("res://assets/images/nuclear_%d.png" % frame_number)

		if frame_texture != null:
			nuclear_sprite.texture = frame_texture

		await viewport_root.get_tree().create_timer(frame_duration).timeout

	# Remove animation sprite
	nuclear_sprite.queue_free()


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


# Wind effect for frozen direction
static func create_wind_effect(direction: int):
	print("  💨 Creating wind effect for direction: %d" % direction)

	var scene_root = Engine.get_main_loop().root.get_tree().get_first_node_in_group("game_scene")
	if scene_root == null:
		print("  ❌ Could not find game scene")
		return null

	# Create container for wind lines
	var wind_container = Node2D.new()
	wind_container.name = "WindEffect_Direction%d" % direction
	scene_root.add_child(wind_container)

	# Get viewport size
	var viewport_size = scene_root.get_viewport().get_visible_rect().size

	# Create multiple wind lines that will continuously animate
	var num_lines = 100  # Even more lines
	var line_spacing_time = 0.03  # Even faster spawn rate

	# Start spawning lines continuously
	_spawn_wind_lines_continuously(wind_container, direction, viewport_size, num_lines, line_spacing_time)

	print("  ✅ Wind effect created and added to scene")
	return wind_container


# Continuously spawn wind lines
static func _spawn_wind_lines_continuously(container: Node2D, direction: int, viewport_size: Vector2, num_lines: int, spacing: float):
	while is_instance_valid(container) and container.get_parent() != null:
		_spawn_single_wind_line(container, direction, viewport_size)
		await container.get_tree().create_timer(spacing).timeout


# Spawn a single wind line
static func _spawn_single_wind_line(container: Node2D, direction: int, viewport_size: Vector2):
	var line = ColorRect.new()
	line.color = Color(0.85, 0.95, 1.0, 0.6)  # Light blue/white semi-transparent

	var line_width = 3.0
	var line_length = 450.0  # 3x longer trails
	var duration_vertical = 0.8
	var duration_horizontal = 0.5  # Faster for horizontal movement

	var start_pos: Vector2
	var end_pos: Vector2
	var duration: float

	# Direction enum: UP=0, DOWN=1, LEFT=2, RIGHT=3
	match direction:
		0:  # UP is blocked - wind flows DOWN (top to bottom)
			var x_offset = randf() * viewport_size.x
			line.size = Vector2(line_width, line_length)
			start_pos = Vector2(x_offset, -line_length)
			end_pos = Vector2(x_offset, viewport_size.y + line_length)
			duration = duration_vertical

		1:  # DOWN is blocked - wind flows UP (bottom to top)
			var x_offset = randf() * viewport_size.x
			line.size = Vector2(line_width, line_length)
			start_pos = Vector2(x_offset, viewport_size.y + line_length)
			end_pos = Vector2(x_offset, -line_length)
			duration = duration_vertical

		2:  # LEFT is blocked - wind flows RIGHT (left to right)
			var y_offset = randf() * viewport_size.y
			line.size = Vector2(line_length, line_width)
			start_pos = Vector2(-line_length, y_offset)
			end_pos = Vector2(viewport_size.x + line_length, y_offset)
			duration = duration_horizontal

		3:  # RIGHT is blocked - wind flows LEFT (right to left)
			var y_offset = randf() * viewport_size.y
			line.size = Vector2(line_length, line_width)
			start_pos = Vector2(viewport_size.x + line_length, y_offset)
			end_pos = Vector2(-line_length, y_offset)
			duration = duration_horizontal

	line.position = start_pos
	container.add_child(line)

	# Animate line across screen
	var tween = container.create_tween()
	tween.tween_property(line, "position", end_pos, duration)
	tween.tween_callback(line.queue_free)


# Remove wind effect for direction
static func remove_wind_effect(direction: int):
	print("  💨 Removing wind effect for direction: %d" % direction)

	var scene_root = Engine.get_main_loop().root.get_tree().get_first_node_in_group("game_scene")
	if scene_root == null:
		return

	var wind_name = "WindEffect_Direction%d" % direction
	var wind = scene_root.get_node_or_null(wind_name)
	if wind != null:
		# Simply remove the container, which will stop the spawning loop
		wind.queue_free()

	# Also remove wind sprites from tiles
	_remove_wind_sprites(direction)


# Remove all wind effects (called when starting new game)
static func clear_all_wind_effects():
	print("  💨 Clearing all wind effects")

	await Engine.get_main_loop().process_frame  # Wait one frame to ensure scene is ready

	var scene_root = Engine.get_main_loop().root.get_tree().get_first_node_in_group("game_scene")
	if scene_root == null:
		print("  ⚠️ Could not find game scene to clear wind effects")
		return

	# Remove all 4 possible directions
	var removed_count = 0
	for dir in range(4):
		var wind_name = "WindEffect_Direction%d" % dir
		var wind = scene_root.get_node_or_null(wind_name)
		if wind != null:
			wind.queue_free()
			removed_count += 1
		# Also remove wind sprites
		_remove_wind_sprites(dir)

	print("  ✅ Cleared %d wind effect(s)" % removed_count)


# Create wind sprites on edge tiles for a direction
static func create_wind_sprites(direction: int):
	print("  💨 Creating wind sprites for direction: %d" % direction)

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		print("  ❌ Could not find grid")
		return

	const TILE_SIZE = 240
	const TILE_SPACING = 20
	const CELL_SIZE = TILE_SIZE + TILE_SPACING
	const GRID_SIZE = 4
	const SPRITE_HEIGHT = 40  # Height of the wind sprite bar

	# Load wind textures
	var wind_textures = [
		load("res://assets/images/wind_1.png"),
		load("res://assets/images/wind_2.png"),
		load("res://assets/images/wind_3.png"),
		load("res://assets/images/wind_4.png")
	]

	# Determine which edge tiles to add sprites to
	var positions = []
	match direction:
		0:  # UP is blocked - sprites on TOP edge of top row tiles
			for x in range(GRID_SIZE):
				positions.append({"grid": Vector2i(x, 0), "edge": "top"})
		1:  # DOWN is blocked - sprites on BOTTOM edge of bottom row tiles
			for x in range(GRID_SIZE):
				positions.append({"grid": Vector2i(x, GRID_SIZE - 1), "edge": "bottom"})
		2:  # LEFT is blocked - sprites on LEFT edge of left column tiles
			for y in range(GRID_SIZE):
				positions.append({"grid": Vector2i(0, y), "edge": "left"})
		3:  # RIGHT is blocked - sprites on RIGHT edge of right column tiles
			for y in range(GRID_SIZE):
				positions.append({"grid": Vector2i(GRID_SIZE - 1, y), "edge": "right"})

	# Create sprite container
	var sprite_container = Node2D.new()
	sprite_container.name = "WindSprites_Direction%d" % direction
	grid_node.add_child(sprite_container)

	# Create sprites for each position
	for pos_data in positions:
		var grid_pos = pos_data["grid"]
		var edge = pos_data["edge"]

		var sprite = TextureRect.new()
		sprite.name = "WindSprite_%d_%d" % [grid_pos.x, grid_pos.y]
		sprite.texture = wind_textures[0]
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE

		# Calculate position based on edge
		var tile_x = TILE_SPACING + grid_pos.x * CELL_SIZE
		var tile_y = TILE_SPACING + grid_pos.y * CELL_SIZE

		match edge:
			"top":
				sprite.size = Vector2(TILE_SIZE, SPRITE_HEIGHT)
				sprite.position = Vector2(tile_x, tile_y - SPRITE_HEIGHT / 2)
				sprite.rotation_degrees = 0
			"bottom":
				sprite.size = Vector2(TILE_SIZE, SPRITE_HEIGHT)
				sprite.position = Vector2(tile_x, tile_y + TILE_SIZE - SPRITE_HEIGHT / 2)
				sprite.rotation_degrees = 180
				sprite.pivot_offset = Vector2(TILE_SIZE / 2, SPRITE_HEIGHT / 2)
			"left":
				sprite.size = Vector2(TILE_SIZE, SPRITE_HEIGHT)
				sprite.position = Vector2(tile_x - SPRITE_HEIGHT / 2, tile_y + TILE_SIZE)
				sprite.rotation_degrees = -90
				sprite.pivot_offset = Vector2(0, 0)
			"right":
				sprite.size = Vector2(TILE_SIZE, SPRITE_HEIGHT)
				sprite.position = Vector2(tile_x + TILE_SIZE + SPRITE_HEIGHT / 2, tile_y)
				sprite.rotation_degrees = 90
				sprite.pivot_offset = Vector2(0, 0)

		sprite_container.add_child(sprite)

	# Start animation loop for all sprites
	_animate_wind_sprites(sprite_container, wind_textures)


# Animate wind sprites with ping-pong cycle
static func _animate_wind_sprites(container: Node2D, textures: Array):
	var frame_index = 0
	var direction = 1  # 1 = forward, -1 = backward
	var frame_duration = 0.15  # Time between frames

	while is_instance_valid(container) and container.get_parent() != null:
		# Update all sprites in container
		for sprite in container.get_children():
			if sprite is TextureRect:
				sprite.texture = textures[frame_index]

		# Wait for next frame
		await container.get_tree().create_timer(frame_duration).timeout

		# Update frame index with ping-pong
		frame_index += direction
		if frame_index >= textures.size() - 1:
			direction = -1
		elif frame_index <= 0:
			direction = 1


# Remove wind sprites for a direction
static func _remove_wind_sprites(direction: int):
	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	var container_name = "WindSprites_Direction%d" % direction
	var container = grid_node.get_node_or_null(container_name)
	if container != null:
		container.queue_free()

