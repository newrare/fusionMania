# Enemy System Implementation - Prompting Plan

This document contains a series of prompts to implement the Enemy system step by step in Fusion Mania.

---

## Phase 1: Core Infrastructure

### Prompt 1.1 - Create EnemyManager (AutoLoad)
```
Create the EnemyManager.gd singleton in managers/ folder. This manager handles:
- Enemy spawning logic
- Respawn timer (10 moves after enemy defeat)
- Level selection based on max tile value
- Damage calculation
- Active enemy tracking
- Random sprite selection based on enemy level

Include these constants and variables:
- ENEMY_LEVELS = [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
- ENEMY_NAMES array with 100 math-themed funny names (examples: Pythagoron, Euclidor, Fibonaccio, Gaussinator, Infinitron, Addinator, Trianglor, etc.)
- ENEMY_POWERS_BY_LEVEL dictionary mapping each level to available powers
- HP_BY_LEVEL dictionary (level 2 = 10 HP, doubling each level up to 2048 = 10240 HP)

Include sprite selection logic:
- get_random_sprite_path(level: int) -> String
  - Level 2-512: return random "res://assets/images/enemy_idle_01.png" to enemy_idle_12.png (use %02d format)
  - Level 1024: return random "res://assets/images/enemy_subboss_01.png", enemy_subboss_02.png, etc.
  - Level 2048: return random "res://assets/images/enemy_mainboss_01.png", enemy_mainboss_02.png, etc.
  - All sprites are 192x48px (4 frames of 48x48 each)
- count_sprite_variants(prefix: String) -> int
  - Scan assets/images/ folder for matching sprite files
  - Return count of available variants (fallback to 1)

Include these signals:
- enemy_spawned(enemy_data: Dictionary)
- enemy_damaged(damage: int, remaining_hp: int)
- enemy_defeated(enemy_level: int, score_bonus: int)
- respawn_timer_updated(moves_remaining: int)

Include these methods:
- spawn_enemy() - Creates enemy data based on max tile, includes sprite_path
- damage_enemy(amount: int) - Applies damage to active enemy
- defeat_enemy() - Calculates score bonus and emits defeat signal
- calculate_score_bonus(enemy_level: int) -> int - Returns current_score × enemy_level
- get_random_name() -> String
- get_level_for_max_tile(max_tile_value: int) -> int
- is_enemy_active() -> bool
- on_move_completed() - Handles respawn countdown

Register as AutoLoad in project.godot.
Read docs/CONTEXT_ENEMY_SYSTEM.md for full specifications.
```

### Prompt 1.2 - Create Enemy Scene and Script
```
Create Enemy.gd and Enemy.tscn in objects/ folder.

The Enemy scene structure should be:
Enemy (Node2D)
├── IdleSprite (AnimatedSprite2D) - dynamically loaded sprite based on level
├── HealthBarContainer (Node2D, positioned above sprite, centered)
│   ├── HealthBarBg (ColorRect, gray #666666, 300x10px)
│   └── HealthBar (ColorRect, red #FF0000, 300x10px)
└── NameLabel (Label, positioned below sprite, centered)

Enemy.gd should include:
- Properties: level, max_hp, current_hp, enemy_name, sprite_path
- TILE_COLORS dictionary (same as Tile.gd for level colors)
- Methods:
  - initialize(data: Dictionary) - Sets up enemy from EnemyManager data
    - Load sprite from data["sprite_path"]
    - Create SpriteFrames from sprite (4 frames, 48x48 each, 192x48 total)
    - Apply glow effect: idle_sprite.modulate = TILE_COLORS[level]
  - load_sprite_frames(sprite_path: String) -> SpriteFrames
    - Create AtlasTextures for 4 frames (0, 48, 96, 144 x-offsets, 48x48 size)
    - Return SpriteFrames with "idle" animation
  - apply_level_glow()
    - Set idle_sprite.modulate to level color
    - Creates color swap/glow effect
  - take_damage(amount: int) - Reduces HP, updates health bar
  - update_health_bar() - Adjusts red bar width proportionally
  - update_display() - Updates name label with colored level
  - play_idle_animation() - Starts idle animation loop
  - die() - Plays defeat animation, emits signal, queue_free()

Sprite variants used:
- Normal (level 2-512): enemy_idle_01.png to enemy_idle_12.png (192x48px, 48x48 per frame)
- Sub-Boss (1024): enemy_subboss_01.png, enemy_subboss_02.png, etc.
- Boss (2048): enemy_mainboss_01.png, enemy_mainboss_02.png, etc.

The glow effect is achieved by setting modulate to the tile color for that level.
This creates a color swap effect that makes each enemy visually distinct.

The name label should display: "<Name>: <Level>" where level is colored using the tile color for that level.
Use BBCode or a separate colored Label for the level number.

Read docs/CONTEXT_ENEMY_SYSTEM.md and docs/CONTEXT_TILE_SYSTEM.md for colors and specifications.
```

