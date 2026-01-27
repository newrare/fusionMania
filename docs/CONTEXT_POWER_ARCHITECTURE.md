# Context: Power Activation Architecture

## 📋 Overview

This document describes the architecture and flow for power activation in Fusion Mania. It defines the separation of responsibilities between classes and the execution sequence for power effects.

---

## 🎯 Power Activation Flow

When a power is activated (two tiles with the same power merge), the following sequence occurs:

### 1. Power Trigger (Immediate)
```
GridManager.process_fusions() → PowerManager.activate_power()
```

### 2. Target Determination
```
PowerManager.activate_power():
  1. Determine emitter tile (tile that triggered the power)
  2. Determine target tiles (tiles that will be affected)
  3. Return emitter + targets for visual effects
```

### 3. Visual Effects (Parallel, max 2 seconds)
The following effects play **simultaneously**:
- **Emitter tile visual**: Blue label, blinking power icon (via `Tile.start_emitter_effect()`)
- **Target tiles visual**: Blinking/highlighting (via `Tile.start_target_effect()`)
- **Power animation**: Sprites/particles (via `PowerEffect.play_power_animation()`)

### 4. Power Effects (After animations)
Once visual animations complete:
- Apply actual effects (destroy tiles, swap positions, add overlays)
- Power effects handled by `GridManager` (tile manipulation) or `GameManager` (state changes)

### 5. Persistent Effects (Multi-turn powers)
For powers that last multiple movements (blind, freeze_up, etc.):
- State/counter stored in `GameManager` (e.g., `blind_turns_remaining`, `frozen_directions`)
- Counter decremented after each move
- If same power activated again: reset counter to default value
- On new game: reset all persistent power states

---

## 🔄 Early Interruption Handling

If the player makes a new move **before** animations complete:

1. **Cancel/skip all running animations** (tweens, sprites)
2. **Immediately apply power effects** (destroy/move tiles)
3. **Process the new movement** normally

Implementation:
```gdscript
# In PowerManager or GridManager
var current_power_tweens: Array = []  # Track all active tweens
var pending_power_effects: Callable   # Store effect to apply

func interrupt_power_animation():
    # Kill all active tweens
    for tween in current_power_tweens:
        if is_instance_valid(tween):
            tween.kill()
    current_power_tweens.clear()
    
    # Apply pending effects immediately
    if pending_power_effects:
        pending_power_effects.call()
        pending_power_effects = null
```

---

## 📁 Class Responsibilities

### GameManager.gd
**Role**: Central game state and persistent power state management

```gdscript
# Game states
var current_state: GameState

# Persistent power states (reset on new game)
var blind_turns_remaining: int = 0
var is_blind_active: bool = false
var frozen_directions: Dictionary = {}  # {Direction: turns_remaining}

# Methods
func reset_power_states():
    """Reset all persistent power states (called on new game)"""
    blind_turns_remaining = 0
    is_blind_active = false
    frozen_directions.clear()

func decrement_power_counters():
    """Called after each move to update power counters"""

func activate_blind(turns: int):
    """Activate or reset blind mode"""
    if is_blind_active:
        # Already active: reset counter
        blind_turns_remaining = turns
    else:
        is_blind_active = true
        blind_turns_remaining = turns
    blind_started.emit()

func freeze_direction(direction: Direction, turns: int):
    """Freeze a movement direction for N turns"""
```

### GridManager.gd
**Role**: Grid state, tile movements, fusions, and tile manipulation

```gdscript
# Grid state
var grid: Array[Array]
var can_move: bool

# Methods
func process_movement(direction: Direction) -> bool:
    """Process player movement input"""
    
func process_fusions(fusions: Array):
    """Process all fusions and trigger powers"""
    
func destroy_tile(tile):
    """Remove tile from grid and trigger destroy animation"""
    
func swap_tiles(tile1, tile2):
    """Swap two tiles positions in grid"""
    
func get_tiles_in_row(row: int) -> Array:
    """Get all tiles in a specific row"""
    
func get_tiles_in_column(col: int) -> Array:
    """Get all tiles in a specific column"""
    
func get_adjacent_tiles(position: Vector2i) -> Array:
    """Get all tiles adjacent to a position (8 directions)"""
```

### PowerManager.gd
**Role**: Power business logic, target determination, animation orchestration

```gdscript
# Animation tracking (for interruption)
var current_power_tweens: Array = []
var pending_effects: Callable = null
var is_power_animating: bool = false

# Signals
signal power_activated(power_type: String, tile)
signal power_effect_completed(power_type: String)
signal power_animation_started()
signal power_animation_interrupted()

# Main entry point
func activate_power(power_type: String, emitter_tile, grid_manager):
    """Main power activation - determines targets and launches effects"""
    
# Target determination (one per power type or generic)
func get_power_targets(power_type: String, emitter_tile, grid_manager) -> Dictionary:
    """Returns {emitter: Tile, targets: Array[Tile]}"""
    
func _get_fire_h_targets(emitter_tile, grid_manager) -> Array:
func _get_fire_v_targets(emitter_tile, grid_manager) -> Array:
func _get_bomb_targets(emitter_tile, grid_manager) -> Array:
# ... etc for each power

# Animation orchestration
func _start_power_visuals(power_type: String, emitter: Tile, targets: Array):
    """Start all visual effects in parallel"""
    
func _apply_power_effects(power_type: String, emitter: Tile, targets: Array, grid_manager):
    """Apply actual power effects (destroy, swap, etc.)"""
    
func interrupt_current_power():
    """Cancel animations and apply effects immediately"""
```

