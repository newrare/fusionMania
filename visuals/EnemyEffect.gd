# EnemyEffect - Visual animation of power ball traveling from enemy to tile
extends Node2D

# Animation settings
const BALL_SIZE: Vector2 = Vector2(20, 20)
const ANIMATION_DURATION: float = 0.7
const BALL_COLOR: Color = Color("#FF4444")  # Red/orange ball

# Ball visual components
var ball_sprite: ColorRect
var tween: Tween

signal animation_completed()

func _ready():
	# Create ball visual (simple colored circle using TextureRect with a circle texture)
	ball_sprite = ColorRect.new()
	ball_sprite.size = BALL_SIZE
	ball_sprite.color = BALL_COLOR
	ball_sprite.position = -BALL_SIZE / 2  # Center the ball
	add_child(ball_sprite)


# Start animation from enemy position to target tile position
func animate_to_target(start_pos: Vector2, target_pos: Vector2):
	position = start_pos
	scale = Vector2(0.5, 0.5)  # Start smaller
	modulate.a = 1.0

	# Create tween for animation
	tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously

	# Animate position (main movement)
	tween.tween_property(self, "position", target_pos, ANIMATION_DURATION)

	# Animate scale (grow slightly during travel)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), ANIMATION_DURATION * 0.6)
	tween.tween_property(self, "scale", Vector2(0.3, 0.3), ANIMATION_DURATION * 0.4).set_delay(ANIMATION_DURATION * 0.6)

	# Animate opacity (fade out at the end)
	tween.tween_property(self, "modulate:a", 0.0, ANIMATION_DURATION * 0.3).set_delay(ANIMATION_DURATION * 0.7)

	# Complete animation
	await tween.finished
	animation_completed.emit()
	queue_free()


# Cancel the animation (called when enemy is destroyed)
func cancel_animation():
	if tween and tween.is_valid():
		tween.kill()
	queue_free()


# Create and play animation (static function for easy use)
static func create_animation(parent: Node, start_pos: Vector2, target_pos: Vector2):
	var EnemyEffectClass = preload("res://visuals/EnemyEffect.gd")
	var animation = EnemyEffectClass.new()
	parent.add_child(animation)
	animation.animate_to_target(start_pos, target_pos)
	return animation