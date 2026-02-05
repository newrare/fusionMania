````markdown
# Context: Power System

## 📋 Overview
Fusion Mania features 20 unique powers that activate strategically. The power system has **two modes**:

### 🎮 Classic Mode
- **No powers** spawn on tiles
- Pure puzzle gameplay (like original 2048)
- Activated when no enemy is active
- Default mode at game start

### ⚔️ Fight Mode  
- Triggered when an **enemy spawns** (first fusion)
- **Enemy assigns powers** to tiles dynamically
- On enemy spawn: 1 power is applied to a random tile
- On each player move: Enemy adds another power to a tile without power
- Powers activate when tiles **with powers merge** (any fusion with a powered tile)
- Moving tile's power has priority over target tile's power
- One power per turn activation (highest priority wins)
- When enemy dies → **All tile powers are cleared** → Returns to Classic Mode

---

## ⚡ Complete Power List

| Power | Code | Type | Description |
|-------|------|------|-------------|
| **Fire Horizontal** | `fire_h` | 🟢 Bonus | Destroys entire row |
| **Fire Vertical** | `fire_v` | 🟢 Bonus | Destroys entire column |
| **Fire Cross** | `fire_cross` | 🟢 Bonus | Destroys row AND column |
| **Bomb** | `bomb` | 🟢 Bonus | Destroys adjacent tiles |
| **Ice** | `ice` | 🔴 Malus | Ices tile for 5 turns |
| **Switch H** | `switch_h` | 🟢 Bonus | Swaps 2 horizontal tiles |
| **Switch V** | `switch_v` | 🟢 Bonus | Swaps 2 vertical tiles |
| **Teleport** | `teleport` | 🟢 Bonus | Player chooses 2 tiles to swap |
| **Expel H** | `expel_h` | 🟢 Bonus | Ejects edge tile |
| **Expel V** | `expel_v` | 🟢 Bonus | Ejects edge tile |
| **Block Up** | `block_up` | 🔴 Malus | Blocks UP movement for 2 turns |
| **Block Down** | `block_down` | 🔴 Malus | Blocks DOWN movement for 2 turns |
| **Block Left** | `block_left` | 🔴 Malus | Blocks LEFT movement for 2 turns |
| **Block Right** | `block_right` | 🔴 Malus | Blocks RIGHT movement for 2 turns |
| **Lightning** | `lightning` | 🟢 Bonus | Destroys 4 random tiles |
| **Nuclear** | `nuclear` | 🟢 Bonus | Destroys all tiles |
| **Blind** | `blind` | 🔴 Malus | Black grid for 4 turns |
| **Bowling** | `bowling` | 🟢 Bonus | Ball crosses and destroys |
| **Ads** | `ads` | 🔴 Malus | Shows ad for X seconds |

---

## 🎲 PowerManager (AutoLoad)

### Power Structure
```gdscript
const POWERS = {
    "fire_h":       {"name": "Fire Row",        "spawn_rate": 10, "type": "bonus", "duration": 1.0},
    "fire_v":       {"name": "Fire Column",     "spawn_rate": 10, "type": "bonus", "duration": 1.0},
    "fire_cross":   {"name": "Fire Cross",      "spawn_rate": 5,  "type": "bonus", "duration": 1.0},
    "bomb":         {"name": "Bomb",            "spawn_rate": 10, "type": "bonus", "duration": 0.3},
    "ice":          {"name": "Ice",             "spawn_rate": 6,  "type": "malus", "duration": 3.0},
    "switch_h":     {"name": "Switch H",        "spawn_rate": 5,  "type": "bonus", "duration": 0.3},
    "switch_v":     {"name": "Switch V",        "spawn_rate": 5,  "type": "bonus", "duration": 0.3},
    "teleport":     {"name": "Teleport",        "spawn_rate": 2,  "type": "bonus", "duration": 0.3},
    "expel_h":      {"name": "Expel H",         "spawn_rate": 10, "type": "bonus", "duration": 0.3},
    "expel_v":      {"name": "Expel V",         "spawn_rate": 10, "type": "bonus", "duration": 0.3},
    "block_up":     {"name": "Block Up",        "spawn_rate": 5,  "type": "malus", "duration": 1.0},
    "block_down":   {"name": "Block Down",      "spawn_rate": 5,  "type": "malus", "duration": 1.0},
    "block_left":   {"name": "Block Left",      "spawn_rate": 5,  "type": "malus", "duration": 1.0},
    "block_right":  {"name": "Block Right",     "spawn_rate": 5,  "type": "malus", "duration": 1.0},
    "lightning":    {"name": "Lightning",       "spawn_rate": 2,  "type": "bonus", "duration": 0.3},
    "nuclear":      {"name": "Nuclear",         "spawn_rate": 1,  "type": "bonus", "duration": 1.5},
    "blind":        {"name": "Blind",           "spawn_rate": 2,  "type": "malus", "duration": 4.0},
    "bowling":      {"name": "Bowling",         "spawn_rate": 2,  "type": "bonus", "duration": 0.5},
    "ads":          {"name": "Ads",             "spawn_rate": 10, "type": "malus", "duration": 1.0}
}
```

