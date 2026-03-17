# PowerChoiceMenu - Power selection overlay for Free Mode
# Allows players to choose which powers will spawn in the game
extends CanvasLayer

# Signals
signal powers_selected(selected_powers: Array)
signal back_pressed()

# Node references (created dynamically)
var overlay_background: ColorRect
var menu_container: VBoxContainer
var title_label: Label
var selection_info: Label
var scroll_container: ScrollContainer
var center_container: CenterContainer
var powers_grid: GridContainer
var bottom_buttons: HBoxContainer
var btn_start: Node
var btn_back: Node

# Power selection state
var selected_powers: Array = []
var power_buttons: Dictionary = {}

# Constants
const TITLE_FONT_SIZE     = 48
const INFO_FONT_SIZE      = 24
const SCROLL_HEIGHT       = 1100
const GRID_SEPARATION     = 20
const BUTTON_SEPARATION   = 40
const GRID_COLUMNS        = 4
const BTN_BACK_WIDTH      = 400
const BTN_BACK_HEIGHT     = 91
const BTN_START_WIDTH     = 300
const BTN_START_HEIGHT    = 70


func _ready():
	# Build scene hierarchy
	_setup_scene()

	# Initially hidden
	hide()

	# Connect button signals
	btn_start.button_clicked.connect(_on_start_clicked)
	btn_back.button_clicked.connect(_on_back_clicked)

	# Create power selection buttons
	create_power_buttons()

	update_selection_info()


# Build scene hierarchy programmatically
func _setup_scene():
	# Overlay background
	overlay_background = ColorRect.new()
	overlay_background.name = "OverlayBackground"
	overlay_background.offset_right = 1080.0
	overlay_background.offset_bottom = 1920.0
	overlay_background.color = Color(0, 0, 0, 0.8)
	add_child(overlay_background)

	# Menu container
	menu_container = VBoxContainer.new()
	menu_container.name = "MenuContainer"
	menu_container.offset_left = 90.0
	menu_container.offset_top = 200.0
	menu_container.offset_right = 990.0
	menu_container.offset_bottom = 1700.0
	menu_container.add_theme_constant_override("separation", 20)
	add_child(menu_container)

	# Title label
	title_label = ThemeManager.create_label()
	title_label.name = "TitleLabel"
	title_label.layout_mode = 2
	title_label.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	title_label.text = "FREE MODE - SELECT POWERS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_container.add_child(title_label)

	# Selection info label
	selection_info = ThemeManager.create_label()
	selection_info.name = "SelectionInfo"
	selection_info.layout_mode = 2
	selection_info.add_theme_color_override("font_color", Color(1, 0.843137, 0, 1))
	selection_info.add_theme_font_size_override("font_size", INFO_FONT_SIZE)
	selection_info.text = "No powers selected - All powers will spawn"
	selection_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_container.add_child(selection_info)

	# Scroll container
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.custom_minimum_size = Vector2(0, SCROLL_HEIGHT)
	scroll_container.layout_mode = 2
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	menu_container.add_child(scroll_container)

	# Center container
	center_container = CenterContainer.new()
	center_container.name = "CenterContainer"
	center_container.layout_mode = 2
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(center_container)

	# Powers grid
	powers_grid = GridContainer.new()
	powers_grid.name = "PowersGrid"
	powers_grid.layout_mode = 2
	powers_grid.add_theme_constant_override("h_separation", GRID_SEPARATION)
	powers_grid.add_theme_constant_override("v_separation", GRID_SEPARATION)
	powers_grid.columns = GRID_COLUMNS
	center_container.add_child(powers_grid)

	# Bottom buttons container
	bottom_buttons = HBoxContainer.new()
	bottom_buttons.name = "BottomButtons"
	bottom_buttons.layout_mode = 2
	bottom_buttons.add_theme_constant_override("separation", BUTTON_SEPARATION)
	bottom_buttons.alignment = 1
	menu_container.add_child(bottom_buttons)

	# Back button
	btn_back = load("res://widgets/UIButton.tscn").instantiate()
	btn_back.name = "BtnBack"
	btn_back.layout_mode = 2
	btn_back.custom_minimum_size = Vector2(BTN_BACK_WIDTH, BTN_BACK_HEIGHT)
	btn_back.text = "BACK"
	bottom_buttons.add_child(btn_back)

	# Start button
	btn_start = load("res://widgets/UIButton.tscn").instantiate()
	btn_start.name = "BtnStart"
	btn_start.layout_mode = 2
	btn_start.custom_minimum_size = Vector2(BTN_START_WIDTH, BTN_START_HEIGHT)
	btn_start.text = "START GAME"
	bottom_buttons.add_child(btn_start)


