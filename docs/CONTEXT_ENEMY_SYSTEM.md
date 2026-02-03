# Context: Enemy System

## 📋 Overview
The Enemy system adds an antagonist to Fusion Mania that the player must defeat by fusing tiles. Enemies have levels matching tile values (2-2048), health bars, and can use powers against the player.

---

## 🎯 Core Concept

### Enemy Lifecycle
1. **Spawn**: Enemy appears after the player's first fusion
2. **Combat**: Player damages enemy by fusing tiles (fusion value / 2 = damage)
3. **Defeat**: When HP reaches 0, enemy is destroyed
4. **Respawn**: After 10 moves/turns, a new enemy spawns

### Level System
Enemies have levels matching tile values:
| Level | Color | HP | Type |
|-------|-------|-----|------|
| 2 | #FFFFFF (White) | 10 | Normal |
| 4 | #D9D9D9 (Light Gray) | 20 | Normal |
| 8 | #00FF00 (Green) | 40 | Normal |
| 16 | #6D9EEB (Blue) | 80 | Normal |
| 32 | #FFE599 (Light Yellow) | 160 | Normal |
| 64 | #E69138 (Orange) | 320 | Normal |
| 128 | #FF00FF (Magenta) | 640 | Normal |
| 256 | #C809C8 (Purple) | 1280 | Normal |
| 512 | #9C079C (Dark Purple) | 2560 | Normal |
| 1024 | #700570 (Darker Purple) | 5120 | **Sub-Boss** |
| 2048 | #440344 (Deep Purple) | 10240 | **Main Boss** |

### Level Selection Rule
The enemy level is determined by the highest tile value on the grid:
- If max tile is 64 → Enemy can spawn at level 2, 4, 8, 16, 32, or 64
- Random selection within available levels

---

## 🖼️ Visual Structure

### Sprite Selection System
Enemies use different sprite sets based on their level:

**Normal Enemies (Level 2-512)**:
- Randomly selected from: `assets/images/enemy_idle_01.png` to `enemy_idle_12.png`
- Each sprite is a 4-frame animation (192x48px total, 48x48 per frame)
- Random selection happens on spawn
- Glow effect applied using the tile color for that level

**Sub-Boss (Level 1024)**:
- Randomly selected from: `assets/images/enemy_subboss_01.png`, `enemy_subboss_02.png`, etc.
- Same format as normal enemies (192x48px, 48x48 per frame)
- Glow effect in #700570 (Darker Purple)

**Main Boss (Level 2048)**:
- Randomly selected from: `assets/images/enemy_mainboss_01.png`, `enemy_mainboss_02.png`, etc.
- Same format as normal enemies (192x48px, 48x48 per frame)
- Glow effect in #440344 (Deep Purple)

### Glow Effect (Color Swap)
The sprite receives a colored glow overlay matching its level color:
```gdscript
# Apply modulate for color glow effect
var level_color = TILE_COLORS.get(level, Color.WHITE)
idle_sprite.modulate = level_color
# Or use self_modulate for stronger effect
idle_sprite.self_modulate = level_color
```

### Scene Layout (in GameScene)
```
GameScene
└── EnemyContainer (Node2D, top-right with 10% margin)
    └── Enemy (Node2D)
        ├── IdleSprite (AnimatedSprite2D)
        │   └── SpriteFrames: idle animation (4 frames, 48x48)
        │   └── Modulate: level color glow effect
        ├── HealthBarBg (ColorRect, gray, 300x10px)
        ├── HealthBar (ColorRect, red, 300x10px)
        └── NameLabel (Label, "<Name>: <LevelInColor>")
```

### Positioning
- **Location**: Top-right corner of GameScene
- **Margins**: 10% from top and right edges
- **Health Bar**: Centered above sprite (300x10px)
- **Name/Level**: Centered below sprite

### Health Bar
```gdscript
# Constants
const HEALTH_BAR_WIDTH = 300.0
const HEALTH_BAR_HEIGHT = 10.0

# Visual
var health_bar_bg: ColorRect  # Gray background (#666666)
var health_bar: ColorRect     # Red foreground (#FF0000)

# Update health bar width based on current HP
func update_health_bar():
    var hp_percent = float(current_hp) / float(max_hp)
    health_bar.size.x = HEALTH_BAR_WIDTH * hp_percent
```

---

## ⚔️ Combat System

### Damage Calculation
```gdscript
# Fusion damage formula
# fusion_value = the value of the resulting tile after fusion
# damage = fusion_value / 2

# Examples:
# 2 + 2 = 4  → damage = 4 / 2 = 2 HP
# 4 + 4 = 8  → damage = 8 / 2 = 4 HP
# 8 + 8 = 16 → damage = 16 / 2 = 8 HP
```

