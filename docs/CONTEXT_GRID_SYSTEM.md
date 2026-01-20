# Context: Grid and Movement System

## 📋 Overview
The grid system handles 2048 game logic: 4x4 grid, tile spawning, movements, fusions, and game over detection.

---

## 🎯 GridManager (AutoLoad)

### Responsibilities
- 4x4 grid management
- New tile spawning
- Movement detection and processing
- Fusion logic
- Game over detection

### Properties
```gdscript
var grid: Array[Array]       # 4x4 grid of tiles (or null)
var grid_size: int = 4       # Grid size
var can_move: bool = true    # If player can move
var move_count: int = 0      # Number of moves made
var blocked_directions: Array = []  # Blocked directions (freeze powers)
```

### Signals
```gdscript
signal tile_spawned(tile: Tile, position: Vector2i)
signal movement_completed(direction: String)
signal fusion_occurred(tile1: Tile, tile2: Tile, new_tile: Tile)
signal no_moves_available()
signal game_over()
```

---

## 🏗️ Grid Initialization

### Creating Empty Grid
```gdscript
func initialize_grid():
    grid = []
    for y in range(grid_size):
        var row = []
        for x in range(grid_size):
            row.append(null)
        grid.append(row)
```

### Initial Spawn
```gdscript
func start_new_game():
    initialize_grid()
    spawn_random_tile()  # First tile
    spawn_random_tile()  # Second tile
    move_count = 0
    blocked_directions.clear()
```

---

## 🎲 Tile Spawning

### Random Spawn
```gdscript
func spawn_random_tile():
    var empty_cells = get_empty_cells()
    
    if empty_cells.is_empty():
        return null
    
    # Choose empty cell
    var random_cell = empty_cells[randi() % empty_cells.size()]
    
    # 90% chance of 2, 10% chance of 4
    var value = 2 if randf() < 0.9 else 4
    
    # Assign power
    var power = PowerManager.get_random_power()
    
    # Create tile
    var tile = create_tile(value, power, random_cell)
    
    return tile

func get_empty_cells() -> Array:
    var empty = []
    for y in range(grid_size):
        for x in range(grid_size):
            if grid[y][x] == null:
                empty.append(Vector2i(x, y))
    return empty
```

### Tile Creation
```gdscript
func create_tile(value: int, power: String, grid_pos: Vector2i) -> Tile:
    var tile = preload("res://objects/Tile.tscn").instantiate()
    tile.initialize(value, power, grid_pos)
    grid[grid_pos.y][grid_pos.x] = tile
    
    # Add to scene (via Grid node)
    Grid.add_tile(tile)
    
    tile_spawned.emit(tile, grid_pos)
    return tile
```

---

## 🎮 Movement System

### Directions
```gdscript
enum Direction {
    UP,
    DOWN,
    LEFT,
    RIGHT
}
```

### Processing Movement
```gdscript
func process_movement(direction: Direction):
    if not can_move:
        return
    
    # Check if direction is blocked
    if direction in blocked_directions:
        print("Direction blocked by freeze power!")
        return
    
    can_move = false
    var moved = false
    var fusions = []
    
    # Apply movement based on direction
    match direction:
        Direction.UP:
            moved = move_tiles_up(fusions)
        Direction.DOWN:
            moved = move_tiles_down(fusions)
        Direction.LEFT:
            moved = move_tiles_left(fusions)
        Direction.RIGHT:
            moved = move_tiles_right(fusions)
    
    # If at least one tile moved
    if moved:
        move_count += 1
        AudioManager.play_sfx_move()
        
        # Wait for animations to finish
        await get_tree().create_timer(0.3).timeout
        
        # Process fusions
        process_fusions(fusions)
        
        # Spawn new tile
        spawn_random_tile()
        
        # Decrement freeze turns
        update_freeze_timers()
        
        # Check game over
        if not has_valid_moves():
            game_over.emit()
    
    can_move = true
    movement_completed.emit(direction)
```

---

## ⬆️ Movement Logic by Direction

### Move Up (detailed example)
```gdscript
func move_tiles_up(fusions: Array) -> bool:
    var moved = false
    
    # Traverse top to bottom, left to right
    for x in range(grid_size):
        for y in range(grid_size):
            if grid[y][x] == null:
                continue
            
            var tile = grid[y][x]
            if tile.is_frozen:
                continue
            
            # Find target position
            var target_y = y
            
            # Move up as far as possible
            while target_y > 0 and grid[target_y - 1][x] == null:
                target_y -= 1
            
            # Check fusion with tile above
            if target_y > 0:
                var above_tile = grid[target_y - 1][x]
                if above_tile != null and tile.can_merge_with(above_tile):
                    # Fusion possible
                    fusions.append({
                        "tile1": tile,
                        "tile2": above_tile,
                        "position": Vector2i(x, target_y - 1)
                    })
                    
                    # Move tile to fusion position
                    move_tile(tile, Vector2i(x, y), Vector2i(x, target_y - 1))
                    moved = true
                    continue
            
            # Simple movement (no fusion)
            if target_y != y:
                move_tile(tile, Vector2i(x, y), Vector2i(x, target_y))
                moved = true
    
    return moved
```

