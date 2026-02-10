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

# Health bar dimensions (same width as sprite displayed size)
const HEALTH_BAR_WIDTH = 384
const HEALTH_BAR_HEIGHT = 16

# Sprite dimensions (876x876 source, scaled to ~384x384)
const SPRITE_SOURCE_SIZE = 876
const SPRITE_DISPLAY_SIZE = 384
const SPRITE_SCALE = float(SPRITE_DISPLAY_SIZE) / float(SPRITE_SOURCE_SIZE)  # ~0.438

# Label font size (reduced by 40%)
const LABEL_FONT_SIZE = 30
const LABEL_FONT_SIZE_SUB_BOSS = 36
const LABEL_FONT_SIZE_BOSS = 42

# Node references (disabled - using get_node() instead to avoid timing issues)
# @onready var idle_sprite: Sprite2D = $ContentContainer/IdleSprite
# @onready var health_bar_container: Node2D = $ContentContainer/HealthBarContainer
# @onready var health_bar_bg: ColorRect = $ContentContainer/HealthBarContainer/HealthBarBg
# @onready var health_bar: ColorRect = $ContentContainer/HealthBarContainer/HealthBar
# @onready var name_label: RichTextLabel = $ContentContainer/NameLabel

# Signals
signal defeated(enemy_level: int)

func _ready():
	pass

# Initialize enemy from EnemyManager data
func initialize(data: Dictionary) -> void:
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
	
	# Get node references (can't use @onready as initialize is called before _ready)
	var idle_sprite_node = get_node("ContentContainer/IdleSprite")
	var health_bar_node = get_node("ContentContainer/HealthBarContainer/HealthBar")
	var level_label_node = get_node("ContentContainer/LevelLabel")
	var name_label_node = get_node("ContentContainer/NameLabel")
	var damage_label_node = get_node("ContentContainer/DamageLabel")
	
	# Load sprite texture and apply glow
	var texture = load_sprite_texture(sprite_path)
	if texture:
		idle_sprite_node.texture = texture
		apply_level_glow()
	
	# Add debug border (only in debug builds)
	if OS.is_debug_build():
		add_debug_border()
	
	# Apply boss-specific styling
	apply_boss_styling()
	
	# Initialize damage label to empty
	damage_label_node.text = ""
	
	# Update visual elements
	update_health_bar()
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

# Apply level-based glow effect using modulate
func apply_level_glow() -> void:
	var idle_sprite_node = get_node("ContentContainer/IdleSprite")
	if TILE_COLORS.has(level):
		idle_sprite_node.modulate = TILE_COLORS[level]
	else:
		idle_sprite_node.modulate = Color.WHITE

# Add debug border around content container (DEBUG ONLY)
func add_debug_border() -> void:
	var content = get_node("ContentContainer")
	
	# Total height: sprite (384) + gap (20) + level label (30) + name label (30) + damage label (30) + health bar (16) = ~510px
	var total_height = 550
	var total_width = SPRITE_DISPLAY_SIZE  # 384px
	
	# Top line
	var top = ColorRect.new()
	top.color = Color(1, 0, 0, 1)
	top.size = Vector2(total_width, 4)
	top.position = Vector2(0, 0)
	content.add_child(top)
	
	# Bottom line
	var bottom = ColorRect.new()
	bottom.color = Color(1, 0, 0, 1)
	bottom.size = Vector2(total_width, 4)
	bottom.position = Vector2(0, total_height - 4)
	content.add_child(bottom)
	
	# Left line
	var left = ColorRect.new()
	left.color = Color(1, 0, 0, 1)
	left.size = Vector2(4, total_height)
	left.position = Vector2(0, 0)
	content.add_child(left)
	
	# Right line
	var right = ColorRect.new()
	right.color = Color(1, 0, 0, 1)
	right.size = Vector2(4, total_height)
	right.position = Vector2(total_width - 4, 0)
	content.add_child(right)

# Apply boss-specific visual styling
func apply_boss_styling() -> void:
	var health_bar_node = get_node("ContentContainer/HealthBarContainer/HealthBar")
	
	if is_sub_boss:
		# Sub-Boss: Orange health bar
		health_bar_node.color = Color("#FF8C00")
	elif is_boss:
		# Boss: Purple health bar with intensified glow
		health_bar_node.color = Color("#8B00FF")
		# Add golden border to health bar background
		var health_bar_bg_node = get_node("ContentContainer/HealthBarContainer/HealthBarBg")
		health_bar_bg_node.color = Color("#FFD700")

# Update HP from EnemyManager (visual only - HP is managed by EnemyManager)
func update_hp(new_hp: int) -> void:
	current_hp = max(0, new_hp)
	update_health_bar()
	flash_damage()
	
	print("💥 Enemy HP updated! HP: %d/%d" % [current_hp, max_hp])
	# Note: die() is NOT called here - EnemyManager handles defeat via enemy_defeated signal


