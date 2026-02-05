# Context: Global Managers

## 📋 Overview
Managers are singletons (AutoLoad) that handle global game systems. They communicate via signals and method calls to coordinate gameplay.

---

## 🎮 GameManager

### Purpose
Central game state manager that coordinates game modes and their transitions.

### Game Mode System
```gdscript
enum GameMode {
    CLASSIC,  # No enemy on grid, no powers
    FIGHT     # Enemy actively placing powers on tiles
}
```

### State
```gdscript
var current_mode: GameMode = GameMode.CLASSIC
```

### Signals
```gdscript
signal mode_changed(new_mode: GameMode)
```

### Methods

#### Mode Control
```gdscript
# Transition to Fight Mode (called by EnemyManager.spawn_enemy())
func enter_fight_mode() -> void:
    if current_mode == GameMode.FIGHT:
        return
    current_mode = GameMode.FIGHT
    mode_changed.emit(current_mode)

# Transition to Classic Mode (called by EnemyManager.defeat_enemy())
func enter_classic_mode() -> void:
    if current_mode == GameMode.CLASSIC:
        return
    current_mode = GameMode.CLASSIC
    mode_changed.emit(current_mode)

# Clear all tile powers (called when entering Classic Mode)
func clear_all_tile_powers() -> void:
    for tile in GridManager.get_all_tiles():
        tile.power_type = ""
        tile.update_visual()
```

#### Query Methods
```gdscript
# Check current mode
func is_fight_mode() -> bool:
    return current_mode == GameMode.FIGHT

func is_classic_mode() -> bool:
    return current_mode == GameMode.CLASSIC
```

### Integration

- **EnemyManager**: Calls `enter_fight_mode()` on spawn, `enter_classic_mode()` on defeat
- **GridManager**: Can query mode for behavioral changes (if needed)
- **GameScene**: Listens to `mode_changed` signal for UI updates

---

## 👾 EnemyManager

### Purpose
Manages enemy lifecycle: spawning, level selection, health tracking, power assignment, and defeat.

### State
```gdscript
var active_enemy: Dictionary  # Current enemy data
var moves_until_respawn: int = 0
```

### Enemy Data Structure
```gdscript
{
    "name": "Euclidor",
    "level": 64,
    "sprite_path": "res://assets/images/enemy_idle_3.png",
    "current_hp": 320,
    "max_hp": 320,
    "powers": ["block_up", "block_down", ...],  # From ENEMY_POWERS_BY_LEVEL
    "scene_node": <Enemy Node reference>
}
```

### Signals
```gdscript
signal enemy_spawned(enemy)
signal enemy_damaged(damage, remaining_hp)
signal enemy_defeated(enemy_level, score_bonus)
signal respawn_timer_updated(moves_remaining)
```

### Methods

#### Spawning
```gdscript
# Spawn a new enemy (called after respawn timer or first fusion)
func spawn_enemy() -> void:
    # 1. Determine level based on max tile
    var level = determine_enemy_level()
    
    # 2. Select random name and sprite
    var name = ENEMY_NAMES[randi() % ENEMY_NAMES.size()]
    var sprite_path = get_random_sprite_path(level)
    
    # 3. Instantiate enemy scene
    var enemy_node = preload("res://objects/Enemy.tscn").instantiate()
    enemy_node.initialize(name, level, sprite_path)
    enemy_container.add_child(enemy_node)
    
    # 4. Store enemy data
    active_enemy = {
        "name": name,
        "level": level,
        "sprite_path": sprite_path,
        "current_hp": get_enemy_max_hp(level),
        "max_hp": get_enemy_max_hp(level),
        "powers": ENEMY_POWERS_BY_LEVEL.get(level, []),
        "scene_node": enemy_node
    }
    
    # 5. Enter Fight Mode
    GameManager.enter_fight_mode()
    
    # 6. Apply first power
    apply_power_to_random_tile()
    
    # 7. Emit signal
    enemy_spawned.emit(active_enemy)
```

#### Power Assignment (Fight Mode)
Powers are assigned by the enemy, one per player move (max 4 on grid).

