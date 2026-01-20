# Context: Godot Project Configuration

## 📋 Overview
Complete Godot 4.5 project configuration for Fusion Mania.

---

## 📁 Folder Structure

```
fusionMania/
├── project.godot               # Main configuration
├── export_presets.cfg          # Export configuration
├── .gitignore                  # Git ignored files
│
├── assets/                     # Game resources
│   ├── sounds/                 # Audio files
│   │   ├── music_background.mp3
│   │   ├── sfx_move.wav
│   │   ├── sfx_fusion.wav
│   │   ├── sfx_power.wav
│   │   ├── sfx_game_over.mp3
│   │   ├── sfx_win.mp3
│   │   ├── sfx_button_hover.wav
│   │   └── sfx_button_click.wav
│   │
│   ├── images/                 # Textures and sprites
│   │   ├── background.png
│   │   ├── grid_cell.png
│   │   └── tile_base.png
│   │
│   └── icons/                  # Power icons
│       ├── power_fire_h.png
│       ├── power_fire_v.png
│       ├── power_bomb.png
│       └── ... (20 icons)
│
├── managers/                   # Singletons (AutoLoad)
│   ├── AudioManager.gd
│   ├── LanguageManager.gd
│   ├── ScoreManager.gd
│   ├── GameManager.gd
│   ├── GridManager.gd
│   ├── PowerManager.gd
│   ├── SaveManager.gd
│   └── ToolsManager.gd
│
├── objects/                    # Game objects
│   ├── Tile.gd
│   ├── Tile.tscn
│   ├── Grid.gd
│   └── Grid.tscn
│
├── overlays/                   # Modal menus
│   ├── TitleMenu.gd
│   ├── TitleMenu.tscn
│   ├── OptionsMenu.gd
│   ├── OptionsMenu.tscn
│   ├── RankingMenu.gd
│   ├── RankingMenu.tscn
│   ├── GameOverMenu.gd
│   └── GameOverMenu.tscn
│
├── widgets/                    # Reusable UI components
│   ├── UIButton.gd
│   └── UIButton.tscn
│
├── visuals/                    # Visual effects
│   └── PowerEffect.gd
│
├── scenes/                     # Main scenes
│   ├── GameScene.gd
│   └── GameScene.tscn
│
├── docs/                       # Documentation
│   ├── CONTEXT_*.md            # Project context files
│   └── PROMPTING_GUIDE.md      # AI prompting guide
│
├── tests/                      # Test and debug files
│   ├── test_setup.gd           # Test scripts
│   ├── test_setup.tscn         # Test scenes
│   └── verify_setup.sh         # Verification scripts
│
└── drafts/                     # Planning and drafts
    ├── DEV_PLAN.md             # Development plan
    ├── TODO.md                 # Task tracking
    └── PHASE_*.md              # Phase guides
```

---

## ⚙️ project.godot Configuration

### General Settings
```ini
config_version=5

[application]
config/name="Fusion Mania"
config/description="A unique twist on 2048 with magical powers!"
run/main_scene="res://scenes/GameScene.tscn"
config/features=PackedStringArray("4.5", "Mobile")
config/icon="res://assets/icons/icon.png"
```

### AutoLoad (Managers)
```ini
[autoload]
AudioManager="*res://managers/AudioManager.gd"
LanguageManager="*res://managers/LanguageManager.gd"
ScoreManager="*res://managers/ScoreManager.gd"
GameManager="*res://managers/GameManager.gd"
GridManager="*res://managers/GridManager.gd"
PowerManager="*res://managers/PowerManager.gd"
SaveManager="*res://managers/SaveManager.gd"
ToolsManager="*res://managers/ToolsManager.gd"
```

### Display
```ini
[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
window/size/mode=2
window/size/resizable=true
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
window/handheld/orientation=1
```

### Touch Input
```ini
[input_devices]
pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=true
```

### Internationalization
```ini
[internationalization]
locale/translations=PackedStringArray()
locale/locale_filter_mode=0
```

### Rendering
```ini
[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="gl_compatibility"
textures/vram_compression/import_etc2_astc=true
```

### Physics (for animations)
```ini
[physics]
common/physics_ticks_per_second=60
```

---

## 🎮 Input Map

### Game Actions
```ini
[input]

# Movements
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"echo":false,"script":null)]
}

move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"echo":false,"script":null)]
}

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"echo":false,"script":null)]
}

move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"echo":false,"script":null)]
}

# Menu
pause={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194305,"key_label":0,"unicode":0,"echo":false,"script":null), Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":0,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":32,"key_label":0,"unicode":0,"echo":false,"script":null)]
}
```

---

## 📱 Mobile Configuration

### Android
```ini
[android]
gradle_build/use_gradle_build=true
gradle_build/min_sdk=21
gradle_build/target_sdk=33
permissions/internet=true
permissions/access_network_state=true
```

### iOS
```ini
[ios]
privacy/camera_usage_description=""
privacy/microphone_usage_description=""
```

---

## 🎨 UI Theme

### Tile Color Configuration
```gdscript
# Colors for tiles by value
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
```

---

## 🔧 Git Configuration Files

### .gitignore
```gitignore
# Godot
.import/
*.import
.godot/
export.cfg
export_presets.cfg

# OS
.DS_Store
Thumbs.db

# Build
*.apk
*.aab
*.ipa

# Logs
logs/
*.log
```

---

## 📋 Configuration Checklist

- [ ] Create `project.godot` file
- [ ] Configure AutoLoads
- [ ] Define Input Map
- [ ] Create folder structure
- [ ] Configure display (resolution, orientation)
- [ ] Enable touch support
- [ ] Configure mobile renderer
- [ ] Define main scene
- [ ] Create placeholder files for assets
- [ ] Test that project opens in Godot 4.5

---

## 🧪 Configuration Test

```gdscript
# TestScene.gd
extends Node

func _ready():
    print("=== Fusion Mania Configuration Test ===")
    
    # Test AutoLoads
    print("AudioManager: ", AudioManager != null)
    print("LanguageManager: ", LanguageManager != null)
    print("ScoreManager: ", ScoreManager != null)
    
    # Test Display
    print("Viewport size: ", get_viewport().size)
    print("Window size: ", DisplayServer.window_get_size())
    
    # Test Input
    print("Touch enabled: ", ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"))
    
    print("=== Test Complete ===")
```
