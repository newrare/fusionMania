# Fusion Mania

A unique twist on the classic 2048 puzzle game with magical powers! Each tile has a special power that activates when merged with another tile of the same power. Strategic fusion gameplay combined with power activation mechanics creates an addictive and dynamic puzzle experience.


## 🎮 Game Features

- **Classic 2048 Mechanics**: Familiar sliding and merging gameplay
- **Magical Power System**: 20 different powers that trigger strategic effects
- **Free Mode**: Custom power selection for personalized gameplay
- **Color-Coded Tiles**: Beautiful neon glow effects with rounded borders
- **Multi-language Support**: Available in French and English
- **Score Tracking**: High score system and ranking
- **Strategic Depth**: Power priority system and turn-based effects
- **Visual Effects**: Floating scores, power messages, and animations
- **🎯 Touch Support**: Full touch/mouse support for PC and mobile (Android/iOS)
  - Swipe to move tiles
  - All buttons work with touch and mouse
  - Adaptive sound effects (hover on PC, tap on mobile)

## 🚀 Getting Started

### Prerequisites
- **Godot Engine 4.5+** (recommended)
- Basic knowledge of GDScript (for development)

### Installation
1. Clone this repository
2. Open the project in Godot Engine
3. Press F5 to run the game

## 📁 Project Structure

```
fusionMania/
├── assets/                     # Game assets
│   ├── images/                 # Game textures and sprites
│   ├── sounds/                 # Audio files
│   └── icons/                  # Power icons
├── managers/                   # Manager scripts
│   ├── AudioManager.gd         # Audio system management
│   ├── EnemyManager.gd         # Enemy spawning and combat management
│   ├── GameManager.gd          # Game state management
│   ├── GridManager.gd          # Grid and tile management
│   ├── LanguageManager.gd      # Localization system
│   ├── PowerManager.gd         # Power system management
│   ├── ScoreManager.gd         # Score tracking system
│   ├── SaveManager.gd          # Game save/load system
│   └── ToolsManager.gd         # Utility tools
├── overlays/                   # Modal overlay windows
│   ├── TitleMenu.gd            # Title menu overlay logic
│   ├── TitleMenu.tscn          # Title menu overlay scene
│   ├── GameOverMenu.gd         # Game over overlay logic
│   ├── GameOverMenu.tscn       # Game over overlay scene
│   ├── OptionsMenu.gd          # Options overlay logic
│   ├── OptionsMenu.tscn        # Options overlay scene
│   ├── RankingMenu.gd          # Ranking overlay logic
│   └── RankingMenu.tscn        # Ranking overlay scene
├── widgets/                    # UI widgets
│   └── UIButton.gd             # Custom button component
├── objects/                    # Game objects
│   ├── Tile.gd                 # Tile behavior and properties
│   ├── Tile.tscn               # Tile scene
│   ├── Grid.gd                 # Grid logic
│   ├── Grid.tscn               # Grid scene
│   ├── Enemy.gd                # Enemy behavior and combat
│   └── Enemy.tscn              # Enemy scene (sprite, health bar, labels)
├── visuals/                    # Global visual effects
│   └── PowerEffect.gd          # Power visual effects
├── scenes/                     # Main game scene
│   ├── GameScene.gd            # Main game logic and overlay management
│   └── GameScene.tscn          # Main game scene (contains grid + all overlays)
├── docs/                       # Documentation
│   ├── CONTEXT_*.md            # Project context files
│   └── PROMPTING_GUIDE.md      # AI prompting guide
├── tests/                      # Test and debug files
│   ├── test_setup.gd           # Test scripts
│   ├── test_setup.tscn         # Test scenes
│   └── verify_setup.sh         # Verification scripts
├── drafts/                     # Planning and drafts
│   ├── DEV_PLAN.md             # Development plan
│   ├── TODO.md                 # Task tracking
│   └── PHASE_*.md              # Phase guides
└── project.godot               # Godot project configuration
```

## 🏗️ Architecture

### Single Scene Design
The game uses a **single main scene** with **modal overlays** instead of multiple separate scenes. This approach simplifies state management and screen transitions.