```gdscript
# Get random power from active enemy's power list
func get_random_enemy_power() -> String:
    if not is_enemy_active():
        return ""
    
    var powers = active_enemy.get("powers", [])
    if powers.is_empty():
        return ""
    
    return powers[randi() % powers.size()]

# Apply power to a random tile without power
func apply_power_to_random_tile() -> bool:
    if not is_enemy_active():
        return false
    
    var tiles_without_power = get_tiles_without_power()
    if tiles_without_power.is_empty():
        return false  # All tiles have powers (max 4)
    
    var random_tile = tiles_without_power[randi() % tiles_without_power.size()]
    var random_power = get_random_enemy_power()
    
    if random_power == "":
        return false
    
    random_tile.power_type = random_power
    random_tile.update_visual()
    return true

# Get all tiles currently without power
func get_tiles_without_power() -> Array:
    var tiles_without = []
    for tile in GridManager.get_all_tiles():
        if tile.power_type == "":
            tiles_without.append(tile)
    return tiles_without
```

#### Combat
```gdscript
# Damage enemy when fusion occurs (called from GameScene)
func damage_enemy(damage: int) -> void:
    if not is_enemy_active():
        return
    
    active_enemy["current_hp"] -= damage
    enemy_damaged.emit(damage, active_enemy["current_hp"])
    
    # Update enemy visual
    var enemy_node = active_enemy["scene_node"]
    enemy_node.current_hp = active_enemy["current_hp"]
    enemy_node.update_display()
    
    # Show floating damage
    UIEffect.show_floating_damage(damage, enemy_node.global_position)
    
    # Check for defeat
    if active_enemy["current_hp"] <= 0:
        defeat_enemy()
```

#### Move Handling
```gdscript
# Called each time player completes a move
func on_move_completed() -> void:
    # Add new power if enemy active (Fight Mode)
    if is_enemy_active():
        apply_power_to_random_tile()
    
    # Update respawn timer if no enemy
    if not is_enemy_active() and moves_until_respawn > 0:
        moves_until_respawn -= 1
        respawn_timer_updated.emit(moves_until_respawn)
        
        if moves_until_respawn == 0:
            spawn_enemy()
```

#### Defeat
```gdscript
# Called when enemy HP reaches 0
func defeat_enemy() -> void:
    if not is_enemy_active():
        return
    
    var enemy_level = active_enemy["level"]
    
    # Calculate bonus score
    var current_score = ScoreManager.get_current_score()
    var bonus = current_score * enemy_level
    ScoreManager.add_score(bonus)
    
    # Clean up enemy
    active_enemy["scene_node"].queue_free()
    active_enemy = {}
    
    # Return to Classic Mode
    GameManager.enter_classic_mode()
    GameManager.clear_all_tile_powers()
    
    # Start respawn timer
    moves_until_respawn = 10
    
    # Emit signals
    enemy_defeated.emit(enemy_level, bonus)
```

#### Query Methods
```gdscript
func is_enemy_active() -> bool:
    return not active_enemy.is_empty()

func has_active_enemy() -> bool:
    return is_enemy_active()
```

### Private Methods

```gdscript
# Determine enemy level from max tile value
func determine_enemy_level() -> int:
    var max_tile_value = GridManager.get_max_tile_value()
    var available_levels = []
    
    for level in [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]:
        if level <= max_tile_value:
            available_levels.append(level)
    
    if available_levels.is_empty():
        return 2
    
    return available_levels[randi() % available_levels.size()]

# Get max HP for enemy level
func get_enemy_max_hp(level: int) -> int:
    var hp_map = {
        2: 10, 4: 20, 8: 40, 16: 80, 32: 160,
        64: 320, 128: 640, 256: 1280, 512: 2560,
        1024: 5120, 2048: 10240
    }
    return hp_map.get(level, 10)

# Get random sprite for level
func get_random_sprite_path(level: int) -> String:
    var prefix = "enemy_idle_" if level < 1024 else \
                 "enemy_subboss_" if level == 1024 else \
                 "enemy_mainboss_"
    
    var variant = randi() % 12 + 1
    return "res://assets/images/%s%d.png" % [prefix, variant]
```

### Integration

- **GameManager**: Calls mode transitions on spawn/defeat
- **GridManager**: Gets tile list for power assignment, listens to move signals
- **GameScene**: Calls `damage_enemy()` on fusion, connects to enemy signals
- **PowerManager**: Not directly; power effects handled by GridManager

---

## 🔲 GridManager

### Purpose
Manages grid tiles, movement, fusion logic, and power activation.

### Key Methods
```gdscript
# Get all tiles on grid
func get_all_tiles() -> Array:
    var all_tiles = []
    for row in grid:
        for tile in row:
            if tile:
                all_tiles.append(tile)
    return all_tiles

# Get maximum tile value (for enemy level)
func get_max_tile_value() -> int:
    var max_val = 0
    for tile in get_all_tiles():
        if tile.value > max_val:
            max_val = tile.value
    return max_val
```

### Signals
```gdscript
signal fusion_occurred(tile1, tile2, new_tile)
signal move_completed
```

