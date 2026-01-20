# Fusion Mania

A unique twist on the classic 2048 puzzle game with magical powers! Each tile has a special power that activates when merged with another tile of the same power. Strategic fusion gameplay combined with power activation mechanics creates an addictive and dynamic puzzle experience.


## 🎮 Game Features

- **Classic 2048 Mechanics**: Familiar sliding and merging gameplay
- **Magical Power System**: 20 different powers that trigger strategic effects
- **Color-Coded Tiles**: Beautiful gradient from white (2) to dark purple (2048)
- **Multi-language Support**: Available in French and English
- **Score Tracking**: High score system and ranking
- **Strategic Depth**: Power priority system and turn-based effects
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
│   └── Grid.tscn               # Grid scene
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
- **Game Over**: Triggered when the grid is completely full

### Tile Colors
Each tile value has a unique color:
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

Each tile displays a power icon in the bottom-right corner. When two tiles with the **same power icon** merge, the power activates!

#### Power List (with spawn rates)
- **[Empty]** (30%): No power
- **[Fire -]** (5%): Horizontal fire - destroys an entire row (bonus: green icon)
- **[Fire |]** (5%): Vertical fire - destroys an entire column (bonus: green icon)
- **[Fire +]** (5%): Cross fire - destroys a row AND a column (bonus: green icon)
- **[Bomb]** (5%): Explosion - destroys adjacent tiles (bonus: green icon)
- **[Ice]** (6%): Freezes the tile for 5 movements (malus: red icon)
- **[Switch ↔]** (5%): Swap two horizontal tiles (bonus: green icon)
- **[Switch ↕]** (5%): Swap two vertical tiles (bonus: green icon)
- **[Teleport]** (2%): Player chooses 2 tiles to swap (bonus: green icon)
- **[Expel → ←]** (5%): Horizontal expulsion - edge tile exits the grid (bonus: green icon)
- **[Expel ↓ ↑]** (5%): Vertical expulsion - edge tile exits the grid (bonus: green icon)
- **[Freeze ↑]** (5%): Blocks UP movement for 2 turns (malus: red icon)
- **[Freeze ↓]** (5%): Blocks DOWN movement for 2 turns (malus: red icon)
- **[Freeze ←]** (5%): Blocks LEFT movement for 2 turns (malus: red icon)
- **[Freeze →]** (5%): Blocks RIGHT movement for 2 turns (malus: red icon)
- **[Lightning]** (2%): 4 random tiles are struck and destroyed (bonus: green icon)
- **[Nuclear]** (1%): All tiles are destroyed (bonus: green icon)
- **[Blind]** (2%): Grid becomes black for 2 turns (malus: red icon)
- **[Bowling]** (2%): A ball crosses the grid randomly, destroying tiles (bonus: green icon)
- **[Ads]** (5%): Launches an ad for X seconds (malus: red icon)

#### Power Rules
1. **Matching Powers**: Both tiles must have the same power icon to activate
2. **Single Power Tile**: If only one tile has a power, the merged tile keeps that power
3. **Different Powers**: If both tiles have different powers, keep the rarer one (lower spawn %), if % same, keep power from the tile that initiated the move
4. **Power Priority**: If multiple fusions happen in one move:
   - **Horizontal movement**: Execute powers from top to bottom
   - **Vertical movement**: Execute powers from right to left
5. **One Power Per Turn**: Only one power executes per turn, even if multiple fusions occur

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
