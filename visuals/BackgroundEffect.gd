# BackgroundEffect - Manages animated parallax background layers
extends Node

# Background parallax layers
var layer1_a: Sprite2D
var layer1_b: Sprite2D
var layer2_a: Sprite2D
var layer2_b: Sprite2D
var layer3_a: Sprite2D
var layer3_b: Sprite2D
var layer4_a: Sprite2D
var layer4_b: Sprite2D
var layer5_a: Sprite2D
var layer5_b: Sprite2D

# Parallax scrolling speeds (pixels per second)
const LAYER1_SPEED = 10.0
const LAYER2_SPEED = 25.0
const LAYER3_SPEED = 50.0
const LAYER4_SPEED = 75.0
const LAYER5_SPEED = 100.0
const SPRITE_WIDTH = 3413.0

var background_layer: Node2D

# Initialize with background layer node
func initialize(bg_layer: Node2D):
	background_layer = bg_layer

	# Initialize background layer references (with null checks)
	if background_layer:
		layer1_a = background_layer.get_node_or_null("Layer1_A")
		layer1_b = background_layer.get_node_or_null("Layer1_B")
		layer2_a = background_layer.get_node_or_null("Layer2_A")
		layer2_b = background_layer.get_node_or_null("Layer2_B")
		layer3_a = background_layer.get_node_or_null("Layer3_A")
		layer3_b = background_layer.get_node_or_null("Layer3_B")
		layer4_a = background_layer.get_node_or_null("Layer4_A")
		layer4_b = background_layer.get_node_or_null("Layer4_B")
		layer5_a = background_layer.get_node_or_null("Layer5_A")
		layer5_b = background_layer.get_node_or_null("Layer5_B")


# Update parallax scrolling animation
func update(delta: float):
	# Scroll each layer at different speeds
	_scroll_layer(layer1_a, layer1_b, LAYER1_SPEED * delta)
	_scroll_layer(layer2_a, layer2_b, LAYER2_SPEED * delta)
	_scroll_layer(layer3_a, layer3_b, LAYER3_SPEED * delta)
	_scroll_layer(layer4_a, layer4_b, LAYER4_SPEED * delta)
	_scroll_layer(layer5_a, layer5_b, LAYER5_SPEED * delta)


# Scroll a background layer with looping
func _scroll_layer(sprite_a: Sprite2D, sprite_b: Sprite2D, speed: float):
	# Check if sprites exist before accessing them
	if not sprite_a or not sprite_b:
		return

	# Move both sprites to the left
	sprite_a.position.x -= speed
	sprite_b.position.x -= speed

	# When sprite A goes off-screen to the left, move it to the right (outside viewport)
	if sprite_a.position.x <= -SPRITE_WIDTH:
		sprite_a.position.x = sprite_b.position.x + SPRITE_WIDTH

	# When sprite B goes off-screen to the left, move it to the right (outside viewport)
	if sprite_b.position.x <= -SPRITE_WIDTH:
		sprite_b.position.x = sprite_a.position.x + SPRITE_WIDTH