#### Main Scene
- **GameScene.tscn**: Contains the grid, all UI overlays, and manages the game state
- The grid is always present in the background
- Overlays are shown/hidden as needed

#### Modal Overlays
1. **TitleMenu** (initial state):
   - Resume (if game saved)
   - New Game
   - Ranking
   - Options
   - Quit
   - Auto-saves game state when opened

2. **OptionsMenu**:
   - Music toggle (checkbox)
   - Sound toggle (checkbox)
   - Reset ranking (with confirmation)
   - Back to title

3. **RankingMenu**:
   - Score table display
   - Back to title

4. **GameOverMenu**:
   - Shows final score
   - Victory/defeat animation based on score
   - New Game button

#### Flow
- Game starts → TitleMenu overlay opens
- Player presses pause → TitleMenu overlay opens + game auto-saves
- Game over → GameOverMenu overlay opens with effects
- All overlays close to return to the grid view

### Benefits
- Simplified screen management
- No scene switching complexity
- Grid always remains loaded
- Faster transitions
- Easier state preservation

## Commands
```
cd <project_folder>
godot
godot project.godot
godot --export-debug "Android" ./fusionMania.apk
```

## 🎯 Game Mechanics

### Core Gameplay
- **Grid System**: 4x4 grid (similar to 2048)
- **Tile Spawning**: New tiles appear after each move (similar to 2048)
- **Movement**: Swipe in 4 directions to slide all tiles
- **Fusion**: Tiles with same number merge when colliding
- **Score**: Each fusion increases the score (same system as 2048)
- **Move Counter**: Tracks total number of moves made
- **Game Over**: Triggered when the grid is completely full

### 👾 Enemy System

The game features an enemy system that adds combat mechanics to the puzzle gameplay:

#### Enemy Basics
- **Spawn**: Enemy appears after the player's first fusion (triggers **Fight Mode**)
- **Position**: Top-right corner with 10% margin from edges
- **Sprites**: Randomly selected from multiple variants per level type
  - Normal enemies (2-512): `enemy_idle_01.png` to `enemy_idle_12.png` (192x48px, 4-frame animation)
  - Sub-Boss (1024): `enemy_subboss_*.png` series
  - Main Boss (2048): `enemy_mainboss_*.png` series
- **Glow Effect**: Each sprite has a colored glow matching its level color
- **Health Bar**: Red bar above sprite showing remaining HP
- **Level & Name**: Displayed below sprite (Lv + enemy name)
- **Damage Display**: Red floating numbers show damage taken

#### Combat Mechanics
- **Damage**: Fusing tiles damages the enemy (fusion result ÷ 2 = damage)
  - Example: 2+2=4 → 4÷2 = **2 damage**
  - Example: 8+8=16 → 16÷2 = **8 damage**
- **Defeat**: When HP reaches 0, enemy is destroyed
- **Score Bonus**: Defeating an enemy grants bonus points (Total Score × Enemy Level)
  - Example: Score 1000, Enemy Lv.8 → Bonus: **8,000 points**
- **Respawn**: After 10 moves, a new enemy spawns (up to max tile value)

#### Enemy Power Management
Enemies use the Fight Mode power system:
- **On Spawn**: Applies one random power from its available list to a random tile
- **Each Turn**: Adds another power to a different tile (if available)
- **Power Pool**: Enemies have level-specific available powers:
  - Level 2-512: Control powers (blocks, switches, fire)
  - Level 1024+: Advanced powers (nuclear, cross-fire)
- **Power Source**: All powers come from the enemy - not random spawns

#### Enemy Levels
Enemies have levels matching tile values with corresponding colors:

| Level | Color | Type | HP | Powers Available |
|-------|-------|------|-----|------------------|
| 2-512 | Tile colors | Normal | 10×Level | Limited set |
| 1024 | #700570 | **Sub-Boss** | 5120 | Extended set |
| 2048 | #440344 | **Main Boss** | 10240 | Full set (20 powers) |