### Enemy Defeat
```gdscript
# When enemy HP reaches 0
func on_enemy_defeated():
    # 1. Calculate score bonus
    var score_bonus = ScoreManager.get_current_score() * enemy.level
    ScoreManager.add_score(score_bonus)
    
    # 2. Play defeat animation/sound
    # 3. Remove enemy from scene
    # 4. Start respawn timer (10 moves)
    moves_until_respawn = 10
```

### Score Bonus Formula
```
Bonus Score = Current Total Score × Enemy Level

Examples:
- Score: 1000, Enemy Level: 8  → Bonus: 1000 × 8 = 8,000 points
- Score: 5000, Enemy Level: 64 → Bonus: 5000 × 64 = 320,000 points
- Score: 10000, Enemy Level: 2048 → Bonus: 10000 × 2048 = 20,480,000 points

Note: Defeating higher-level enemies (especially bosses) gives massive score bonuses!
```
    
# Check respawn on each move
func on_move_completed():
    if enemy_defeated and moves_until_respawn > 0:
        moves_until_respawn -= 1
        if moves_until_respawn == 0:
            spawn_new_enemy()
```

---

## 🎭 Enemy Names

### Name System
100 math-themed funny names for enemies:

```gdscript
const ENEMY_NAMES = [
    # Mathematicians Puns
    "Pythagoron", "Euclidor", "Archimedon", "Fibonaccio", "Gaussinator",
    "Eulerix", "Newtonix", "Leibnizor", "Fermatron", "Riemannox",
    "Lovelacix", "Turingbot", "Babbagon", "Pascalor", "Descartox",
    
    # Number Puns
    "Infinitron", "Zeronator", "Primox", "Divisor", "Factorion",
    "Modulox", "Integerix", "Decimalon", "Fractionor", "Radicalix",
    
    # Operation Puns
    "Addinator", "Subtractron", "Multiplox", "Dividron", "Exponix",
    "Sqrootox", "Logarix", "Derivator", "Integron", "Limitron",
    
    # Shape Puns
    "Trianglor", "Squarox", "Circleon", "Hexagonix", "Polygonor",
    "Cubixon", "Spherion", "Pyramidex", "Cylindrix", "Conixor",
    
    # Algebra Puns
    "Variablex", "Constantor", "Coefficix", "Polynomor", "Equatron",
    "Formulix", "Theoremon", "Axiomox", "Postulator", "Lemmatron",
    
    # Geometry Puns
    "Angulator", "Perpendix", "Parallelon", "Tangentrix", "Secantox",
    "Vectorix", "Matrixor", "Tensoron", "Dimensior", "Planeton",
    
    # Calculus Puns
    "Deltarix", "Epsilonor", "Sigmator", "Thetanox", "Omegabot",
    "Infinitix", "Asymptron", "Convergix", "Divergon", "Seriestor",
    
    # Statistics Puns
    "Meanator", "Medianox", "Modexor", "Deviatron", "Variancix",
    "Probabilor", "Randomix", "Sampleton", "Correlator", "Regrexor",
    
    # Logic Puns
    "Booleanix", "Andgator", "Orgonix", "Notronix", "Xorinator",
    "Nandexor", "Normatron", "Implicor", "Biconditrix", "Negator",
    
    # Set Theory Puns
    "Unionix", "Intersector", "Subsetron", "Complementor", "Emptixor",
    "Cardinalix", "Ordinalon", "Powersetor", "Bijector", "Surjexor",
    
    # Famous Numbers
    "Piratrix", "Eulerion", "Goldenox", "Avogadrix", "Plancktor",
    "Imaginarix", "Complexor", "Rationalon", "Irrationalix", "Transcendor"
]
```

### Display Format
```gdscript
# Name label format: "<Name>: <Level>"
# Level is displayed in the corresponding tile color

func get_display_name() -> String:
    return "%s: %d" % [enemy_name, level]

# The level number uses BBCode or a colored Label for the level color
```

---

## 🔮 Enemy Powers by Level

Enemies can use powers against the player. Available powers depend on enemy level:

```gdscript
const ENEMY_POWERS_BY_LEVEL = {
    2: ["block_up", "block_down", "block_left", "block_right"],
    4: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v"],
    8: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport"],
    16: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice"],
    32: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v"],
    64: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb"],
    128: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v"],
    256: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind"],
    512: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind", "lightning"],
    1024: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind", "lightning", "fire_cross"],
    2048: ["block_up", "block_down", "block_left", "block_right", "fire_h", "fire_v", "teleport", "ice", "switch_h", "switch_v", "bomb", "expel_h", "expel_v", "blind", "lightning", "fire_cross", "nuclear"]
}
```

### Power Categories by Level
| Level | New Powers Unlocked |
|-------|---------------------|
| 2 | Block directions (up, down, left, right) |
| 4 | + Fire horizontal/vertical |
| 8 | + Teleport |
| 16 | + Ice |
| 32 | + Switch horizontal/vertical |
| 64 | + Bomb |
| 128 | + Expel horizontal/vertical |
| 256 | + Blind |
| 512 | + Lightning |
| 1024 (Sub-Boss) | + Fire Cross |
| 2048 (Boss) | + Nuclear |

---

## 📁 File Structure

### New Files
```
objects/
├── Enemy.gd          # Enemy behavior and logic
└── Enemy.tscn        # Enemy scene (sprite, health bar, labels)