### PowerEffect.gd
**Role**: Visual effects and animations ONLY (sprites, particles, overlays)

```gdscript
# Static methods for effects
static func play_power_animation(power_type: String, emitter_pos: Vector2, target_positions: Array):
    """Play the main power animation (fireballs, lightning, etc.)"""
    
static func create_fireball(start_pos: Vector2, direction: Vector2):
static func create_lightning_bolt(target_pos: Vector2):
static func create_explosion(position: Vector2):
static func create_nuclear_flash():

# Overlay effects
static func show_blind_overlay(duration: float):
static func show_freeze_direction_indicator(direction: Direction):
static func remove_freeze_direction_indicator(direction: Direction):
```

### Tile.gd
**Role**: Individual tile state and visual representation

```gdscript
# Tile state
var value: int
var power_type: String
var is_frozen: bool
var freeze_turns: int
var grid_position: Vector2i

# Visual effect methods (NEW)
func start_emitter_effect(duration: float = 2.0):
    """Visual effect when this tile is the power emitter
    - Change value label to blue
    - Blink power icon
    """
    
func stop_emitter_effect():
    """Stop emitter visual effect immediately"""
    
func start_target_effect(duration: float = 2.0):
    """Visual effect when this tile is a power target
    - Blink/flash the entire tile
    """
    
func stop_target_effect():
    """Stop target visual effect immediately"""

# Existing methods
func update_visual():
func spawn_animation():
func merge_animation():
func destroy_animation():
func set_frozen(frozen: bool, turns: int):
```

### Grid.gd
**Role**: Grid visual container and cell backgrounds

```gdscript
# Visual management only
func add_tile(tile):
func calculate_screen_position(grid_pos: Vector2i) -> Vector2:
func clear_all_tiles():
```

---

## 🔧 Power-Specific Target Determination

Each power has a specific method to determine targets:

| Power | Emitter | Targets |
|-------|---------|---------|
| fire_h | Fusion tile | All tiles in same row (except emitter) |
| fire_v | Fusion tile | All tiles in same column (except emitter) |
| fire_cross | Fusion tile | All tiles in row + column (except emitter) |
| bomb | Fusion tile | All adjacent tiles (8 directions) |
| ice | Fusion tile | The fusion tile itself |
| switch_h | Fusion tile | Left and right adjacent tiles |
| switch_v | Fusion tile | Up and down adjacent tiles |
| teleport | Fusion tile | 2 random tiles (player choice or random) |
| expel_h | Fusion tile | Edge tile in same row |
| expel_v | Fusion tile | Edge tile in same column |
| freeze_* | Fusion tile | None (affects game state) |
| lightning | Fusion tile | 4 random tiles |
| nuclear | Fusion tile | All tiles (except emitter) |
| blind | Fusion tile | None (affects game state) |
| bowling | Fusion tile | Tiles in random direction line |
| ads | Fusion tile | None (triggers ad) |

---

## ⏱️ Timing Constants

```gdscript
const POWER_ANIMATION_DURATION = 2.0    # Maximum animation time
const EMITTER_EFFECT_DURATION = 2.0     # Emitter visual effect time
const TARGET_BLINK_DURATION = 2.0       # Target blink time
const BLINK_INTERVAL = 0.2              # Time between blinks
```

---

## 🎮 Integration with Game Flow

```
Player Input
    ↓
GameScene._process_move(direction)
    ↓
GridManager.process_movement(direction)
    ↓
    ├── move_tiles_*(fusions)  → Collect fusions
    ├── process_fusions(fusions)
    │       ↓
    │   PowerManager.activate_power(power, tile, grid_manager)
    │       ↓
    │       ├── get_power_targets() → Determine emitter + targets
    │       ├── _start_power_visuals() → Start animations (parallel)
    │       │       ├── Tile.start_emitter_effect()
    │       │       ├── Tile.start_target_effect() (for each target)
    │       │       └── PowerEffect.play_power_animation()
    │       └── await animation_complete or interrupt
    │       ↓
    │       └── _apply_power_effects() → Apply actual effects
    ↓
spawn_random_tile()
    ↓
Check game_over
```

---

## 🔄 State Reset on New Game

When `GameManager.start_new_game()` is called:

```gdscript
func start_new_game():
    # Reset persistent power states
    reset_power_states()
    
    # Reset game data
    game_data = {...}
    
    # Other initialization...
```

This ensures clean state for each new game session.
