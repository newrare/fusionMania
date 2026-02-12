extends Node2D

# Enemy properties
var level: int = 2
var max_hp: int = 10
var current_hp: int = 10
var enemy_name: String = ""
var sprite_path: String = ""

# Boss detection
var is_sub_boss: bool = false
var is_boss: bool = false

# Tile colors (same as Tile.gd for level-based glow effect)
const TILE_COLORS = {
	2:    Color("#FFFFFF"),  # White
	4:    Color("#D9D9D9"),  # Light Gray
	8:    Color("#00FF00"),  # Green
	16:   Color("#6D9EEB"),  # Blue
	32:   Color("#FFE599"),  # Light Yellow
	64:   Color("#E69138"),  # Orange
	128:  Color("#FF00FF"),  # Magenta
	256:  Color("#C809C8"),  # Purple
	512:  Color("#9C079C"),  # Dark Purple
	1024: Color("#700570"),  # Darker Purple
	2048: Color("#440344")   # Deep Purple
}

# Tile dimensions
const TILE_SIZE = 240
const CORNER_RADIUS = 20

# Label font size
const LABEL_FONT_SIZE = 30
const LABEL_FONT_SIZE_SUB_BOSS = 36
const LABEL_FONT_SIZE_BOSS = 42

# Signals
signal defeated(enemy_level: int)

func _ready():
	pass

# Initialize enemy from EnemyManager data
func initialize(data: Dictionary):
	level = data.get("level", 2)
	max_hp = data.get("max_hp", 10)
	current_hp = max_hp
	enemy_name = data.get("name", "Unknown")
	sprite_path = data.get("sprite_path", "")

	# Boss detection
	is_sub_boss = (level == 1024)
	is_boss = (level == 2048)

	# Set initial state for spawn animation
	scale = Vector2.ZERO
	modulate.a = 0.0

	# Get node references
	var enemy_sprite_node = get_node("TileContainer/EnemySprite")
	var background_panel = get_node("TileContainer/BackgroundPanel")
	var liquid_wave = get_node("TileContainer/LiquidWave")
	var level_label_node = get_node("LevelLabel")
	var name_label_node = get_node("NameLabel")
	var damage_label_node = get_node("DamageLabel")

	# Load sprite texture (no color effect)
	var texture = load_sprite_texture(sprite_path)
	if texture:
		enemy_sprite_node.texture = texture

	# Get level color
	var level_color = TILE_COLORS.get(level, Color.WHITE)
	var dark_color = level_color.darkened(0.7)  # Background darker version
	print("🎨 Enemy Lv%d - Level color: %s" % [level, level_color])

	# Create StyleBoxFlat for BackgroundPanel (dark base with rounded corners)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = dark_color
	bg_style.corner_radius_top_left = CORNER_RADIUS
	bg_style.corner_radius_top_right = CORNER_RADIUS
	bg_style.corner_radius_bottom_left = CORNER_RADIUS
	bg_style.corner_radius_bottom_right = CORNER_RADIUS
	bg_style.anti_aliasing = true
	bg_style.anti_aliasing_size = 2.0
	background_panel.add_theme_stylebox_override("panel", bg_style)

	# Create ShaderMaterial for LiquidWave with ondulation effect
	var wave_shader = load("res://assets/shaders/liquid_wave.gdshader")
	var wave_material = ShaderMaterial.new()
	wave_material.shader = wave_shader
	wave_material.set_shader_parameter("liquid_color", level_color)
	wave_material.set_shader_parameter("surface_height", 0.0)  # 0 = full HP
	wave_material.set_shader_parameter("wave_amplitude", 6.0)
	wave_material.set_shader_parameter("wave_frequency", 12.0)
	wave_material.set_shader_parameter("wave_speed", 2.5)
	wave_material.set_shader_parameter("corner_radius", float(CORNER_RADIUS))
	wave_material.set_shader_parameter("rect_size", Vector2(TILE_SIZE, TILE_SIZE))
	liquid_wave.material = wave_material

	# Initialize damage label to empty
	damage_label_node.text = ""

	# Update visual elements
	update_liquid_fill()
	update_display()

	# Play spawn animation
	play_spawn_animation()

	# Optional: Boss music
	if is_boss and AudioManager.has_method("play_music"):
		AudioManager.play_music("music_boss")


# Load sprite texture from path (single 876x876 image)
func load_sprite_texture(path: String) -> Texture2D:
	if path.is_empty() or not FileAccess.file_exists(path):
		print("Enemy: Sprite path invalid or file not found: ", path)
		return null

	var texture = load(path)
	if not texture:
		print("Enemy: Failed to load texture from: ", path)
		return null

	return texture


# Update HP from EnemyManager (visual only - HP is managed by EnemyManager)
func update_hp(new_hp: int):
	current_hp = max(0, new_hp)
	update_liquid_fill()
	flash_damage()

	print("💥 Enemy HP updated! HP: %d/%d" % [current_hp, max_hp])


