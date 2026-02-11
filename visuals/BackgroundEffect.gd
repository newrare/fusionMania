# BackgroundEffect - Manages animated parallax background layers with clouds
extends Node

# Background layer nodes
var sky: Sprite2D
var rock: Sprite2D
var cloud01_a: Sprite2D
var cloud01_b: Sprite2D
var cloud02_a: Sprite2D
var cloud02_b: Sprite2D
var ground: Sprite2D

# Cloud animation speeds (pixels per second) - base values
const CLOUD01_SPEED_MIN = 20.0
const CLOUD01_SPEED_MAX = 50.0
const CLOUD02_SPEED_MIN = -60.0   # Negative = left
const CLOUD02_SPEED_MAX = -30.0

# Current cloud speeds (varied on each wrap)
var cloud01_speed: float = 30.0
var cloud02_speed: float = -45.0

# Base Y position for clouds
const CLOUD_BASE_Y = 960
const CLOUD_Y_VARIATION = 200  # +/- 200px

# Screen width for cloud wrapping (1920 x 1.778 scale)
const SCREEN_WIDTH = 1080.0
const CLOUD_WIDTH = 3413.0  # Scaled cloud texture width (1920 * 1.778)

# Transparency animation
var cloud01_alpha: float = 1.0
var cloud02_alpha: float = 0.8

const MIN_ALPHA = 0.1  # 10%
const MAX_ALPHA = 1.0  # 100%

# Sky brightness animation
var sky_brightness: float = 1.0
var sky_brightness_target: float = 1.0
var sky_brightness_direction: int = -1

const BRIGHTNESS_CHANGE_SPEED = 0.05  # Brightness change per second (slower = 2x longer transitions)
const MIN_BRIGHTNESS = 0.40   # Darker
const MAX_BRIGHTNESS = 1.15   # Brighter

var background_layer: Node2D


# Initialize with background layer node
func initialize(bg_layer: Node2D):
	background_layer = bg_layer
	
	if background_layer:
		sky = background_layer.get_node_or_null("Sky")
		rock = background_layer.get_node_or_null("Rock")
		cloud01_a = background_layer.get_node_or_null("Cloud01_A")
		cloud01_b = background_layer.get_node_or_null("Cloud01_B")
		cloud02_a = background_layer.get_node_or_null("Cloud02_A")
		cloud02_b = background_layer.get_node_or_null("Cloud02_B")
		ground = background_layer.get_node_or_null("Ground")
		
		# Set initial random alpha values
		if cloud01_a and cloud01_b:
			var initial_alpha = randf_range(MIN_ALPHA, MAX_ALPHA)
			cloud01_a.modulate.a = initial_alpha
			cloud01_b.modulate.a = initial_alpha
			cloud01_alpha = initial_alpha
			# Set initial random speed
			cloud01_speed = randf_range(CLOUD01_SPEED_MIN, CLOUD01_SPEED_MAX)
		
		if cloud02_a and cloud02_b:
			var initial_alpha = randf_range(MIN_ALPHA, MAX_ALPHA)
			cloud02_a.modulate.a = initial_alpha
			cloud02_b.modulate.a = initial_alpha
			cloud02_alpha = initial_alpha
			# Set initial random speed
			cloud02_speed = randf_range(CLOUD02_SPEED_MIN, CLOUD02_SPEED_MAX)
		
		# Set initial random brightness for sky
		if sky:
			var initial_brightness = randf_range(MIN_BRIGHTNESS, MAX_BRIGHTNESS)
			sky.modulate = Color(initial_brightness, initial_brightness, initial_brightness)
			sky_brightness = initial_brightness
			sky_brightness_target = initial_brightness
			
			# Apply same brightness to rock and ground
			if rock:
				rock.modulate = Color(initial_brightness, initial_brightness, initial_brightness)
			if ground:
				ground.modulate = Color(initial_brightness, initial_brightness, initial_brightness)


# Update cloud animations
func update(delta: float):
	# Animate sky brightness
	if sky:
		_animate_sky_brightness(delta)
	
	# Animate cloud01 (moves right)
	if cloud01_a and cloud01_b:
		_animate_cloud_pair(cloud01_a, cloud01_b, cloud01_speed * delta, delta, true)
	
	# Animate cloud02 (moves left)
	if cloud02_a and cloud02_b:
		_animate_cloud_pair(cloud02_a, cloud02_b, cloud02_speed * delta, delta, false)