### Signals
```gdscript
signal power_activated(power_type: String, tile: Tile)
signal power_effect_completed(power_type: String)
```

---

## ⚙️ Game Mode (GameManager)

### Mode System
```gdscript
enum GameMode {
    CLASSIC,  # No powers on tiles
    FIGHT     # Enemy assigns powers
}

var current_mode: GameMode = GameMode.CLASSIC
```

### Mode Transitions
1. **Start Game** → CLASSIC mode (no enemy)
2. **First Fusion** → Enemy spawns → Enter FIGHT mode
3. **Enemy Defeated** → Clear all tile powers → Return to CLASSIC mode
4. **10 Moves Later** → New enemy spawns → Back to FIGHT mode

---

## 🔀 Power Activation (NEW!)

### Fusion & Power Triggering

#### Classic Mode Fusion
- Two tiles with **same value** merge
- New tile has **no power** (classic 2048 behavior)
- Result: Increased score only

#### Fight Mode Fusion
- **ANY tile with power that merges triggers its power**
- Tile A has power → Tile B doesn't → **Tile A's power triggers**
- Tile A has power → Tile B has power → **Tile A's power triggers** (moving tile priority)
- Tile A doesn't → Tile B has power → **Tile B's power triggers**
- Tile A has power → Tile B has same power → **Moving tile's power triggers**

### Power Consumption
Powers are **single-use**:
- Power triggers on fusion
- New tile **has NO power** after fusion (power is consumed)
- Enemy will apply new powers on next move

### Priority System
When multiple fusions happen in one move, **only ONE power activates**:

1. **Highest fusion value** wins
2. If tied → **Highest position** (lowest Y) wins
3. If still tied → **Leftmost** (lowest X) wins

Example:
```
Move: 4 → 4 = 8 (with power)  [Position: (1,1)]
Move: 4 → 4 = 8 (with power)  [Position: (2,1)]
Result: Only position (1,1) power activates (leftmost)
```

---

## 📋 Power Resolution Logic

### Merge Result Structure
```gdscript
func merge_with(other_tile) -> Dictionary:
    var new_value = value * 2
    
    # NEW: Power triggers if ANY tile has power
    var power_to_activate = ""
    if power_type != "":
        power_to_activate = power_type      # Moving tile's power
    elif other_tile.power_type != "":
        power_to_activate = other_tile.power_type  # Target tile's power
    
    # New tile has no power (power consumed)
    var new_power = ""
    
    return {
        "value":           new_value,
        "power":           new_power,         # New tile power (empty)
        "power_activated": power_to_activate != "",
        "activated_power": power_to_activate   # Which power to trigger
    }
```

---

## 🎯 Random Power Assignment (Classic Mode - deprecated)

This was the **old system** before Fight Mode. Kept for reference:

### Get Random Power
In Classic Mode, this is no longer used:
```gdscript
func get_random_power() -> String:
    # Returns empty string in Classic Mode
    # Only used when Free Mode is enabled (future feature)
    return ""
```

---

## ✨ Power Activation Method

### Main Activation
```gdscript
func activate_power(power_type: String, tile: Tile, grid_manager):
    if power_type == "":
        return
    
    print("🔥 Activating power: %s" % power_type)
    power_activated.emit(power_type, tile)
    AudioManager.play_sfx_power()
    
    match power_type:
        "fire_h":
            await activate_fire_horizontal(tile, grid_manager)
        "fire_v":
            await activate_fire_vertical(tile, grid_manager)
        # ... etc for all 20 powers
```

---

## 📁 Files Modified

- `managers/GameManager.gd`: Added `GameMode` enum and mode management
- `managers/GridManager.gd`: Updated fusion processing for new power logic
- `managers/EnemyManager.gd`: Power assignment and fight mode transition
- `objects/Tile.gd`: New merge logic with power triggering

````