---

## Phase 2: GameScene Integration

### Prompt 2.1 - Add Enemy Container to GameScene
```
Modify GameScene.tscn and GameScene.gd to integrate the Enemy system:

1. In GameScene.tscn:
   - Add an EnemyContainer (Node2D) node after UIEffect
   - This container will hold the spawned Enemy instance
   - Remove the existing EnemyIdle AnimatedSprite2D (it will be part of Enemy.tscn now)

2. In GameScene.gd:
   - Add @onready var enemy_container = $EnemyContainer
   - Connect to EnemyManager signals in _ready():
     - EnemyManager.enemy_spawned.connect(_on_enemy_spawned)
     - EnemyManager.enemy_defeated.connect(_on_enemy_defeated)
   - Implement _on_enemy_spawned(enemy_data):
     - Instance Enemy.tscn
     - Call enemy.initialize(enemy_data)
     - Add to enemy_container
   - Implement _on_enemy_defeated(enemy_level, score_bonus):
     - Remove enemy from container
     - Display bonus score UI (floating text showing "+<bonus>")
     - ScoreManager.add_score(score_bonus) - Add the bonus to player score
   - Update _on_viewport_resized() to position enemy_container at top-right with 10% margins

Keep the existing parallax background and all other systems intact.
```

### Prompt 2.2 - Connect Fusion to Enemy Damage
```
Modify GameScene.gd to connect tile fusions to enemy damage:

1. In the existing _on_fusion_occurred(tile1, tile2, new_tile) function:
   - After showing floating score, check if enemy is active
   - Calculate damage: new_tile.value / 2
   - Call EnemyManager.damage_enemy(damage)

2. Add visual feedback:
   - Show damage number floating from enemy (similar to fusion score)
   - Flash the enemy sprite red briefly on hit

3. Connect move completion to respawn timer:
   - In _on_tiles_moved() or appropriate move handler
   - Call EnemyManager.on_move_completed()

The enemy should only spawn after the FIRST fusion in a game session.
Add a flag in EnemyManager: first_fusion_occurred = false
Set it to true on first fusion and call spawn_enemy()
```

---

## Phase 3: Enemy Spawn Logic

### Prompt 3.1 - Implement Level Selection
```
In EnemyManager.gd, implement the level selection logic:

1. get_max_tile_value() -> int:
   - Query GridManager for all tiles
   - Return the highest tile value found
   - Return 2 if grid is empty

2. get_available_levels(max_tile: int) -> Array:
   - Filter ENEMY_LEVELS to only include levels <= max_tile
   - Example: max_tile=64 returns [2, 4, 8, 16, 32, 64]

3. select_random_level(max_tile: int) -> int:
   - Get available levels
   - Return a random level from the array
   - Weight towards higher levels for more challenge (optional)

4. spawn_enemy():
   - Get max tile value from grid
   - Select random level
   - Get random name
   - Calculate HP for level
   - Get available powers for level
   - Emit enemy_spawned signal with all data

Test by verifying enemies don't spawn at levels higher than the max tile.
```

