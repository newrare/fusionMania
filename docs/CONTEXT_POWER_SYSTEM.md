# Context: Power System

## 📋 Overview
Fusion Mania features 20 unique powers that activate when two tiles with the same power merge.

---

## ⚡ Complete Power List

| Power | Code | Spawn % | Type | Description |
|-------|------|---------|------|-------------|
| **Fire Horizontal** | `fire_h` | 10% | 🟢 Bonus | Destroys entire row |
| **Fire Vertical** | `fire_v` | 10% | 🟢 Bonus | Destroys entire column |
| **Fire Cross** | `fire_cross` | 5% | 🟢 Bonus | Destroys row AND column |
| **Bomb** | `bomb` | 10% | 🟢 Bonus | Destroys adjacent tiles |
| **Ice** | `ice` | 6% | 🔴 Malus | Ices tile for 5 turns |
| **Switch H** | `switch_h` | 5% | 🟢 Bonus | Swaps 2 horizontal tiles |
| **Switch V** | `switch_v` | 5% | 🟢 Bonus | Swaps 2 vertical tiles |
| **Teleport** | `teleport` | 2% | 🟢 Bonus | Player chooses 2 tiles to swap |
| **Expel H** | `expel_h` | 10% | 🟢 Bonus | Ejects edge tile |
| **Expel V** | `expel_v` | 10% | 🟢 Bonus | Ejects edge tile |
| **Block Up** | `block_up` | 5% | 🔴 Malus | Blocks UP movement for 2 turns |
| **Block Down** | `block_down` | 5% | 🔴 Malus | Blocks DOWN movement for 2 turns |
| **Block Left** | `block_left` | 5% | 🔴 Malus | Blocks LEFT movement for 2 turns |
| **Block Right** | `block_right` | 5% | 🔴 Malus | Blocks RIGHT movement for 2 turns |
| **Lightning** | `lightning` | 2% | 🟢 Bonus | Destroys 4 random tiles |
| **Nuclear** | `nuclear` | 1% | 🟢 Bonus | Destroys all tiles |
| **Blind** | `blind` | 2% | 🔴 Malus | Black grid for 2 turns |
| **Bowling** | `bowling` | 2% | 🟢 Bonus | Ball crosses and destroys |
| **Ads** | `ads` | 10% | 🔴 Malus | Shows ad for X seconds |

---

## 🎲 PowerManager (AutoLoad)

### Power Structure
```gdscript
const POWER_DATA = {
    "empty":        {"name": "Empty",           "spawn_rate": 30, "type": "none"},
    "fire_h":       {"name": "Fire Row",        "spawn_rate": 5,  "type": "bonus"},
    "fire_v":       {"name": "Fire Column",     "spawn_rate": 5,  "type": "bonus"},
    "fire_cross":   {"name": "Fire Cross",      "spawn_rate": 5,  "type": "bonus"},
    "bomb":         {"name": "Bomb",            "spawn_rate": 5,  "type": "bonus"},
    "ice":          {"name": "Ice",             "spawn_rate": 6,  "type": "malus"},
    "switch_h":     {"name": "Switch H",        "spawn_rate": 5,  "type": "bonus"},
    "switch_v":     {"name": "Switch V",        "spawn_rate": 5,  "type": "bonus"},
    "teleport":     {"name": "Teleport",        "spawn_rate": 2,  "type": "bonus"},
    "expel_h":      {"name": "Expel H",         "spawn_rate": 5,  "type": "bonus"},
    "expel_v":      {"name": "Expel V",         "spawn_rate": 5,  "type": "bonus"},
    "block_up":     {"name": "Block Up",        "spawn_rate": 5,  "type": "malus"},
    "block_down":   {"name": "Block Down",      "spawn_rate": 5,  "type": "malus"},
    "block_left":   {"name": "Block Left",      "spawn_rate": 5,  "type": "malus"},
    "block_right":  {"name": "Block Right",     "spawn_rate": 5,  "type": "malus"},
    "lightning":    {"name": "Lightning",       "spawn_rate": 2,  "type": "bonus"},
    "nuclear":      {"name": "Nuclear",         "spawn_rate": 1,  "type": "bonus"},
    "blind":        {"name": "Blind",           "spawn_rate": 2,  "type": "malus"},
    "bowling":      {"name": "Bowling",         "spawn_rate": 2,  "type": "bonus"},
    "ads":          {"name": "Ads",             "spawn_rate": 5,  "type": "malus"}
}
```

