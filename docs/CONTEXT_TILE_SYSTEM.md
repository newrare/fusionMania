# Context: Tile System

## 📋 Overview
Tiles are the basic objects of Fusion Mania game. Each tile has a value (2, 4, 8, ..., 2048), a color, and potentially a power.

---

## 🎨 Tile Structure

### Main Properties
```gdscript
var value: int          = 2      # Tile value (2, 4, 8, ..., 2048)
var power_type: String  = ""     # Power type (empty if none)
var grid_position: Vector2i      # Position in grid (x, y)
var is_frozen: bool     = false  # If frozen by Ice power
var freeze_turns: int   = 0      # Remaining freeze turns
```

### Visual Nodes
```
Tile (Control)
├── Background (Panel, z-index=0)     # Neon glow border + attenuated background
├── PowerIcon (TextureRect, z-index=1) # Power icon (top-right, green=bonus, red=malus)
├── ValueLabel (Label, z-index=2)     # Displays value (2, 4, 8... - font scales with value)
└── PowerLabel (Label, z-index=2)     # Power name (bottom center)
```

---

## 🌈 Tile Colors (Neon Glow)

The tile colors are used for the neon glow border effect. The background uses the same color but heavily attenuated (15% brightness).

```gdscript
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

# Styling constants
const BORDER_RADIUS = 20
const GLOW_SIZE = 8
const BACKGROUND_ATTENUATION = 0.15

# Font sizes (scales with value, fits within tile)
const VALUE_FONT_SIZES = {
    2:    48,
    4:    52,
    8:    56,
    16:   60,
    32:   64,
    64:   68,
    128:  56,   # 3 digits
    256:  56,
    512:  56,
    1024: 48,   # 4 digits
    2048: 48
}

# Power icon colors
const BONUS_COLOR = Color("#00FF00")  # Green
const MALUS_COLOR = Color("#FF0000")  # Red
```

---

## ⚡ Power System

### Power Assignment
- Powers are randomly assigned when creating tile
- Each power has defined spawn rate (see PowerManager)
- A tile can have a power or be empty

### Power Icons (SVG only)
Icons are displayed in the top-right corner with color modulation:
- **Green** for bonus powers
- **Red** for malus powers

```
assets/icons/
├── power_fire_h.svg          # Fire horizontal (bonus)
├── power_fire_v.svg          # Fire vertical (bonus)
├── power_fire_cross.svg      # Fire cross (bonus)
├── power_bomb.svg            # Bomb (bonus)
├── power_ice.svg             # Ice (malus)
├── power_switch_h.svg        # Switch horizontal (bonus)
├── power_switch_v.svg        # Switch vertical (bonus)
├── power_teleport.svg        # Teleport (bonus)
├── power_expel_h.svg         # Expel horizontal (bonus)
├── power_expel_v.svg         # Expel vertical (bonus)
├── power_freeze_up.svg       # Freeze up (malus)
├── power_freeze_down.svg     # Freeze down (malus)
├── power_freeze_left.svg     # Freeze left (malus)
├── power_freeze_right.svg    # Freeze right (malus)
├── power_lightning.svg       # Lightning (bonus)
├── power_nuclear.svg         # Nuclear (bonus)
├── power_blind.svg           # Blind (malus)
├── power_bowling.svg         # Bowling (bonus)
└── power_ads.svg             # Ads (malus)
```

---

## 🎭 Animations

### Spawn Animation
```gdscript
func spawn_animation():
    # Scale from 0 to 1
    scale = Vector2.ZERO
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2.ONE, 0.2)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_BACK)
```

### Merge Animation
```gdscript
func merge_animation():
    # Scale up then down
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
    tween.tween_property(self, "scale", Vector2.ONE, 0.1)
```

### Move Animation
```gdscript
func move_to_position(target_pos: Vector2, duration: float = 0.2):
    var tween = create_tween()
    tween.tween_property(self, "position", target_pos, duration)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_QUAD)
```

### Destroy Animation
```gdscript
func destroy_animation():
    # Fade out and scale down
    var tween = create_tween()
    tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
    tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)
    tween.tween_callback(queue_free)
```

### Freeze Effect
```gdscript
func apply_freeze_effect():
    # Blue tint overlay
    modulate = Color(0.7, 0.7, 1.0, 1.0)

func remove_freeze_effect():
    modulate = Color.WHITE
```

