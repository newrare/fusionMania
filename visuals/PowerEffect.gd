# PowerEffect - Visual effects for power activations
# Handles all visual feedback for powers
extends Node

# Preload textures to avoid loading delays
const ICE_OVERLAY_TEXTURE = preload("res://assets/images/ice_overlay.png")

# Fire line sequence (new version with fireball sprites)
# Note: Tile visual effects (emitter/target) are now handled by PowerManager via Tile.gd methods
static func fire_line_sequence(emitter_tile, target_tiles: Array, is_horizontal: bool, grid_manager):
	print("  🔥 Fire line sequence: %s, %d targets" % ["horizontal" if is_horizontal else "vertical", target_tiles.size()])

	if emitter_tile == null:
		return

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	# Launch fireballs in both directions
	if is_horizontal:
		_create_fireball(grid_node, emitter_tile, Vector2.RIGHT)  # Right
		_create_fireball(grid_node, emitter_tile, Vector2.LEFT)   # Left
	else:
		_create_fireball(grid_node, emitter_tile, Vector2.DOWN)   # Down
		_create_fireball(grid_node, emitter_tile, Vector2.UP)     # Up

	# Wait then destroy tiles
	await grid_node.get_tree().create_timer(1.0).timeout
	for target in target_tiles:
		if is_instance_valid(target):
			grid_manager.destroy_tile(target)


# Fire cross sequence (horizontal + vertical)
# Note: Tile visual effects (emitter/target) are now handled by PowerManager via Tile.gd methods
static func fire_cross_sequence(emitter_tile, target_tiles: Array, grid_manager):
	print("  🔥 Fire cross sequence: %d targets" % target_tiles.size())

	if emitter_tile == null:
		return

	var grid_node = Engine.get_main_loop().root.get_tree().get_first_node_in_group("grid")
	if grid_node == null:
		return

	# Launch fireballs in all 4 directions
	_create_fireball(grid_node, emitter_tile, Vector2.RIGHT)  # Right
	_create_fireball(grid_node, emitter_tile, Vector2.LEFT)   # Left
	_create_fireball(grid_node, emitter_tile, Vector2.DOWN)   # Down
	_create_fireball(grid_node, emitter_tile, Vector2.UP)     # Up

	# Wait then destroy tiles
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


# ============================
# Deprecated - Tile effects now in Tile.gd
# ============================

# Note: _blink_tile and highlight_emitter_tile are deprecated
# Use Tile.start_target_effect() and Tile.start_emitter_effect() instead
# Keeping for backwards compatibility with existing code that hasn't been migrated

# Make tile blink for duration (DEPRECATED - use Tile.start_target_effect)
static func _blink_tile(tile, duration: float):
	if not is_instance_valid(tile):
		return
	
	# Delegate to new Tile method if available
	if tile.has_method("start_target_effect"):
		tile.start_target_effect(duration)
		return

	var original_modulate 	= tile.modulate
	var blink_count 		= int(duration / 0.2)
	var tween 				= tile.create_tween()

	for i in range(blink_count):
		tween.tween_property(tile, "modulate", Color(1.5, 1.5, 1.5, 1), 0.1)
		tween.tween_property(tile, "modulate", original_modulate, 0.1)

	tween.tween_property(tile, "modulate", original_modulate, 0.0)


# Highlight emitter tile (DEPRECATED - use Tile.start_emitter_effect)
static func highlight_emitter_tile(emitter_tile, duration: float):
	if not is_instance_valid(emitter_tile):
		return
	
	# Delegate to new Tile method if available
	if emitter_tile.has_method("start_emitter_effect"):
		emitter_tile.start_emitter_effect(duration)
		return

	# Legacy implementation for backwards compatibility
	if emitter_tile.power_icon != null and emitter_tile.power_icon.visible:
		var original_scale 	= emitter_tile.power_icon.scale
		var blink_count		= max(1, int(duration / 0.2))  # At least 1 blink
		var icon_tween 		= emitter_tile.power_icon.create_tween()

		for i in range(blink_count):
			icon_tween.tween_property(emitter_tile.power_icon, "scale", original_scale * 1.3, 0.1)
			icon_tween.tween_property(emitter_tile.power_icon, "scale", original_scale, 0.1)

		icon_tween.tween_property(emitter_tile.power_icon, "scale", original_scale, 0.0)

	if emitter_tile.value_label != null:
		var original_label_color 	= emitter_tile.value_label.modulate
		var label_tween 			= emitter_tile.value_label.create_tween()

		label_tween.tween_property(emitter_tile.value_label, "modulate", Color(0.3, 0.5, 1, 1), 0.1)
		label_tween.tween_interval(max(0.0, duration - 0.2))  # Ensure non-negative
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

	# Note: emitter visual effect is handled by PowerManager calling start_emitter_effect directly

	# Create ice overlay
	var viewport_root 	= tile.get_tree().root
	var ice_overlay 	= TextureRect.new()

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
		tween.tween_interval(2.0)
		tween.tween_property(ice_overlay, "modulate:a", 0.0, 1.0)
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

	const TILE_SIZE 			= 240
	const TILE_SPACING 			= 20
	const CELL_SIZE 			= TILE_SIZE + TILE_SPACING
	const ANIMATION_DURATION 	= 0.3
	const FRAME_COUNT 			= 5

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


# ============================
# Wind Effect Methods
# ============================

# Create wind effect for a frozen direction
static func create_wind_effect(direction: int):
	print("  💨 Creating wind effect for direction: %d" % direction)
	
	var game_scene = Engine.get_main_loop().root.get_tree().get_first_node_in_group("game_scene")
	if game_scene == null:
		return
	
	var wind_name = "WindEffect_Direction%d" % direction
	var existing = game_scene.get_node_or_null(wind_name)
	if existing != null:
		existing.queue_free()
	
	var wind = ColorRect.new()
	wind.name = wind_name
	wind.color = Color(0.5, 0.8, 1.0, 0.3)
	wind.size = Vector2(50, 50)
	
	game_scene.add_child(wind)


# Remove wind effect for a direction
static func remove_wind_effect(direction: int):
	print("  💨 Removing wind effect for direction: %d" % direction)
	
	var game_scene = Engine.get_main_loop().root.get_tree().get_first_node_in_group("game_scene")
	if game_scene == null:
		return
	
	var wind_name = "WindEffect_Direction%d" % direction
	var wind = game_scene.get_node_or_null(wind_name)
	if wind != null:
		wind.queue_free()
	
	_remove_wind_sprites(direction)


# Clear all wind effects (called when starting new game)
static func clear_all_wind_effects():
	print("  💨 Clearing all wind effects")
	
	await Engine.get_main_loop().process_frame
	
	var scene_root = Engine.get_main_loop().root.get_tree().get_first_node_in_group("game_scene")
	if scene_root == null:
		return
	
	var removed_count = 0
	for dir in range(4):
		var wind_name = "WindEffect_Direction%d" % dir
		var wind = scene_root.get_node_or_null(wind_name)
		if wind != null:
			wind.queue_free()
			removed_count += 1
		_remove_wind_sprites(dir)
	
	print("  ✅ Cleared %d wind effect(s)" % removed_count)


# Create wind sprites on edge tiles
static func create_wind_sprites(direction: int):
	print("  💨 Creating wind sprites for direction: %d" % direction)
	# Placeholder - sprites are complex, just create simple indicator for now


# Remove wind sprites for a direction
static func _remove_wind_sprites(direction: int):
	# Placeholder - cleanup if sprites were created
	pass
