# PowerChoiceMenu - Power selection overlay for Free Mode
# Allows players to choose which powers will spawn in the game
extends CanvasLayer

# Signals
signal powers_selected(selected_powers: Array)
signal back_pressed()

# Node references
@onready var overlay_background = $OverlayBackground
@onready var menu_container     = $MenuContainer
@onready var title_label        = $MenuContainer/TitleLabel
@onready var powers_grid        = $MenuContainer/ScrollContainer/CenterContainer/PowersGrid
@onready var btn_start          = $MenuContainer/BottomButtons/BtnStart
@onready var btn_back           = $MenuContainer/BottomButtons/BtnBack
@onready var selection_info     = $MenuContainer/SelectionInfo

# Power selection state
var selected_powers: Array = []
var power_buttons: Dictionary = {}


func _ready():
	# Initially hidden
	hide()

	# Connect button signals
	btn_start.button_clicked.connect(_on_start_clicked)
	btn_back.button_clicked.connect(_on_back_clicked)

	# Create power selection buttons
	create_power_buttons()

	update_selection_info()


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
		var label = Label.new()
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