# Animate a pair of clouds with scrolling and transparency change on wrap
func _animate_cloud_pair(sprite_a: Sprite2D, sprite_b: Sprite2D, movement: float, delta: float, is_cloud01: bool):
	# Move clouds
	sprite_a.position.x += movement
	sprite_b.position.x += movement
	
	# Get current alpha
	var current_alpha = cloud01_alpha if is_cloud01 else cloud02_alpha
	
	# Wrap clouds when they go off screen and apply randomization
	if movement > 0:  # Moving right
		# Cloud A wraps
		if sprite_a.position.x > SCREEN_WIDTH + CLOUD_WIDTH / 2:
			sprite_a.position.x = sprite_b.position.x - CLOUD_WIDTH
			_randomize_cloud(sprite_a, is_cloud01)
			current_alpha = sprite_a.modulate.a
		# Cloud B wraps
		if sprite_b.position.x > SCREEN_WIDTH + CLOUD_WIDTH / 2:
			sprite_b.position.x = sprite_a.position.x - CLOUD_WIDTH
			_randomize_cloud(sprite_b, is_cloud01)
			current_alpha = sprite_b.modulate.a
	else:  # Moving left
		# Cloud A wraps
		if sprite_a.position.x < -CLOUD_WIDTH / 2:
			sprite_a.position.x = sprite_b.position.x + CLOUD_WIDTH
			_randomize_cloud(sprite_a, is_cloud01)
			current_alpha = sprite_a.modulate.a
		# Cloud B wraps
		if sprite_b.position.x < -CLOUD_WIDTH / 2:
			sprite_b.position.x = sprite_a.position.x + CLOUD_WIDTH
			_randomize_cloud(sprite_b, is_cloud01)
			current_alpha = sprite_b.modulate.a
	
	# Apply alpha to both sprites
	sprite_a.modulate.a = current_alpha
	sprite_b.modulate.a = current_alpha
	
	# Save current alpha
	if is_cloud01:
		cloud01_alpha = current_alpha
	else:
		cloud02_alpha = current_alpha


# Randomize cloud properties on wrap
func _randomize_cloud(sprite: Sprite2D, is_cloud01: bool):
	# 1. Random transparency (10% to 100%)
	var new_alpha = randf_range(MIN_ALPHA, MAX_ALPHA)
	sprite.modulate.a = new_alpha
	
	# 2. Random Y position (+/- 200px from base)
	var y_offset = randf_range(-CLOUD_Y_VARIATION, CLOUD_Y_VARIATION)
	sprite.position.y = CLOUD_BASE_Y + y_offset
	
	# 3. Random vertical flip (mirror)
	sprite.flip_v = randf() > 0.5
	
	# 4. Random speed variation
	if is_cloud01:
		cloud01_speed = randf_range(CLOUD01_SPEED_MIN, CLOUD01_SPEED_MAX)
		cloud01_alpha = new_alpha
	else:
		cloud02_speed = randf_range(CLOUD02_SPEED_MIN, CLOUD02_SPEED_MAX)
		cloud02_alpha = new_alpha


# Animate sky brightness
func _animate_sky_brightness(delta: float):
	# Move towards target brightness
	if sky_brightness_direction < 0:  # Getting darker
		sky_brightness -= BRIGHTNESS_CHANGE_SPEED * delta
		if sky_brightness <= MIN_BRIGHTNESS:
			sky_brightness = MIN_BRIGHTNESS
			# Reverse direction and pick new random target
			sky_brightness_direction = 1
			sky_brightness_target = randf_range(0.95, MAX_BRIGHTNESS)
	else:  # Getting brighter
		sky_brightness += BRIGHTNESS_CHANGE_SPEED * delta
		if sky_brightness >= sky_brightness_target:
			sky_brightness = sky_brightness_target
			# Reverse direction
			sky_brightness_direction = -1
			sky_brightness_target = randf_range(MIN_BRIGHTNESS, 0.95)
	
	# Apply brightness to sky
	sky.modulate = Color(sky_brightness, sky_brightness, sky_brightness)
	
	# Apply same brightness to rock and ground (synchronized)
	if rock:
		rock.modulate = Color(sky_brightness, sky_brightness, sky_brightness)
	if ground:
		ground.modulate = Color(sky_brightness, sky_brightness, sky_brightness)