### Prompt 3.2 - Implement Respawn Timer
```
In EnemyManager.gd, implement the respawn countdown:

1. Add variables:
   - var moves_until_respawn: int = 0
   - var enemy_defeated_flag: bool = false
   - var first_fusion_occurred: bool = false

2. on_enemy_defeated(enemy_level: int):
   - Calculate score bonus: current_score × enemy_level
   - Add bonus to ScoreManager
   - Emit enemy_defeated(enemy_level, score_bonus) signal
   - Set enemy_defeated_flag = true
   - Set moves_until_respawn = 10

3. on_move_completed():
   - If enemy_defeated_flag and moves_until_respawn > 0:
     - Decrement moves_until_respawn
     - Emit respawn_timer_updated(moves_until_respawn)
     - If moves_until_respawn == 0:
       - Set enemy_defeated_flag = false
       - Call spawn_enemy()

4. reset() - For new game:
   - Reset all flags and timers
   - first_fusion_occurred = false
   - enemy_defeated_flag = false
   - moves_until_respawn = 0

Connect to GameManager.game_started to call reset().
```

---

## Phase 4: Visual Polish

### Prompt 4.1 - Health Bar Animation
```
Improve the health bar visual feedback in Enemy.gd:

1. Smooth health bar decrease:
   - Use Tween to animate health bar width change
   - Duration: 0.3 seconds
   - Easing: EASE_OUT

2. Damage flash effect:
   - When taking damage, flash the IdleSprite white/red
   - Use modulate property with Tween
   - Quick flash: 0.1s to white, 0.1s back to normal

3. Low health warning:
   - When HP < 25%, make health bar pulse/flash
   - Add a subtle glow effect

4. Defeat animation:
   - Calculate and display score bonus (current_score × level)
   - Show floating bonus text above enemy (gold color, large font)
   - Scale down + fade out
   - Optional: particle effect burst
   - Duration: 0.5 seconds before queue_free()
   - Emit defeated signal with level and score_bonus
```

### Prompt 4.2 - Enemy Spawn Animation
```
Add spawn animation for enemies in Enemy.gd:

1. Initial state:
   - Start with scale = Vector2(0, 0)
   - Start with modulate.a = 0 (transparent)

2. Spawn animation sequence:
   - Tween scale from (0,0) to (1.2, 1.2) in 0.3s
   - Then scale to (1.0, 1.0) in 0.1s (bounce effect)
   - Simultaneously fade in modulate.a from 0 to 1

3. Add spawn sound effect:
   - Call AudioManager.play_sfx("sfx_enemy_spawn") if available

4. Optional particle effect:
   - Spawn particles around enemy on appear
```

---

## Phase 5: Boss Special Treatment

### Prompt 5.1 - Sub-Boss and Boss Indicators
```
Add special visual treatment for level 1024 (Sub-Boss) and 2048 (Boss):

1. In Enemy.gd, add boss detection:
   - var is_sub_boss: bool = (level == 1024)
   - var is_boss: bool = (level == 2048)

2. Visual differences for bosses:
   - Larger scale: Sub-Boss = 1.2x, Boss = 1.5x
   - Add a crown/special icon above sprite for bosses
   - Different idle animation speed (slower, more menacing)
   - Intensified glow effect (multiply modulate alpha or add shader)
   - Optional: Pulsing glow animation for bosses

3. Sprite selection:
   - Sub-Boss uses enemy_subboss_<x>.png sprites
   - Boss uses enemy_mainboss_<x>.png sprites
   - Glow colors: Sub-Boss=#700570, Boss=#440344

4. Name label formatting:
   - Sub-Boss: Add "⚔️" prefix to name
   - Boss: Add "👑" prefix to name
   - Larger font size for boss names

5. Health bar styling:
   - Sub-Boss: Orange health bar instead of red
   - Boss: Purple health bar with golden border

6. Optional: Trigger special boss music
   - On boss spawn, tell AudioManager to switch to boss music
```

