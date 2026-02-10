# MovementData - Data structures for immediate logic/animation separation
# Contains all data structures needed to encapsulate movement results
class_name MovementData
extends Resource

# ============================================================================
# MAIN RESULT CLASS
# ============================================================================

## Contains all calculated changes from a movement operation
## Used to separate calculation from application and animation
class MovementResult:
	var direction: GridManager.Direction
	var has_changes: bool = false
	var moved_tiles: Array[MovedTileData] = []
	var fusions: Array[FusionData] = []
	var destroyed_tiles: Array[DestroyedTileData] = []
	var activated_powers: Array[PowerEffectData] = []
	var new_tiles: Array[NewTileData] = []
	var state_changes: StateChanges = StateChanges.new()
	
	func _init():
		state_changes = StateChanges.new()

# ============================================================================
# TILE MOVEMENT DATA
# ============================================================================

## Data for a tile that moves without fusion
class MovedTileData:
	var tile: Node
	var from_pos: Vector2i
	var to_pos: Vector2i
	
	func _init(p_tile: Node = null, p_from: Vector2i = Vector2i.ZERO, p_to: Vector2i = Vector2i.ZERO):
		tile = p_tile
		from_pos = p_from
		to_pos = p_to

# ============================================================================
# FUSION DATA
# ============================================================================

## Data for two tiles that fuse together
class FusionData:
	var tile1: Node                # Moving tile
	var tile2: Node                # Static tile  
	var result_tile: Node          # New fused tile
	var position: Vector2i         # Final position of fusion
	var power_activated: String = ""  # Power triggered by fusion
	
	func _init(p_tile1: Node = null, p_tile2: Node = null, p_result: Node = null, p_pos: Vector2i = Vector2i.ZERO, p_power: String = ""):
		tile1 = p_tile1
		tile2 = p_tile2  
		result_tile = p_result
		position = p_pos
		power_activated = p_power

# ============================================================================
# POWER EFFECT DATA
# ============================================================================

## Data for a power effect that needs to be applied immediately
class PowerEffectData:
	var power_type: String
	var source_tile: Node
	var source_position: Vector2i
	var affected_positions: Array[Vector2i] = []
	var blocked_directions: Array[GridManager.Direction] = []
	var duration: int = 0
	var destroyed_tile_positions: Array[Vector2i] = []
	
	func _init(p_power: String = "", p_tile: Node = null, p_pos: Vector2i = Vector2i.ZERO):
		power_type = p_power
		source_tile = p_tile
		source_position = p_pos

# ============================================================================
# DESTRUCTION DATA
# ============================================================================

## Data for a tile that gets destroyed
class DestroyedTileData:
	var tile: Node
	var position: Vector2i
	var cause: String  # "power", "fusion", "expel", etc.
	
	func _init(p_tile: Node = null, p_pos: Vector2i = Vector2i.ZERO, p_cause: String = ""):
		tile = p_tile
		position = p_pos
		cause = p_cause

# ============================================================================
# NEW TILE DATA
# ============================================================================

## Data for a new tile to be created
class NewTileData:
	var value: int
	var power_type: String
	var position: Vector2i
	
	func _init(p_value: int = 2, p_power: String = "", p_pos: Vector2i = Vector2i.ZERO):
		value = p_value
		power_type = p_power
		position = p_pos

# ============================================================================
# GAME STATE CHANGES
# ============================================================================

## Global state changes that need to be applied
class StateChanges:
	var move_count_increment: int = 0
	var score_addition: int = 0
	var ice_timer_decrements: Array[Vector2i] = []  # Positions where ice timer decreases
	var blocked_directions_added: Array[BlockDirectionData] = []
	var blocked_directions_removed: Array[GridManager.Direction] = []
	var game_over: bool = false
	var spawn_new_tile: bool = false
	
	func _init():
		pass

## Data for blocking a direction
class BlockDirectionData:
	var direction: GridManager.Direction
	var duration: int
	
	func _init(p_dir: GridManager.Direction = GridManager.Direction.UP, p_duration: int = 1):
		direction = p_dir
		duration = p_duration

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

## Helper functions for working with movement data
class MovementDataUtils:
	
	## Check if a MovementResult has any actual changes
	static func has_meaningful_changes(result: MovementResult) -> bool:
		return result.moved_tiles.size() > 0 or \
		       result.fusions.size() > 0 or \
		       result.destroyed_tiles.size() > 0 or \
		       result.activated_powers.size() > 0
	
	## Get all tiles involved in a movement (for animation tracking)
	static func get_all_involved_tiles(result: MovementResult) -> Array[Node]:
		var tiles: Array[Node] = []
		
		for moved in result.moved_tiles:
			if moved.tile and not tiles.has(moved.tile):
				tiles.append(moved.tile)
		
		for fusion in result.fusions:
			if fusion.tile1 and not tiles.has(fusion.tile1):
				tiles.append(fusion.tile1)
			if fusion.tile2 and not tiles.has(fusion.tile2):
				tiles.append(fusion.tile2)
			if fusion.result_tile and not tiles.has(fusion.result_tile):
				tiles.append(fusion.result_tile)
		
		for destroyed in result.destroyed_tiles:
			if destroyed.tile and not tiles.has(destroyed.tile):
				tiles.append(destroyed.tile)
		
		return tiles
	
	## Get all positions that will be affected by the movement
	static func get_all_affected_positions(result: MovementResult) -> Array[Vector2i]:
		var positions: Array[Vector2i] = []
		
		for moved in result.moved_tiles:
			if not positions.has(moved.from_pos):
				positions.append(moved.from_pos)
			if not positions.has(moved.to_pos):
				positions.append(moved.to_pos)
		
		for fusion in result.fusions:
			if not positions.has(fusion.position):
				positions.append(fusion.position)
		
		for destroyed in result.destroyed_tiles:
			if not positions.has(destroyed.position):
				positions.append(destroyed.position)
		
		for power_effect in result.activated_powers:
			for pos in power_effect.affected_positions:
				if not positions.has(pos):
					positions.append(pos)
		
		return positions
	
	## Create a summary string for debugging
	static func get_movement_summary(result: MovementResult) -> String:
		var summary = "Movement %s: " % GridManager.Direction.keys()[result.direction]
		summary += "%d moved, " % result.moved_tiles.size()
		summary += "%d fused, " % result.fusions.size()
		summary += "%d destroyed, " % result.destroyed_tiles.size()
		summary += "%d powers" % result.activated_powers.size()
		return summary