### Signals
```gdscript
signal power_activated(power_type: String, tile: Tile)
signal power_effect_completed(power_type: String)
```

---

## 🎯 Random Assignment

### Get Random Power
```gdscript
func get_random_power() -> String:
    var total_rate = 0
    for power_key in POWER_DATA.keys():
        total_rate += POWER_DATA[power_key].spawn_rate
    
    var random_value = randf() * total_rate
    var current_sum = 0
    
    for power_key in POWER_DATA.keys():
        current_sum += POWER_DATA[power_key].spawn_rate
        if random_value <= current_sum:
            return power_key if power_key != "empty" else ""
    
    return ""  # Default: no power
```

---

## 🔀 Fusion Resolution

### Power Inheritance Logic
```gdscript
func resolve_power_merge(power1: String, power2: String) -> String:
    # Case 1: Both have same power (activation!)
    if power1 == power2:
        return power1
    
    # Case 2: Only one has power
    if power1 == "":
        return power2
    if power2 == "":
        return power1
    
    # Case 3: Different powers -> keep rarest
    var rate1 = POWER_DATA.get(power1, {}).get("spawn_rate", 100)
    var rate2 = POWER_DATA.get(power2, {}).get("spawn_rate", 100)
    
    if rate1 < rate2:
        return power1  # power1 is rarer
    elif rate2 < rate1:
        return power2  # power2 is rarer
    else:
        # Same rarity: keep tile that initiated movement
        # (handled by GridManager)
        return power1
```

---

## ✨ Power Activation

### Main Method
```gdscript
func activate_power(power_type: String, tile: Tile, grid_manager):
    if power_type == "":
        return
    
    print("🔥 Activating power: %s" % power_type)
    power_activated.emit(power_type, tile)
    AudioManager.play_sfx_power()
    
    match power_type:
        "fire_h":
            activate_fire_horizontal(tile, grid_manager)
        "fire_v":
            activate_fire_vertical(tile, grid_manager)
        "fire_cross":
            activate_fire_cross(tile, grid_manager)
        "bomb":
            activate_bomb(tile, grid_manager)
        "ice":
            activate_ice(tile, grid_manager)
        "switch_h":
            activate_switch_horizontal(tile, grid_manager)
        "switch_v":
            activate_switch_vertical(tile, grid_manager)
        "teleport":
            activate_teleport(tile, grid_manager)
        "expel_h":
            activate_expel_horizontal(tile, grid_manager)
        "expel_v":
            activate_expel_vertical(tile, grid_manager)
        "block_up":
            activate_block_direction(GridManager.Direction.UP, grid_manager)
        "block_down":
            activate_block_direction(GridManager.Direction.DOWN, grid_manager)
        "block_left":
            activate_block_direction(GridManager.Direction.LEFT, grid_manager)
        "block_right":
            activate_block_direction(GridManager.Direction.RIGHT, grid_manager)
        "lightning":
            activate_lightning(tile, grid_manager)
        "nuclear":
            activate_nuclear(tile, grid_manager)
        "blind":
            activate_blind(tile, grid_manager)
        "bowling":
            activate_bowling(tile, grid_manager)
        "ads":
            activate_ads(tile, grid_manager)
    
    power_effect_completed.emit(power_type)
```

---

## 🎆 Power Implementation (Examples)

### Fire Horizontal
```gdscript
func activate_fire_horizontal(tile: Tile, grid_manager):
    var row = tile.grid_position.y
    
    # Destroy entire row
    for x in range(grid_manager.grid_size):
        var target = grid_manager.get_tile_at(Vector2i(x, row))
        if target != null and target != tile:
            grid_manager.destroy_tile(target)
    
    # Visual effect
    PowerEffect.fire_line_effect(row, true)  # true = horizontal
```