---

## Phase 6: Save/Load Integration

### Prompt 6.1 - Save Enemy State
```
Integrate enemy state with SaveManager:

1. In EnemyManager.gd, add methods:
   - get_save_data() -> Dictionary:
     Returns: {
       "has_enemy": bool,
       "enemy_level": int,
       "enemy_name": String,
       "enemy_sprite_path": String,
       "enemy_hp": int,
       "enemy_max_hp": int,
       "moves_until_respawn": int,
       "first_fusion_occurred": bool
     }
   
   - load_save_data(data: Dictionary):
     Restores enemy state from saved data
     Includes sprite_path for consistent enemy appearance

2. In SaveManager.gd:
   - Add enemy data to save_game() 
   - Add enemy restoration in restore_game()

3. In GameScene.gd:
   - On resume, check if enemy should be restored
   - If has_enemy in save data, spawn enemy with saved stats and sprite
   - If moves_until_respawn > 0, continue countdown

Test save/load with:
- Active enemy with partial HP
- Defeated enemy with respawn countdown
- No enemy yet (first fusion not occurred)
- Different sprite variants restore correctly
```

---

## Phase 7: Testing & Debug

### Prompt 7.1 - Debug Commands
```
Add debug commands for testing the enemy system:

1. In GameScene.gd or a new DebugManager:
   - spawn_test_enemy(level: int) - Force spawn enemy at specific level
   - kill_enemy() - Instantly defeat current enemy
   - damage_enemy_debug(amount: int) - Apply specific damage
   - set_respawn_timer(moves: int) - Set custom respawn time

2. Debug display (optional):
   - Show enemy HP numerically
   - Show respawn countdown on screen
   - Show available powers for current enemy level

3. Console commands (if debug console exists):
   - "enemy spawn <level>" 
   - "enemy kill"
   - "enemy damage <amount>"
   - "enemy info" - Print current enemy stats

These should only work in debug builds (if OS.is_debug_build()).
```

---

## Execution Order

1. **Start with Prompt 1.1** - EnemyManager is the foundation
2. **Then Prompt 1.2** - Enemy scene needs manager to work
3. **Then Prompts 2.1 and 2.2** - Integration connects everything
4. **Then Prompts 3.1 and 3.2** - Spawn logic makes it functional
5. **Prompts 4.x** - Visual polish (can be done anytime after Phase 3)
6. **Prompt 5.1** - Boss treatment (optional, after basics work)
7. **Prompt 6.1** - Save/load (important for game persistence)
8. **Prompt 7.1** - Debug tools (helpful throughout development)

---

## Testing Checklist

After each phase, verify:

### Phase 1
- [ ] EnemyManager loads as AutoLoad
- [ ] ENEMY_NAMES has 100 entries
- [ ] ENEMY_POWERS_BY_LEVEL has all 11 levels
- [ ] Enemy.tscn displays correctly in editor

### Phase 2
- [ ] Enemy container positions correctly
- [ ] Enemy spawns after first fusion
- [ ] Enemy takes damage on fusion
- [ ] Enemy removed on defeat

### Phase 3
- [ ] Level never exceeds max tile value
- [ ] Respawn happens after 10 moves
- [ ] Multiple enemies spawn/die correctly

### Phase 4
- [ ] Health bar animates smoothly
- [ ] Damage flash is visible
- [ ] Spawn animation plays

### Phase 5
- [ ] Bosses look distinct
- [ ] Boss indicators display

### Phase 6
- [ ] Enemy state saves correctly
- [ ] Enemy restores on resume
- [ ] Respawn timer persists

---

## Notes

- Always read CONTEXT_ENEMY_SYSTEM.md before starting a prompt
- Reference CONTEXT_TILE_SYSTEM.md for color values
- Reference CONTEXT_POWER_SYSTEM.md for power codes
- Test on both PC and mobile (touch) after integration
- Keep console output for debugging (print statements)