### Move Down, Left, Right
- Same logic but reversed directions
- **Down**: traverse bottom to top
- **Left**: traverse left to right
- **Right**: traverse right to left

---

## 🔄 Tile Fusion

### Processing Fusions
```gdscript
func process_fusions(fusions: Array):
    if fusions.is_empty():
        return
    
    # Sort fusions by priority (based on direction)
    # See PowerManager for priority logic
    
    for fusion_data in fusions:
        var tile1 = fusion_data.tile1
        var tile2 = fusion_data.tile2
        var position = fusion_data.position
        
        # Merge tiles
        var merge_result = tile1.merge_with(tile2)
        
        # Create new tile
        var new_tile = create_tile(
            merge_result.value,
            merge_result.power,
            position
        )
        
        # Add score
        ScoreManager.add_to_score(merge_result.value)
        
        # Animation and sound
        new_tile.merge_animation()
        AudioManager.play_sfx_fusion()
        
        # Destroy old tiles
        destroy_tile(tile1)
        destroy_tile(tile2)
        
        # Activate power if match
        if merge_result.power_activated:
            PowerManager.activate_power(merge_result.power, new_tile, self)
        
        fusion_occurred.emit(tile1, tile2, new_tile)
```

---

## 🚫 Game Over Detection

### Check Valid Moves
```gdscript
func has_valid_moves() -> bool:
    # Check if there are empty cells
    if not get_empty_cells().is_empty():
        return true
    
    # Check possible horizontal and vertical fusions
    for y in range(grid_size):
        for x in range(grid_size):
            var tile = grid[y][x]
            if tile == null or tile.is_frozen:
                continue
            
            # Check right
            if x < grid_size - 1:
                var right_tile = grid[y][x + 1]
                if right_tile != null and tile.can_merge_with(right_tile):
                    return true
            
            # Check bottom
            if y < grid_size - 1:
                var bottom_tile = grid[y + 1][x]
                if bottom_tile != null and tile.can_merge_with(bottom_tile):
                    return true
    
    return false
```

---

## 🧊 Freeze System

### Block Direction
```gdscript
func block_direction(direction: Direction, turns: int):
    if direction not in blocked_directions:
        blocked_directions.append(direction)
    
    # Timer to unblock
    await get_tree().create_timer(turns).timeout
    blocked_directions.erase(direction)
```

### Update Freeze Timers
```gdscript
func update_freeze_timers():
    for y in range(grid_size):
        for x in range(grid_size):
            var tile = grid[y][x]
            if tile != null and tile.is_frozen:
                tile.freeze_turns -= 1
                if tile.freeze_turns <= 0:
                    tile.is_frozen = false
                    tile.remove_freeze_effect()
```

---

## 🛠️ Utilities

### Move Tile
```gdscript
func move_tile(tile: Tile, from: Vector2i, to: Vector2i):
    # Update grid
    grid[from.y][from.x] = null
    grid[to.y][to.x] = tile
    
    # Update tile
    tile.grid_position = to
    
    # Animation
    var screen_pos = calculate_screen_position(to)
    tile.move_to_position(screen_pos)
```

### Destroy Tile
```gdscript
func destroy_tile(tile: Tile):
    var pos = tile.grid_position
    grid[pos.y][pos.x] = null
    tile.destroy_animation()
```

### Get Tile
```gdscript
func get_tile_at(position: Vector2i) -> Tile:
    if position.x < 0 or position.x >= grid_size:
        return null
    if position.y < 0 or position.y >= grid_size:
        return null
    return grid[position.y][position.x]
```

---

## 🎨 Grid.gd (Visual)

### Responsibilities
- Grid display
- Tile container
- Position calculation

```gdscript
extends Control

const TILE_SIZE = 240
const TILE_SPACING = 20

func add_tile(tile: Tile):
    add_child(tile)
    var screen_pos = calculate_screen_position(tile.grid_position)
    tile.position = screen_pos

func calculate_screen_position(grid_pos: Vector2i) -> Vector2:
    var x = TILE_SPACING + grid_pos.x * (TILE_SIZE + TILE_SPACING)
    var y = TILE_SPACING + grid_pos.y * (TILE_SIZE + TILE_SPACING)
    return Vector2(x, y)
```

---

## ✅ Implementation Checklist

- [ ] Create `managers/GridManager.gd` (AutoLoad)
- [ ] Create `objects/Grid.gd` and `Grid.tscn`
- [ ] Implement `initialize_grid()`
- [ ] Implement `spawn_random_tile()`
- [ ] Implement 4 movement functions
- [ ] Implement `process_fusions()`
- [ ] Implement `has_valid_moves()`
- [ ] Implement freeze system
- [ ] Test each direction individually
- [ ] Test simple fusions
- [ ] Test game over detection