# Update sprite texture (called when health state changes)
func update_sprite(new_sprite_path: String) -> void:
	sprite_path = new_sprite_path
	var texture = load_sprite_texture(sprite_path)
	if texture:
		var idle_sprite_node = get_node("ContentContainer/IdleSprite")
		idle_sprite_node.texture = texture
		# Reapply glow effect to new sprite
		apply_level_glow()
		print("🔄 Enemy sprite updated: %s" % sprite_path)


# Show damage taken in the damage label
func show_damage(damage: int) -> void:
	var damage_label_node = get_node("ContentContainer/DamageLabel")
	damage_label_node.text = "[color=#FF0000]-%d[/color]" % damage
	
	# Clear the label after 1.5 seconds
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func(): damage_label_node.text = "")


# Update health bar width proportionally
func update_health_bar() -> void:
	var health_bar_node = get_node("ContentContainer/HealthBarContainer/HealthBar")
	if max_hp <= 0:
		health_bar_node.offset_right = health_bar_node.offset_left
		return
	
	var health_percent = float(current_hp) / float(max_hp)
	var target_width = HEALTH_BAR_WIDTH * health_percent
	
	# For ColorRect with offset positioning, we change offset_right
	var target_offset_right = health_bar_node.offset_left + target_width
	
	# Smooth tween animation
	var tween = create_tween()
	tween.tween_property(health_bar_node, "offset_right", target_offset_right, 0.3).set_ease(Tween.EASE_OUT)
	
	# Low health warning (< 25%)
	if health_percent < 0.25 and health_percent > 0:
		start_low_health_pulse()

# Update level and name labels separately
func update_display() -> void:
	var level_label_node = get_node("ContentContainer/LevelLabel")
	var name_label_node = get_node("ContentContainer/NameLabel")
	
	level_label_node.bbcode_enabled = true
	name_label_node.bbcode_enabled = true
	
	# Get level color as hex string
	var level_color = TILE_COLORS.get(level, Color.WHITE)
	var color_hex = level_color.to_html(false)
	
	# Add boss prefix and determine font size
	var name_prefix = ""
	var font_size = LABEL_FONT_SIZE  # Base font size (50px)
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
	
	# Level label: "Lv [color=#...]<value>[/color]" - centered
	level_label_node.text = "Lv [color=#%s]%d[/color]" % [color_hex, level]
	
	# Name label: "[Prefix]Name" - centered
	name_label_node.text = "%s%s" % [name_prefix, enemy_name]

# Play spawn animation with bounce effect
func play_spawn_animation() -> void:
	# Play spawn sound effect if available
	if AudioManager.has_method("play_sfx"):
		AudioManager.play_sfx("sfx_enemy_spawn")
	
	# Determine final scale based on boss type
	var final_scale = Vector2(1.0, 1.0)
	if is_sub_boss:
		final_scale = Vector2(1.2, 1.2)
	elif is_boss:
		final_scale = Vector2(1.5, 1.5)
	
	# Create parallel tweens for scale and fade
	var tween = create_tween().set_parallel(true)
	
	# Fade in modulate alpha
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	
	# Sequential scale animation (bounce effect)
	var scale_tween = create_tween()
	var overshoot_scale = final_scale * 1.2
	scale_tween.tween_property(self, "scale", overshoot_scale, 0.3).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(self, "scale", final_scale, 0.1).set_ease(Tween.EASE_IN)

# Pulse health bar when low HP
func start_low_health_pulse() -> void:
	var health_bar_node = get_node("ContentContainer/HealthBarContainer/HealthBar")
	
	# Create pulsing effect
	var tween = create_tween().set_loops()
	tween.tween_property(health_bar_node, "modulate:a", 0.5, 0.5)
	tween.tween_property(health_bar_node, "modulate:a", 1.0, 0.5)

# Flash red when taking damage
func flash_damage() -> void:
	var idle_sprite_node = get_node("ContentContainer/IdleSprite")
	# Store original modulate color
	var original_color = idle_sprite_node.modulate
	
	# Create flash tween
	var tween = create_tween()
	tween.tween_property(idle_sprite_node, "modulate", Color.RED, 0.1)
	tween.tween_property(idle_sprite_node, "modulate", original_color, 0.1)

# Handle enemy defeat
func die() -> void:
	# Calculate score bonus (done in EnemyManager, but we emit level for it)
	var score_bonus = ScoreManager.get_current_score() * level
	
	# Emit defeated signal immediately
	defeated.emit(level)
	
	# Play defeat animation
	var tween = create_tween().set_parallel(true)
	
	# Scale down effect
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.5).set_ease(Tween.EASE_IN)
	
	# Fade out effect
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_IN)
	
	# Queue free after animation
	tween.chain().tween_callback(queue_free)