managers/
└── EnemyManager.gd   # Enemy spawning, level selection, respawn timer, sprite selection (AutoLoad)
```

### Sprite Selection in EnemyManager
```gdscript
# Get random sprite path based on level
func get_random_sprite_path(level: int) -> String:
    var sprite_prefix = ""
    
    if level == 2048:
        sprite_prefix = "enemy_mainboss_"
    elif level == 1024:
        sprite_prefix = "enemy_subboss_"
    else:
        sprite_prefix = "enemy_idle_"
    
    # Count available sprite variants
    var variant_count = count_sprite_variants(sprite_prefix)
    var random_variant = randi() % variant_count + 1
    
    return "res://assets/images/%s%d.png" % [sprite_prefix, random_variant]

# Helper to count available sprite files
func count_sprite_variants(prefix: String) -> int:
    # Scan assets/images/ for files matching prefix
    # Return count (fallback to 1 if scanning fails)
    pass
```

### Modified Files
```
scenes/
├── GameScene.gd      # Connect to enemy signals, handle enemy spawn/defeat
└── GameScene.tscn    # Add Enemy node to scene

managers/
└── GridManager.gd    # Emit signal on fusion with fusion value for damage calculation
```

---

## 📡 Signals

### EnemyManager Signals
```gdscript
signal enemy_spawned(enemy)
signal enemy_damaged(damage, remaining_hp)
signal enemy_defeated(enemy_level, score_bonus)
signal respawn_timer_updated(moves_remaining)
```

### GridManager Addition
```gdscript
# Existing signal modification
signal fusion_occurred(tile1, tile2, new_tile)
# Add fusion value info for enemy damage calculation
```

---

## 🔧 Integration Points

### GameScene._ready()
```gdscript
# Connect enemy signals
EnemyManager.enemy_spawned.connect(_on_enemy_spawned)
EnemyManager.enemy_defeated.connect(_on_enemy_defeated)
GridManager.fusion_occurred.connect(_on_fusion_for_enemy)
```

### Damage on Fusion
```gdscript
func _on_fusion_for_enemy(tile1, tile2, new_tile):
    if EnemyManager.has_active_enemy():
        var damage = new_tile.value / 2
        EnemyManager.damage_enemy(damage)
```

---

## 🎮 Gameplay Flow

```
1. Game starts → No enemy visible
2. Player makes first fusion → Enemy spawns (level based on max tile)
3. Player continues fusing → Enemy takes damage
4. Enemy HP reaches 0 → Enemy defeated, disappears
5. 10 moves pass → New enemy spawns
6. Repeat from step 3
```

---

## 🎨 Visual Assets Needed

### Sprites

**Normal Enemies (Level 2-512)**:
- `assets/images/enemy_idle_1.png` - Variant 1 (384x96px, 4 frames)
- `assets/images/enemy_idle_2.png` - Variant 2 (384x96px, 4 frames)
- `assets/images/enemy_idle_3.png` - Variant 3 (384x96px, 4 frames)
- `assets/images/enemy_idle_4.png` - Variant 4 (384x96px, 4 frames)
- ... (add more variants as needed)

**Sub-Boss (Level 1024)**:
- `assets/images/enemy_subboss_1.png` - Variant 1 (384x96px, 4 frames)
- `assets/images/enemy_subboss_2.png` - Variant 2 (384x96px, 4 frames)
- ... (add more variants as needed)

**Main Boss (Level 2048)**:
- `assets/images/enemy_mainboss_1.png` - Variant 1 (384x96px, 4 frames)
- `assets/images/enemy_mainboss_2.png` - Variant 2 (384x96px, 4 frames)
- ... (add more variants as needed)

**Note**: Each sprite receives a colored glow overlay matching its level using the modulate property.

### Sounds (Future)
- `assets/sounds/sfx_enemy_hit.wav` - When enemy takes damage
- `assets/sounds/sfx_enemy_defeated.wav` - When enemy is defeated
- `assets/sounds/sfx_enemy_spawn.wav` - When enemy spawns
- `assets/sounds/sfx_boss_music.mp3` - Music for boss fights (1024, 2048)
