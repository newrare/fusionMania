# Context: Input and Controls System

## 📋 Overview
Unified input system supporting keyboard (PC) and touch (mobile) for Fusion Mania.

---

## 🎮 Supported Input Types

### PC (Desktop)
- **Keyboard**: WASD + Arrow keys
- **Mouse**: Hover on buttons
- **Shortcuts**: ESC/SPACE for pause

### Mobile (Touch)
- **Swipe**: Slide in 4 directions
- **Tap**: Touch buttons
- **No hover**: Automatic platform detection

---

## 🔧 Godot Configuration

### project.godot
```ini
[input_devices]
pointing/emulate_touch_from_mouse=true
pointing/emulate_mouse_from_touch=true
```

### Input Map
```gdscript
# Actions defined in Project Settings > Input Map

move_up:      W, ↑
move_down:    S, ↓
move_left:    A, ←
move_right:   D, →
pause:        ESC, SPACE
```

---

## 📱 Platform Detection

### ToolsManager.gd
```gdscript
# managers/ToolsManager.gd
extends Node

var is_mobile: bool = false

func _ready():
    detect_platform()

func detect_platform():
    var os_name = OS.get_name()
    is_mobile = os_name in ["Android", "iOS"]

    print("Platform detected: %s (Mobile: %s)" % [os_name, is_mobile])

func get_is_mobile() -> bool:
    return is_mobile
```

---

## 🎯 Swipe System

### Swipe Detection
```gdscript
# scenes/GameScene.gd

var swipe_start_position: Vector2 = Vector2.ZERO
var is_swiping: bool = false
var min_swipe_distance: float = 50.0

func _input(event):
    # Start swipe
    if event is InputEventScreenTouch and event.pressed:
        swipe_start_position = event.position
        is_swiping = true

    # End swipe
    elif event is InputEventScreenTouch and not event.pressed and is_swiping:
        var swipe_end_position = event.position
        var swipe_vector = swipe_end_position - swipe_start_position

        # Check minimum distance
        if swipe_vector.length() >= min_swipe_distance:
            process_swipe(swipe_vector)

        is_swiping = false

func process_swipe(swipe_vector: Vector2):
    # Determine dominant direction
    var angle = swipe_vector.angle()
    var direction: GridManager.Direction

    # Convert angle to direction
    if abs(angle) < PI / 4:
        direction = GridManager.Direction.RIGHT
    elif abs(angle) > 3 * PI / 4:
        direction = GridManager.Direction.LEFT
    elif angle > 0:
        direction = GridManager.Direction.DOWN
    else:
        direction = GridManager.Direction.UP

    # Send movement
    GridManager.process_movement(direction)
```

---

## ⌨️ Keyboard Input

### Keyboard Detection
```gdscript
# scenes/GameScene.gd

func _unhandled_input(event):
    if event.is_action_pressed("move_up"):
        GridManager.process_movement(GridManager.Direction.UP)
    elif event.is_action_pressed("move_down"):
        GridManager.process_movement(GridManager.Direction.DOWN)
    elif event.is_action_pressed("move_left"):
        GridManager.process_movement(GridManager.Direction.LEFT)
    elif event.is_action_pressed("move_right"):
        GridManager.process_movement(GridManager.Direction.RIGHT)
    elif event.is_action_pressed("pause"):
        toggle_pause()
```

---

## 🎵 Adaptive Sounds

### Buttons with Platform Detection
```gdscript
# widgets/UIButton.gd
extends Button

func _ready():
    # Connect signals based on platform
    if ToolsManager.get_is_mobile():
        # Mobile: sound on click only
        pressed.connect(_on_button_pressed)
    else:
        # PC: hover + click
        mouse_entered.connect(_on_button_hover)
        pressed.connect(_on_button_pressed)

func _on_button_hover():
    AudioManager.play_sfx_button_hover()

func _on_button_pressed():
    AudioManager.play_sfx_button_click()
```

---

## 🔄 Unified System