---

## 📏 Sizing

### Recommended Tile Size
```gdscript
const TILE_SIZE = 240  # pixels (for 4x4 grid on 1080px width)
const TILE_SPACING = 20  # pixels between tiles
```

### Position Calculation
```gdscript
func calculate_screen_position(grid_pos: Vector2i) -> Vector2:
    var x = TILE_SPACING + grid_pos.x * (TILE_SIZE + TILE_SPACING)
    var y = TILE_SPACING + grid_pos.y * (TILE_SIZE + TILE_SPACING)
    return Vector2(x, y)
```

---

## 🔧 Main Methods

### Initialization
```gdscript
func initialize(val: int, power: String = "", grid_pos: Vector2i = Vector2i.ZERO):
    value = val
    power_type = power
    grid_position = grid_pos
    
    update_visual()
    spawn_animation()
```

### Visual Update
```gdscript
func update_visual():
    # Update color
    if background:
        background.color = TILE_COLORS.get(value, Color.WHITE)
    
    # Update label
    if value_label:
        value_label.text = str(value)
    
    # Update power icon
    if power_icon and power_type != "":
        power_icon.texture = load("res://assets/icons/power_%s.png" % power_type)
        power_icon.visible = true
    else:
        power_icon.visible = false
```

### Tile Fusion
```gdscript
func can_merge_with(other_tile: Tile) -> bool:
    return value == other_tile.value and not is_frozen and not other_tile.is_frozen

func merge_with(other_tile: Tile) -> Dictionary:
    # Double value
    var new_value = value * 2
    
    # Determine power to keep
    var new_power = PowerManager.resolve_power_merge(power_type, other_tile.power_type)
    
    # Return new values
    return {
        "value": new_value,
        "power": new_power,
        "power_activated": (power_type == other_tile.power_type and power_type != "")
    }
```

---

## 🎮 Signals

```gdscript
signal tile_clicked(tile: Tile)
signal tile_moved(from: Vector2i, to: Vector2i)
signal tile_merged(tile: Tile, value: int)
signal tile_destroyed(tile: Tile)
```

---

## 🧪 Usage Example

```gdscript
# Create tile
var tile = preload("res://objects/Tile.tscn").instantiate()
tile.initialize(2, "fire_h", Vector2i(0, 0))
add_child(tile)

# Move tile
tile.move_to_position(Vector2(100, 100))

# Merge two tiles
if tile1.can_merge_with(tile2):
    var merge_result = tile1.merge_with(tile2)
    tile1.initialize(merge_result.value, merge_result.power, tile1.grid_position)
    tile2.destroy_animation()
```

---

## 💾 Tile.tscn File Structure

```
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://objects/Tile.gd" id="1"]
[ext_resource type="Texture2D" path="res://assets/images/tile_base.png" id="2"]

[node name="Tile" type="Control"]
custom_minimum_size = Vector2(240, 240)
layout_mode = 3
anchors_preset = 0
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
color = Color(1, 1, 1, 1)

[node name="ValueLabel" type="Label" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -50.0
offset_top = -25.0
offset_right = 50.0
offset_bottom = 25.0
theme_override_font_sizes/font_size = 48
text = "2"
horizontal_alignment = 1
vertical_alignment = 1

[node name="PowerIcon" type="TextureRect" parent="."]
visible = false
layout_mode = 1
anchors_preset = 3
anchor_left = 1.0
anchor_top = 1.0
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = -60.0
offset_top = -60.0
grow_horizontal = 0
grow_vertical = 0
expand_mode = 1
stretch_mode = 5
```

---

## 🐛 Debug

```gdscript
func _to_string() -> String:
    return "Tile[value=%d, power=%s, pos=%s, frozen=%s]" % [
        value, power_type, grid_position, is_frozen
    ]
```

---

## ✅ Implementation Checklist

- [ ] Create `objects/Tile.gd` with all properties
- [ ] Create `objects/Tile.tscn` with visual structure
- [ ] Implement animations (spawn, merge, move, destroy)
- [ ] Implement `update_visual()` with dynamic colors
- [ ] Implement `can_merge_with()` and `merge_with()`
- [ ] Add freeze effects (freeze/unfreeze)
- [ ] Connect power icons
- [ ] Test each animation individually
- [ ] Test fusions with different powers