### Power Activation in Fusion
When tiles merge, if a power is activated:

```gdscript
func process_fusions() -> void:
    # Check all tiles for merges
    for tile in get_all_tiles():
        var adjacent = get_adjacent_tiles(tile)
        for adj_tile in adjacent:
            if can_merge(tile, adj_tile):
                var result = tile.merge_with(adj_tile)
                
                # Check for activated power
                if result.has("activated_power") and result["activated_power"] != "":
                    var power = result["activated_power"]
                    PowerManager.activate_power(power, tile.grid_position)
                    
                    # Enemy takes damage if active
                    if EnemyManager.is_enemy_active():
                        EnemyManager.damage_enemy(tile.value / 2)
```

### Integration

- **EnemyManager**: Requests tile list for power placement, receives move signals
- **PowerManager**: Requests power activation
- **GameScene**: Emits move signals

---

## ✨ PowerManager

### Purpose
Manages 20 unique powers and their grid effects.

### Power Types
```
Block Powers:      block_up, block_down, block_left, block_right
Fire Powers:       fire_h, fire_v, fire_cross
Movement Powers:   teleport, switch_h, switch_v, expel_h, expel_v
Element Powers:    ice, bomb, lightning
Special Powers:    blind, nuclear
```

### Methods
```gdscript
# Activate power at grid position
func activate_power(power_type: String, position: Vector2i) -> void:
    if not POWERS.has(power_type):
        return
    
    var power_effect = POWERS[power_type]
    power_effect.call(position)
```

### Integration

- **GridManager**: Receives power activation requests from fusion
- **Tile.gd**: Reads and displays power type

---

## 🎵 AudioManager

### Main Methods
```gdscript
play_sfx_move()
play_sfx_fusion()
play_sfx_power()
play_sfx_button_click()
play_sfx_game_over()
play_sfx_win()

toggle_music()
toggle_sfx()
is_music_enabled() -> bool
is_sfx_enabled() -> bool
```

### Configuration File
`user://audio_settings.cfg`

---

## 🌍 LanguageManager

### Main Methods
```gdscript
set_language(lang: String)
get_current_language() -> String
toggle_language()
```

### Signals
```gdscript
signal language_changed
```

### Configuration File
`user://language_settings.cfg`

---

## 🏆 ScoreManager

### Main Methods
```gdscript
start_game()
add_to_score(points: int)
add_score(score: int) -> int  # Returns rank 1-10
get_current_score() -> int
get_high_scores() -> Array
reset_all_scores()
```

### Signals
```gdscript
signal score_changed(new_score: int)
signal high_score_achieved(score: int, rank: int)
```

### Configuration File
`user://fusion_mania_scores.save`

---

## 🔧 project.godot Configuration

```ini
[autoload]
GameManager="*res://managers/GameManager.gd"
EnemyManager="*res://managers/EnemyManager.gd"
GridManager="*res://managers/GridManager.gd"
PowerManager="*res://managers/PowerManager.gd"
AudioManager="*res://managers/AudioManager.gd"
LanguageManager="*res://managers/LanguageManager.gd"
ScoreManager="*res://managers/ScoreManager.gd"
```

---

## 🔄 Mode Transition Flowchart

```
Game Start
├─ Classic Mode (no enemy)
│
├─ [Player makes first fusion]
│
├─ EnemyManager.spawn_enemy()
│  ├─ Create enemy
│  ├─ GameManager.enter_fight_mode()
│  └─ Apply first power
│
├─ Fight Mode (enemy active)
│  ├─ Each move:
│  │  ├─ Player fuses tiles
│  │  ├─ Power may activate
│  │  ├─ Enemy takes damage
│  │  └─ New power added
│  │
│  └─ Enemy HP reaches 0
│     ├─ EnemyManager.defeat_enemy()
│     ├─ GameManager.enter_classic_mode()
│     ├─ GameManager.clear_all_tile_powers()
│     └─ Start 10-move respawn timer
│
└─ Classic Mode (countdown: 10 moves)
   ├─ Each move decrements timer
   └─ Timer reaches 0 → spawn new enemy (repeat)
```

---

## 💡 Best Practices

### Accessing Managers
```gdscript
GameManager.enter_fight_mode()
EnemyManager.damage_enemy(10)
ScoreManager.add_to_score(50)
```

### Listening to Signals
```gdscript
func _ready():
    GameManager.mode_changed.connect(_on_mode_changed)
    EnemyManager.enemy_spawned.connect(_on_enemy_spawned)
    ScoreManager.score_changed.connect(_on_score_changed)
```

