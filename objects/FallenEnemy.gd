# FallenEnemy - Debris after enemy defeat
# Falls to bottom of screen and stacks with other defeated enemies
# Uses RigidBody2D for proper collision with rotation and center of gravity
extends RigidBody2D

# Physics constants
const GRAVITY_SCALE = 3.0  # Multiplier for global gravity (faster fall)
const ANGULAR_DAMP = 2.0  # Rotation slowdown
const LINEAR_DAMP = 0.5  # Movement slowdown
const IMPULSE_STRENGTH = 200.0  # Initial random impulse strength
const IMPULSE_UP_MIN = -150.0  # Minimum upward impulse
const IMPULSE_UP_MAX = -50.0  # Maximum upward impulse
const INITIAL_ROTATION_IMPULSE = 3.0  # Initial rotation speed range

# Hitbox size (matches visual 240px)
const HITBOX_SIZE = 240  # Square hitbox size
const HALF_SIZE = 120  # Half of hitbox for position calculations

# Enemy identity
var enemy_name: String = ""
var enemy_level: int = 2
var enemy_color: Color = Color.WHITE

# Ground tracking
var ground_body: StaticBody2D = null

# Node references (created dynamically)
var collision_shape: CollisionShape2D
var tile_container: Control
var background_panel: Panel
var enemy_sprite: Sprite2D
var name_label: Label


func _ready():
	# Add to fallen_enemy group
	add_to_group("fallen_enemy")

	# Build scene hierarchy if not already done
	if not tile_container:
		_setup_scene()
	
	# Configure RigidBody2D physics
	gravity_scale = GRAVITY_SCALE
	angular_damp = ANGULAR_DAMP
	linear_damp = LINEAR_DAMP
	contact_monitor = true
	max_contacts_reported = 10
	
	# Set center of mass to center (default, but explicit)
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_AUTO
	
	# Create physics material for bounce and friction
	var physics_mat = PhysicsMaterial.new()
	physics_mat.bounce = 0.15  # Low bounce for stable stacking
	physics_mat.friction = 0.6  # Friction for realistic sliding
	physics_material_override = physics_mat
	
	print("🪨 FallenEnemy '%s' spawned at %s" % [enemy_name, global_position])
	
	# Random initial impulse (horizontal and upward)
	# So enemies don't always fall in same place
	var impulse_x = randf_range(-IMPULSE_STRENGTH, IMPULSE_STRENGTH)
	var impulse_y = randf_range(IMPULSE_UP_MIN, IMPULSE_UP_MAX)
	linear_velocity = Vector2(impulse_x, impulse_y)
	
	# Random initial rotation velocity
	angular_velocity = randf_range(-INITIAL_ROTATION_IMPULSE, INITIAL_ROTATION_IMPULSE)
	
	# Update name label if set
	_update_name_label()
	
	# Create ground if needed
	_create_ground()


# Build scene hierarchy programmatically
func _setup_scene():
	# Collision shape with rectangle
	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.position = Vector2(0, 0)
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(HITBOX_SIZE, HITBOX_SIZE)
	collision_shape.shape = rect_shape
	add_child(collision_shape)

	# Tile container
	tile_container = Control.new()
	tile_container.name = "TileContainer"
	tile_container.clip_contents = true
	tile_container.custom_minimum_size = Vector2(HITBOX_SIZE, HITBOX_SIZE)
	tile_container.layout_mode = 3
	tile_container.anchors_preset = 0
	tile_container.offset_left = -HALF_SIZE
	tile_container.offset_top = -HALF_SIZE
	tile_container.offset_right = HALF_SIZE
	tile_container.offset_bottom = HALF_SIZE
	add_child(tile_container)

	# Background panel
	background_panel = Panel.new()
	background_panel.name = "BackgroundPanel"
	background_panel.layout_mode = 1
	background_panel.anchors_preset = Control.PRESET_FULL_RECT
	background_panel.anchor_right = 1.0
	background_panel.anchor_bottom = 1.0
	background_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	background_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	tile_container.add_child(background_panel)

	# Enemy sprite
	enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySprite"
	enemy_sprite.z_index = 1
	enemy_sprite.position = Vector2(HALF_SIZE, HALF_SIZE)
	enemy_sprite.scale = Vector2(0.273973, 0.273973)
	tile_container.add_child(enemy_sprite)

	# Name label (hidden by default)
	name_label = ThemeManager.create_label()
	name_label.name = "NameLabel"
	name_label.visible = false
	name_label.layout_mode = 1
	name_label.anchors_preset = Control.PRESET_CENTER_BOTTOM
	name_label.anchor_left = 0.5
	name_label.anchor_top = 1.0
	name_label.anchor_right = 0.5
	name_label.anchor_bottom = 1.0
	name_label.offset_left = -100.0
	name_label.offset_top = -40.0
	name_label.offset_right = 100.0
	name_label.offset_bottom = 0.0
	name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	name_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	name_label.add_theme_color_override("font_color", ThemeManager.get_color("white"))
	name_label.add_theme_color_override("font_outline_color", ThemeManager.get_color("black"))
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.clip_text = true
	tile_container.add_child(name_label)