#### Level Selection
The enemy's maximum possible level equals the highest tile value on the grid.
- **Level 512**: + Lightning
- **Level 1024** (Sub-Boss): + Fire Cross
- **Level 2048** (Boss): + Nuclear

### Visual Effects
- **Neon Glow Tiles**: Each tile features a glowing border in its signature color
- **Floating Score**: When tiles merge, the fusion score (+value) appears above the tile in neon blue, floating upward before fading
- **Power Messages**: Power activations display a message at the bottom of the grid for 5 seconds
- **Rounded Borders**: Smooth, modern tile appearance with rounded corners
- **Color-Coded Icons**: Power icons in top-right corner (green for bonus, red for malus)
- **Blind Overlay**: Black overlay covers the grid when Blind power activates

### Tile Visual Design
Each tile has:
- **2**: #FFFFFF (White)
- **4**: #D9D9D9 (Light Gray)
- **8**: #00FF00 (Green)
- **16**: #6D9EEB (Blue)
- **32**: #FFE599 (Light Yellow)
- **64**: #E69138 (Orange)
- **128**: #FF00FF (Magenta)
- **256**: #C809C8 (Purple)
- **512**: #9C079C (Dark Purple)
- **1024**: #700570 (Darker Purple)
- **2048**: #440344 (Deep Purple)

### 🔥 Power System

Each tile can have a power that activates when fused. The power system has two modes:

#### 🎮 Classic Mode
- **No powers** on tiles
- Pure 2048 puzzle gameplay
- Tiles spawn without powers

#### ⚔️ Fight Mode (when enemy is active)
- **Enemy assigns powers** to tiles strategically
- On spawn: Enemy applies one random power to a tile
- Each turn: Enemy adds a new power to a tile without power (up to 4 powers on grid)
- **Power Activation**: A power triggers immediately when a tile with that power **merges with any other tile**
  - The moving tile's power (if any) takes priority
  - After fusion, the new tile has **no power** (power is consumed)
- When enemy is defeated → return to Classic Mode + all powers are cleared

#### Power Rules
1. **Power Triggering**: Any tile with a power that merges will trigger it
2. **Power Priority**: If moving tile has power, it takes priority over the target tile
3. **Power Consumption**: Powers are single-use (consumed on fusion)
4. **One Power Per Movement**: Only the highest priority power activates per turn
   - Priority 1: Highest fusion value
   - Priority 2: Highest position on grid (lowest Y)
   - Priority 3: Leftmost position (lowest X)

#### 20 Available Powers
Same as tile powers, enemies can assign:
- **Fire Row/Column/Cross**: Destroy tiles in patterns
- **Bomb**: Destroy adjacent tiles
- **Ice**: Freeze tile for 5 turns
- **Block Directions**: Restrict player movement
- **Switch/Teleport**: Reposition tiles
- **Expel**: Push tiles off grid
- **And more**: Lightning, Nuclear, Blind, Bowling, Ads

- **[Fire -]** (10%): Horizontal fire - destroys an entire row (bonus: green icon)
- **[Fire |]** (10%): Vertical fire - destroys an entire column (bonus: green icon)
- **[Fire +]** (5%): Cross fire - destroys a row AND a column (bonus: green icon)
- **[Bomb]** (10%): Explosion - destroys adjacent tiles (bonus: green icon)
- **[Ice]** (6%): Freezes the tile for 5 movements (malus: red icon)
- **[Switch ↔]** (5%): Swap two horizontal tiles (bonus: green icon)
- **[Switch ↕]** (5%): Swap two vertical tiles (bonus: green icon)
- **[Teleport]** (2%): Player chooses 2 tiles to swap (bonus: green icon)
- **[Expel → ←]** (10%): Horizontal expulsion - edge tile exits the grid (bonus: green icon)
- **[Expel ↓ ↑]** (10%): Vertical expulsion - edge tile exits the grid (bonus: green icon)
- **[Freeze ↑]** (5%): Blocks UP movement for 2 turns (malus: red icon)
- **[Freeze ↓]** (5%): Blocks DOWN movement for 2 turns (malus: red icon)
- **[Freeze ←]** (5%): Blocks LEFT movement for 2 turns (malus: red icon)
- **[Freeze →]** (5%): Blocks RIGHT movement for 2 turns (malus: red icon)
- **[Lightning]** (2%): 4 random tiles are struck and destroyed (bonus: green icon)
- **[Nuclear]** (1%): All tiles are destroyed (bonus: green icon)
- **[Blind]** (2%): Grid becomes black for 4 seconds (malus: red icon)
- **[Bowling]** (2%): A ball crosses the grid randomly, destroying tiles (bonus: green icon)
- **[Ads]** (10%): Launches an ad for X seconds (malus: red icon)