### Bomb
```gdscript
func activate_bomb(tile: Tile, grid_manager):
    var pos = tile.grid_position
    
    # Adjacent positions (8 directions)
    var adjacent = [
        Vector2i(pos.x - 1, pos.y - 1), Vector2i(pos.x, pos.y - 1), Vector2i(pos.x + 1, pos.y - 1),
        Vector2i(pos.x - 1, pos.y),                                 Vector2i(pos.x + 1, pos.y),
        Vector2i(pos.x - 1, pos.y + 1), Vector2i(pos.x, pos.y + 1), Vector2i(pos.x + 1, pos.y + 1)
    ]
    
    for adj_pos in adjacent:
        var target = grid_manager.get_tile_at(adj_pos)
        if target != null:
            grid_manager.destroy_tile(target)
    
    # Visual effect
    PowerEffect.explosion_effect(tile.position)
```

### Ice
```gdscript
func activate_ice(tile: Tile, grid_manager):
    tile.is_iced = true
    tile.ice_turns = 5
    tile.apply_ice_effect()
    
    # Visual effect
    PowerEffect.ice_effect(tile)
```

### Teleport
```gdscript
func activate_teleport(tile: Tile, grid_manager):
    # Interactive mode: player must click 2 tiles
    grid_manager.enter_teleport_mode()
```

### Lightning
```gdscript
func activate_lightning(tile: Tile, grid_manager):
    var all_tiles = []
    
    # Get all tiles
    for y in range(grid_manager.grid_size):
        for x in range(grid_manager.grid_size):
            var t = grid_manager.get_tile_at(Vector2i(x, y))
            if t != null and t != tile:
                all_tiles.append(t)
    
    # Choose 4 random tiles
    all_tiles.shuffle()
    var targets = all_tiles.slice(0, mini(4, all_tiles.size()))
    
    # Destroy with effect
    for target in targets:
        PowerEffect.lightning_strike_effect(target)
        await get_tree().create_timer(0.2).timeout
        grid_manager.destroy_tile(target)
```

---

## 🎨 Visual Effects (PowerEffect.gd)

```gdscript
# visuals/PowerEffect.gd
extends Node

static func fire_line_effect(index: int, is_horizontal: bool):
    # Create animated fire line
    pass

static func explosion_effect(position: Vector2):
    # Create explosion with particles
    pass

static func ice_effect(tile: Tile):
    # Add blue icy overlay
    pass

static func lightning_strike_effect(tile: Tile):
    # Lightning striking tile
    pass

static func nuclear_flash():
    # White flash across entire grid
    pass

static func blind_overlay(duration: float):
    # Black overlay hiding grid
    pass
```

---

## 🎯 Priority Rules

### One Activation Per Turn
- If multiple fusions with powers in one movement
- **Horizontal movement**: execute top to bottom
- **Vertical movement**: execute right to left

### Implementation
```gdscript
func sort_fusions_by_priority(fusions: Array, direction: GridManager.Direction) -> Array:
    match direction:
        GridManager.Direction.UP, GridManager.Direction.DOWN:
            # Vertical: sort right to left
            fusions.sort_custom(func(a, b): return a.position.x > b.position.x)
        GridManager.Direction.LEFT, GridManager.Direction.RIGHT:
            # Horizontal: sort top to bottom
            fusions.sort_custom(func(a, b): return a.position.y < b.position.y)
    
    return fusions
```

---

## ✅ Implementation Checklist

- [ ] Create `managers/PowerManager.gd` (AutoLoad)
- [ ] Create `visuals/PowerEffect.gd`
- [ ] Define `POWER_DATA` with 20 powers
- [ ] Implement `get_random_power()`
- [ ] Implement `resolve_power_merge()`
- [ ] Implement `activate_power()` (switch)
- [ ] Implement each power individually
- [ ] Create basic visual effects
- [ ] Test each power separately
- [ ] Test priority rules