# Initialize with enemy name and level for display
func initialize(p_name, p_level):
	# Ensure scene is setup (in case called before _ready)
	if not tile_container:
		_setup_scene()

	enemy_name = p_name
	enemy_level = p_level
	enemy_color = ThemeManager.get_level_color(p_level)
	_update_name_label()


# Update the name label with enemy name and color
func _update_name_label():
	if name_label and enemy_name != "":
		name_label.text = enemy_name
		name_label.add_theme_color_override("font_color", enemy_color)
		name_label.add_theme_color_override("font_outline_color", Color.BLACK)
		name_label.visible = true


# Apply small bounce when player moves (makes fallen enemies react slightly)
func apply_movement_bounce(direction):
	# Determine impulse direction based on player movement
	# Direction values: UP=0, DOWN=1, LEFT=2, RIGHT=3 (from GridManager.Direction enum)
	var impulse = Vector2.ZERO
	
	match direction:
		0: # UP
			impulse = Vector2(randf_range(-50, 50), -150)  # Push up
		1: # DOWN
			impulse = Vector2(randf_range(-50, 50), 150)   # Push down
		2: # LEFT
			impulse = Vector2(-150, randf_range(-50, 50))  # Push left
		3: # RIGHT
			impulse = Vector2(150, randf_range(-50, 50))   # Push right
	
	apply_central_impulse(impulse)
	
	# Small random rotation impulse
	var rotation_impulse = randf_range(-1.0, 1.0)
	apply_torque_impulse(rotation_impulse * 200.0)


# Create a static ground body at bottom of screen
func _create_ground():
	# Check if ground already exists
	var scene_root = get_parent()
	if not scene_root:
		return
	
	ground_body = scene_root.get_node_or_null("FallenEnemyGround")
	if ground_body:
		return  # Ground already exists
	
	# Create ground StaticBody2D
	ground_body = StaticBody2D.new()
	ground_body.name = "FallenEnemyGround"
	
	# Position at bottom of screen
	var viewport_size = get_viewport().get_visible_rect().size
	ground_body.position = Vector2(viewport_size.x / 2, viewport_size.y + 50)
	
	# Create collision shape (wide rectangle)
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(viewport_size.x * 2, 100)  # Very wide
	collision_shape.shape = rect_shape
	
	# Physics material for ground
	var ground_mat = PhysicsMaterial.new()
	ground_mat.friction = 0.8
	ground_mat.bounce = 0.1
	ground_body.physics_material_override = ground_mat
	
	ground_body.add_child(collision_shape)
	scene_root.add_child(ground_body)
	
	print("🌍 Created ground at y=%.0f" % ground_body.position.y)


# Called during physics step - snap rotation when nearly sleeping
func _integrate_forces(state):
	# If nearly at rest and nearly upright, snap to upright
	if state.linear_velocity.length() < 10.0 and abs(state.angular_velocity) < 0.1:
		var current_rotation = fmod(state.transform.get_rotation(), TAU)
		# Normalize to -PI to PI
		if current_rotation > PI:
			current_rotation -= TAU
		elif current_rotation < -PI:
			current_rotation += TAU
		
		# If close to upright (0, PI/2, PI, -PI/2), snap to it
		var snap_angle = round(current_rotation / (PI/2)) * (PI/2)
		if abs(current_rotation - snap_angle) < 0.1:  # Within ~6 degrees
			state.transform = Transform2D(snap_angle, state.transform.origin)
			state.angular_velocity = 0.0