#### 🎯 Free Mode

Free Mode allows you to customize which powers will appear in your game:

1. **Launch Free Mode**: From the main menu, select "FREE MODE"
2. **Select Powers**: A grid displays all 19 power icons with checkboxes
   - Each icon is color-coded: **Green** = Bonus, **Red** = Malus
   - Check/uncheck powers to include/exclude them
3. **Spawn Rate Distribution**:
   - **No powers selected**: All 19 powers spawn with default rates (normal mode)
   - **1 power selected**: That power spawns at 100%
   - **2 powers selected**: Each spawns at 50%
   - **N powers selected**: Each spawns at (100/N)%
4. **Start Game**: Click "START GAME" to begin with your custom power selection

**Example Scenarios**:
- Select only **Fire** powers for a destruction-focused game
- Select only **malus** powers for extreme difficulty
- Select a single power to guarantee specific gameplay mechanics
- Mix bonus and malus for balanced but focused gameplay

**Strategic Uses**:
- Practice specific power combinations
- Create themed challenges (e.g., "Ice Age" with only freeze powers)
- Simplify gameplay for new players by selecting only bonus powers
- Increase difficulty by selecting only malus powers

### Controls

#### PC (Desktop)
- **Move Tiles**: Arrow keys or WASD
- **Pause**: ESC or SPACE key
- **Language**: Toggle in options menu

#### Mobile (Android/iOS)
- **Move Tiles**: Swipe in any direction
- **Pause**: Tap the PAUSE button
- **Buttons**: Tap any button to activate

> **Note**: Mouse and touch work identically - the same code handles both!

## 🛠️ Development

### Built With
- **Godot Engine 4.5**: Game engine
- **GDScript**: Programming language
- **Tween System**: For smooth animations
- **Signal System**: For component communication

### Key Systems
- **Single Scene Architecture**: One main scene with modal overlays for simplified state management
- **Grid Management**: 4x4 grid with tile spawning logic
- **Power Management**: 20 different power effects with spawn rate control
- **Fusion Logic**: Tile merging with power inheritance
- **Enemy System**: Animated enemies with health bars, level-based powers, and respawn mechanics
- **Score Tracking**: Persistent high score system
- **Save System**: Auto-save when pausing, resume functionality
- **Overlay Management**: Dynamic show/hide of modal menus over the grid
- **Animation System**: Tween-based tile and effect animations
- **Input Handling**: Comprehensive swipe and keyboard input

## 🌍 Localization

The game supports multiple languages:
- 🇺🇸 English
- 🇫🇷 French

Language can be switched dynamically through the options menu.

## 📊 Technical Details

- **Engine**: Godot 4.5+
- **Rendering**: Mobile renderer with GL compatibility
- **Grid Size**: 4x4 tiles
- **Tile System**: Node-based tile management
- **Animation**: Tween nodes for smooth tile movements
- **Input**: Unified swipe/keyboard/touch input system
- **Platform**: PC (Windows, Linux, Mac), Mobile (Android, iOS)
- **Power System**: Probability-based power distribution with 20 unique effects

### 📱 Mobile Support

Full touch support implemented:
- **Touch Input**: `emulate_mouse_from_touch` enabled in project settings
- **Test Mode**: `emulate_touch_from_mouse` for PC testing
- **Smart Sounds**: Adaptive audio feedback based on platform detection
- **Swipe Detection**: Smooth gesture recognition for tile movement

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