### InputHandler Class
```gdscript
# managers/InputHandler.gd (optional, to centralize)
class_name InputHandler
extends Node

signal direction_input(direction: GridManager.Direction)
signal pause_input()

var swipe_start: Vector2
var is_swiping: bool = false
const MIN_SWIPE_DIST = 50.0

func _input(event):
    # Swipe/Touch
    if event is InputEventScreenTouch:
        handle_touch(event)

    # Mouse drag (for PC testing)
    elif event is InputEventMouseButton:
        if ToolsManager.get_is_mobile():
            return  # Ignore on mobile
        handle_mouse_drag(event)

func _unhandled_input(event):
    # Keyboard
    if event.is_action_pressed("move_up"):
        direction_input.emit(GridManager.Direction.UP)
    elif event.is_action_pressed("move_down"):
        direction_input.emit(GridManager.Direction.DOWN)
    elif event.is_action_pressed("move_left"):
        direction_input.emit(GridManager.Direction.LEFT)
    elif event.is_action_pressed("move_right"):
        direction_input.emit(GridManager.Direction.RIGHT)
    elif event.is_action_pressed("pause"):
        pause_input.emit()

func handle_touch(event: InputEventScreenTouch):
    if event.pressed:
        swipe_start = event.position
        is_swiping = true
    elif is_swiping:
        var swipe_end = event.position
        var swipe_vec = swipe_end - swipe_start

        if swipe_vec.length() >= MIN_SWIPE_DIST:
            emit_swipe_direction(swipe_vec)

        is_swiping = false

func emit_swipe_direction(swipe_vector: Vector2):
    var angle = swipe_vector.angle()
    var dir: GridManager.Direction

    if abs(angle) < PI / 4:
        dir = GridManager.Direction.RIGHT
    elif abs(angle) > 3 * PI / 4:
        dir = GridManager.Direction.LEFT
    elif angle > 0:
        dir = GridManager.Direction.DOWN
    else:
        dir = GridManager.Direction.UP

    direction_input.emit(dir)
```

---

## 🎯 Pause Management

### Toggle Pause
```gdscript
# scenes/GameScene.gd

var is_paused: bool = false

func toggle_pause():
    is_paused = !is_paused

    if is_paused:
        # Open title menu (auto-saves)
        show_overlay(title_menu)
        # Save game
        SaveManager.auto_save()
    else:
        # Resume
        hide_all_overlays()

func _unhandled_input(event):
    if event.is_action_pressed("pause"):
        toggle_pause()
```

---

## 🖱️ UI Input

### Custom Button
```gdscript
# widgets/UIButton.gd
extends Button

signal button_clicked()

var hover_scale: Vector2 = Vector2(1.05, 1.05)
var normal_scale: Vector2 = Vector2.ONE

func _ready():
    connect_signals()

    # Initial style
    pivot_offset = size / 2

func connect_signals():
    if not ToolsManager.get_is_mobile():
        # PC: hover effects
        mouse_entered.connect(_on_hover_start)
        mouse_exited.connect(_on_hover_end)

    # All: click
    pressed.connect(_on_clicked)

func _on_hover_start():
    AudioManager.play_sfx_button_hover()

    var tween = create_tween()
    tween.tween_property(self, "scale", hover_scale, 0.1)

func _on_hover_end():
    var tween = create_tween()
    tween.tween_property(self, "scale", normal_scale, 0.1)

func _on_clicked():
    AudioManager.play_sfx_button_click()

    # Click animation
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
    tween.tween_property(self, "scale", normal_scale, 0.05)

    button_clicked.emit()
```

---

## 🧪 Debug Mode

### Input Testing
```gdscript
# Debug overlay to test inputs
extends CanvasLayer

@onready var debug_label = $DebugLabel

func _input(event):
    if OS.is_debug_build():
        if event is InputEventScreenTouch:
            debug_label.text = "Touch: %s (pressed: %s)" % [event.position, event.pressed]
        elif event is InputEventKey:
            debug_label.text = "Key: %s" % event.as_text()
```

---

## 📋 Input State Management

### Block Input During Animations
```gdscript
# managers/GameManager.gd

var can_accept_input: bool = true

func block_input():
    can_accept_input = false

func unblock_input():
    can_accept_input = true

# In GameScene.gd
func _input(event):
    if not GameManager.can_accept_input:
        return

    # Process input...
```

---

## ✅ Implementation Checklist

- [ ] Configure Input Map in project.godot
- [ ] Enable emulate_touch_from_mouse
- [ ] Implement platform detection in ToolsManager
- [ ] Create swipe system in GameScene
- [ ] Add keyboard support
- [ ] Create UIButton with adaptive sounds
- [ ] Implement pause system
- [ ] Test swipe in all directions
- [ ] Test keyboard (WASD + arrows)
- [ ] Test touch buttons vs mouse
- [ ] Verify input blocking during animations

---

## 🐛 Common Debug Issues

### Swipe Not Working
```gdscript
# Check that emulate_touch_from_mouse is enabled
print(ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"))
```

### Double Input (keyboard + swipe)
```gdscript
# Add platform check
if ToolsManager.get_is_mobile() and event is InputEventKey:
    return  # Ignore keyboard on mobile
```

### Button Not Responding
```gdscript
# Check button is not disabled
button.disabled = false

# Check signal connections
print("Signals connected: ", button.mouse_entered.is_connected(_on_hover))
```