# Update liquid fill height based on HP percentage
func update_liquid_fill():
	var liquid_wave = get_node("TileContainer/LiquidWave")
	if max_hp <= 0:
		return

	var health_percent = float(current_hp) / float(max_hp)

	# surface_height: 0 = full (100% HP), 1 = empty (0% HP)
	var target_surface = 1.0 - health_percent

	# Get the shader material
	var material = liquid_wave.material as ShaderMaterial
	if material:
		# Animate the surface height
		var current_surface = material.get_shader_parameter("surface_height")
		if current_surface == null:
			current_surface = 0.0

		var tween = create_tween()
		tween.tween_method(
			func(value): material.set_shader_parameter("surface_height", value),
			current_surface,
			target_surface,
			0.4
		)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)

	print("🌊 Liquid fill: %d%% (surface: %.2f)" % [int(health_percent * 100), target_surface])


# Update sprite texture (called when health state changes)
func update_sprite(new_sprite_path: String):
	sprite_path = new_sprite_path
	var texture = load_sprite_texture(sprite_path)
	if texture:
		var enemy_sprite_node = get_node("TileContainer/EnemySprite")
		enemy_sprite_node.texture = texture
		print("🔄 Enemy sprite updated: %s" % sprite_path)


# Show damage taken in the damage label
func show_damage(damage: int):
	var damage_label_node = get_node("DamageLabel")
	damage_label_node.text = "[color=#FF0000]-%d[/color]" % damage

	# Clear the label after 1.5 seconds
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): damage_label_node.text = "")


# Update level and name labels separately
func update_display():
	var level_label_node = get_node("LevelLabel")
	var name_label_node = get_node("NameLabel")

	level_label_node.bbcode_enabled = true
	name_label_node.bbcode_enabled = true

	# Get level color as hex string
	var level_color = TILE_COLORS.get(level, Color.WHITE)
	var color_hex = level_color.to_html(false)

	# Add boss prefix and determine font size
	var name_prefix = ""
	var font_size = LABEL_FONT_SIZE
	if is_sub_boss:
		name_prefix = "⚔️ "
		font_size = LABEL_FONT_SIZE_SUB_BOSS
	elif is_boss:
		name_prefix = "👑 "
		font_size = LABEL_FONT_SIZE_BOSS

	# Clear previous theme overrides for name label
	name_label_node.remove_theme_font_size_override("font_size")
	name_label_node.remove_theme_font_size_override("normal_font_size")

	# Apply font size for name label
	name_label_node.add_theme_font_size_override("normal_font_size", font_size)
	name_label_node.add_theme_font_size_override("font_size", font_size)

	# Update labels with BBCode
	name_label_node.text = "[center]%s%s[/center]" % [name_prefix, enemy_name]
	level_label_node.text = "[center][color=#%s]Lv %d[/color][/center]" % [color_hex, level]


# Create a visual flash on damage
func flash_damage():
	var enemy_sprite_node = get_node("TileContainer/EnemySprite")
	var original_modulate = enemy_sprite_node.modulate

	# Flash red
	var tween = create_tween()
	tween.tween_property(enemy_sprite_node, "modulate", Color.RED, 0.1)
	tween.tween_property(enemy_sprite_node, "modulate", original_modulate, 0.1)


# Spawn animation
func play_spawn_animation():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)


# Death animation (called externally when enemy is defeated)
# Creates a FallenEnemy physics object instead of just disappearing
func play_death_animation():
	# Create fallen enemy debris
	var fallen_enemy_scene = preload("res://objects/FallenEnemy.tscn")
	var fallen_enemy = fallen_enemy_scene.instantiate()
	
	# Initialize with enemy name and level (for display)
	fallen_enemy.initialize(enemy_name, level)
	
	# Position at current enemy location
	fallen_enemy.global_position = global_position
	
	# Set z-index so it renders in front of background but behind the grid
	fallen_enemy.z_index = 1
	
	# Copy the visual appearance (color from BackgroundPanel)
	var original_bg_panel = get_node("TileContainer/BackgroundPanel")
	var fallen_bg_panel = fallen_enemy.get_node("TileContainer/BackgroundPanel")
	var original_style = original_bg_panel.get_theme_stylebox("panel")
	if original_style:
		fallen_bg_panel.add_theme_stylebox_override("panel", original_style)
	
	# Copy the sprite and scale it
	var original_sprite = get_node("TileContainer/EnemySprite")
	var fallen_sprite = fallen_enemy.get_node("TileContainer/EnemySprite")
	fallen_sprite.texture = original_sprite.texture
	fallen_sprite.scale = original_sprite.scale
	fallen_sprite.modulate = original_sprite.modulate
	
	# Add to GameScene (parent of enemy_container) instead of enemy_container
	# This way FallenEnemy can fall down and stack at the bottom
	var parent = get_parent()
	if parent:
		# Get the grandparent (GameScene)
		var grandparent = parent.get_parent()
		if grandparent:
			grandparent.add_child(fallen_enemy)
			print("✅ FallenEnemy '%s' (Lv.%d) added to GameScene" % [enemy_name, level])
		else:
			parent.add_child(fallen_enemy)
			print("⚠️ FallenEnemy added to parent (no grandparent found)")
	else:
		get_tree().root.add_child(fallen_enemy)
		print("⚠️ FallenEnemy added to root (no parent found)")
	
	# Brief flash effect before original enemy disappears
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.1)
	tween.chain().tween_callback(queue_free)


# Called from GameScene._on_enemy_defeated()
func die():
	play_death_animation()