# Create a button for each power
func create_power_buttons():
	# Clear existing buttons
	for child in powers_grid.get_children():
		child.queue_free()

	power_buttons.clear()

	# Create a button for each power
	for power_key in PowerManager.POWERS.keys():
		var power = PowerManager.POWERS[power_key]
		var power_name = power.get("name", power_key)
		var power_type = power.get("type", "none")

		# Create container for icon + label
		var power_container = VBoxContainer.new()
		power_container.custom_minimum_size = Vector2(200, 220)

		# Icon button (clickable)
		var icon_button = TextureButton.new()
		icon_button.custom_minimum_size = Vector2(150, 150)
		icon_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		icon_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		icon_button.ignore_texture_size = true

		var icon_path = "res://assets/icons/power_%s.svg" % power_key
		if ResourceLoader.exists(icon_path):
			var texture = load(icon_path)
			icon_button.texture_normal = texture
			icon_button.texture_pressed = texture
			icon_button.texture_hover = texture

		# Create shader material to color SVG (like Tile.gd)
		var shader_material = ShaderMaterial.new()
		var shader = Shader.new()
		shader.code = """
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	// Apply tint while preserving alpha
	COLOR = vec4(tint_color.rgb, tex.a);
}
"""
		shader_material.shader = shader
		shader_material.set_shader_parameter("tint_color", Color.WHITE)
		icon_button.material = shader_material
		icon_button.set_meta("power_key", power_key)
		icon_button.set_meta("is_selected", false)
		icon_button.pressed.connect(_on_power_icon_clicked.bind(power_key, icon_button))

		# Label
		var label = ThemeManager.create_label()
		label.text = power_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 24)
		label.add_theme_color_override("font_color", Color.WHITE)

		power_container.add_child(icon_button)
		power_container.add_child(label)

		powers_grid.add_child(power_container)
		power_buttons[power_key] = icon_button


# Show the menu
func show_menu():
	visible = true
	selected_powers.clear()

	# Reset all icons to white (not selected)
	for power_key in power_buttons.keys():
		var icon_button = power_buttons[power_key]
		if icon_button.material and icon_button.material is ShaderMaterial:
			icon_button.material.set_shader_parameter("tint_color", Color.WHITE)
		icon_button.set_meta("is_selected", false)

	update_selection_info()


# Hide the menu
func hide_menu():
	visible = false


# Power icon clicked - toggle selection
func _on_power_icon_clicked(power_key: String, icon_button: TextureButton):
	var is_selected = icon_button.get_meta("is_selected", false)

	if is_selected:
		# Deselect - turn white
		if icon_button.material and icon_button.material is ShaderMaterial:
			icon_button.material.set_shader_parameter("tint_color", Color.WHITE)
		icon_button.set_meta("is_selected", false)
		selected_powers.erase(power_key)
	else:
		# Select - turn blue
		if icon_button.material and icon_button.material is ShaderMaterial:
			icon_button.material.set_shader_parameter("tint_color", Color("#00BFFF"))
		icon_button.set_meta("is_selected", true)
		if power_key not in selected_powers:
			selected_powers.append(power_key)

	update_selection_info()


# Update selection info text
func update_selection_info():
	var count = selected_powers.size()
	if count == 0:
		selection_info.text = "No powers selected - All powers will spawn"
		selection_info.add_theme_color_override("font_color", Color("#FFD700"))
	else:
		var spawn_rate = 100.0 / count
		selection_info.text = "%d power(s) selected - Each: %.1f%% spawn rate" % [count, spawn_rate]
		selection_info.add_theme_color_override("font_color", Color("#00FF00"))


# Start button clicked
func _on_start_clicked():
	print("PowerChoiceMenu: Starting with %d selected powers" % selected_powers.size())
	powers_selected.emit(selected_powers)


# Back button clicked
func _on_back_clicked():
	print("PowerChoiceMenu: Back clicked")
	back_pressed.emit()
