# AnimationManager - Central animation control for immediate logic separation
# Manages all animations with grouping and cancellation support
extends Node

# ============================================================================
# ANIMATION TRACKING
# ============================================================================

## Dictionary of animation groups: group_name -> Array[Tween]
var active_animations: Dictionary = {}

## Array of cleanup timers to prevent memory leaks
var cleanup_timers: Array[Timer] = []

## Default animation duration for fallback cleanup
const DEFAULT_CLEANUP_DELAY: float = 5.0

# ============================================================================
# SIGNALS
# ============================================================================

signal animation_group_started(group_name: String)
signal animation_group_completed(group_name: String)
signal all_animations_cancelled()

# ============================================================================
# CORE FUNCTIONS
# ============================================================================

func _ready():
	print("🎬 AnimationManager ready - Managing parallel animations")

## Register an animation tween with a group for management
func register_animation(tween: Tween, group: String = "default") -> bool:
	if not tween or not tween.is_valid():
		print("⚠️ AnimationManager: Invalid tween provided")
		return false
	
	# Initialize group if needed
	if not active_animations.has(group):
		active_animations[group] = []
		animation_group_started.emit(group)
	
	# Add to group
	active_animations[group].append(tween)
	
	# Connect cleanup signal
	if not tween.finished.is_connected(_on_animation_finished):
		tween.finished.connect(_on_animation_finished.bind(tween, group))
	
	print("🎬 Animation registered to group '%s' (total: %d)" % [group, active_animations[group].size()])
	return true

## Cancel all animations in a specific group
func cancel_animation_group(group: String):
	if not active_animations.has(group):
		return
	
	print("🚫 Cancelling animation group '%s' (%d animations)" % [group, active_animations[group].size()])
	
	for tween in active_animations[group]:
		if tween and tween.is_valid():
			tween.kill()
	
	active_animations[group].clear()
	active_animations.erase(group)

## Cancel all active animations
func cancel_all_animations():
	print("🚫 Cancelling ALL animations (%d groups)" % active_animations.size())
	
	for group in active_animations.keys():
		for tween in active_animations[group]:
			if tween and tween.is_valid():
				tween.kill()
	
	active_animations.clear()
	all_animations_cancelled.emit()

## Get number of active animation groups
func get_active_group_count() -> int:
	return active_animations.size()

## Get number of animations in a specific group  
func get_group_animation_count(group: String) -> int:
	if active_animations.has(group):
		return active_animations[group].size()
	return 0

## Check if a specific group is active
func is_group_active(group: String) -> bool:
	return active_animations.has(group) and active_animations[group].size() > 0

# ============================================================================
# ANIMATION CREATION HELPERS
# ============================================================================

## Create and register a movement animation
func create_movement_animation(tile: Node, target_pos: Vector2, duration: float = 0.2, group: String = "movement") -> Tween:
	if not tile:
		return null
	
	var tween = tile.create_tween()
	tween.tween_property(tile, "position", target_pos, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	
	register_animation(tween, group)
	return tween

## Create and register a fade animation
func create_fade_animation(node: Node, target_alpha: float, duration: float = 0.3, group: String = "effects") -> Tween:
	if not node:
		return null
	
	var tween = node.create_tween()
	tween.tween_property(node, "modulate:a", target_alpha, duration)
	
	register_animation(tween, group)
	return tween

## Create and register a scale animation
func create_scale_animation(node: Node, target_scale: Vector2, duration: float = 0.2, group: String = "effects") -> Tween:
	if not node:
		return null
	
	var tween = node.create_tween()
	tween.tween_property(node, "scale", target_scale, duration)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	register_animation(tween, group)
	return tween

## Create and register a bounce animation for feedback
func create_bounce_animation(node: Node, direction_offset: Vector2, duration: float = 0.2, group: String = "feedback") -> Tween:
	if not node:
		return null
	
	var original_pos = node.position
	var tween = node.create_tween()
	tween.tween_property(node, "position", original_pos + direction_offset, duration * 0.5)
	tween.tween_property(node, "position", original_pos, duration * 0.5)
	tween.set_ease(Tween.EASE_OUT)
	
	register_animation(tween, group)
	return tween

# ============================================================================
# POWER EFFECT ANIMATIONS
# ============================================================================

## Create explosion effect animation
func create_explosion_animation(center_pos: Vector2, group: String = "powers") -> Tween:
	# Create temporary explosion node
	var explosion = ColorRect.new()
	explosion.color = Color.ORANGE
	explosion.size = Vector2(50, 50)
	explosion.position = center_pos - explosion.size / 2
	
	# Add to scene temporarily
	var scene_root = get_tree().current_scene
	scene_root.add_child(explosion)
	
	# Animate
	var tween = explosion.create_tween()
	tween.set_parallel(true)
	tween.tween_property(explosion, "scale", Vector2(3, 3), 0.3)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)
	
	register_animation(tween, group)
	return tween

