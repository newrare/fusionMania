# Test script for FallenEnemy physics system
extends Node2D

func _ready():
	print("Testing FallenEnemy physics system...")
	
	# Spawn multiple enemies and make them fall
	await get_tree().process_frame
	test_fallen_enemy_spawn()


func test_fallen_enemy_spawn():
	print("📍 Starting FallenEnemy test...")
	
	# Create a few fallen enemies at different positions
	var pos_x = [300, 540, 780]
	var pos_y = 200
	
	for x in pos_x:
		var fallen_scene = preload("res://objects/FallenEnemy.tscn")
		var fallen = fallen_scene.instantiate()
		
		# Position at test location
		fallen.global_position = Vector2(x, pos_y)
		fallen.z_index = -50
		
		# Give it a color (simulate different types)
		var colors = [Color.WHITE, Color.GREEN, Color.BLUE, Color.MAGENTA]
		var color = colors[randi() % colors.size()]
		
		var panel = fallen.get_node("TileContainer/BackgroundPanel")
		# Create a simple StyleBoxFlat for testing
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = color
		style_box.set_corner_radius_all(10)
		panel.add_theme_stylebox_override("panel", style_box)
		
		add_child(fallen)
		print("✓ Fallen enemy spawned at %s with color %s" % [Vector2(x, pos_y), color])
	
	print("✅ FallenEnemy test initialized - observe gravity effects")
	print("   Expect: blocks fall, bounce, then stack at ground level (y~1480)")