## Create ice effect animation
func create_ice_effect_animation(tile_pos: Vector2, group: String = "powers") -> Tween:
	# Create temporary ice overlay
	var ice_effect = ColorRect.new()
	ice_effect.color = Color(0.5, 0.8, 1.0, 0.3)
	ice_effect.size = Vector2(80, 80)
	ice_effect.position = tile_pos - ice_effect.size / 2
	
	var scene_root = get_tree().current_scene
	scene_root.add_child(ice_effect)
	
	var tween = ice_effect.create_tween()
	tween.tween_property(ice_effect, "modulate:a", 0.0, 2.0)
	tween.tween_callback(ice_effect.queue_free)
	
	register_animation(tween, group)
	return tween

# ============================================================================
# CLEANUP SYSTEM
# ============================================================================

## Create a safety timer to cleanup animations if they don't finish
func create_cleanup_timer(duration: float, callback: Callable):
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(_on_cleanup_timer_timeout.bind(timer, callback))
	
	add_child(timer)
	cleanup_timers.append(timer)
	timer.start()

## Cleanup all timers (call when scene changes)
func cleanup_all_timers():
	print("🧹 Cleaning up %d animation timers" % cleanup_timers.size())
	
	for timer in cleanup_timers:
		if timer and is_instance_valid(timer):
			timer.stop()
			timer.queue_free()
	
	cleanup_timers.clear()

# ============================================================================
# INTERNAL HANDLERS
# ============================================================================

## Called when an animation finishes naturally
func _on_animation_finished(tween: Tween, group: String):
	if active_animations.has(group):
		active_animations[group].erase(tween)
		
		# Clean up empty groups
		if active_animations[group].is_empty():
			active_animations.erase(group)
			animation_group_completed.emit(group)
			print("✅ Animation group '%s' completed" % group)

## Called when a cleanup timer fires
func _on_cleanup_timer_timeout(timer: Timer, callback: Callable):
	# Remove from tracking
	cleanup_timers.erase(timer)
	
	# Execute callback safely
	if callback and callback.is_valid():
		callback.call_deferred()
	
	# Cleanup timer
	if timer and is_instance_valid(timer):
		timer.queue_free()

# ============================================================================
# DEBUG FUNCTIONS
# ============================================================================

## Print current animation status for debugging
func print_animation_status():
	print("🎬 Animation Status:")
	print("  Active groups: %d" % active_animations.size())
	for group in active_animations.keys():
		print("    %s: %d animations" % [group, active_animations[group].size()])
	print("  Cleanup timers: %d" % cleanup_timers.size())

## Get animation statistics
func get_animation_stats() -> Dictionary:
	var stats = {
		"total_groups": active_animations.size(),
		"total_animations": 0,
		"cleanup_timers": cleanup_timers.size(),
		"groups": {}
	}
	
	for group in active_animations.keys():
		var count = active_animations[group].size()
		stats.total_animations += count
		stats.groups[group] = count
	
	return stats