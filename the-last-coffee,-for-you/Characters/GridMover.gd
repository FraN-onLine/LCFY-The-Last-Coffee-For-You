extends Node
class_name GridMover

@export var tile_size := 32
@export var move_speed := 4.0          # tiles per second
@export var move_repeat_delay := 0.0

var is_moving := false
var current_tile: Vector2i
var target_tile: Vector2i
var target_world_pos: Vector2
var move_timer := 0.0

# ----------------------------
# SETUP
# ----------------------------
func setup(start_world_pos: Vector2) -> Vector2:
	current_tile = world_to_tile(start_world_pos)
	target_tile = current_tile
	target_world_pos = tile_to_world(current_tile)
	return target_world_pos

func snap_owner_to_grid(owner: Node2D):
	current_tile = world_to_tile(owner.global_position)
	target_tile = current_tile
	target_world_pos = tile_to_world(current_tile)
	owner.global_position = target_world_pos
	is_moving = false

# ----------------------------
# UPDATE
# ----------------------------
func update(delta: float, owner: Node2D):
	if is_moving:
		_move_towards_target(delta, owner)
		return

	if move_timer > 0.0:
		move_timer -= delta

# ----------------------------
# MOVE REQUEST
# ----------------------------
func try_move(
	dir: Vector2i,
	owner: Node2D,
	can_move_cb: Callable,
	location: String
) -> bool:
	if is_moving or move_timer > 0.0:
		return false

	# Only cardinal directions
	if abs(dir.x) + abs(dir.y) != 1:
		return false

	var next_tile := current_tile + dir

	# Hard occupancy check
	if TileOccupancy.is_occupied(location, next_tile):
		return false

	# Tile collision check
	if not can_move_cb.call(next_tile):
		return false

	# Reserve tile
	TileOccupancy.vacate(location, current_tile)
	TileOccupancy.occupy(location, next_tile, owner)

	target_tile = next_tile
	target_world_pos = tile_to_world(target_tile)
	is_moving = true
	move_timer = move_repeat_delay
	return true

# ----------------------------
# INTERNAL MOVEMENT
# ----------------------------
func _move_towards_target(delta: float, owner: Node2D):
	var step := move_speed * tile_size * delta
	owner.global_position = owner.global_position.move_toward(
		target_world_pos,
		step
	)

	if owner.global_position.distance_to(target_world_pos) <= 0.5:
		owner.global_position = target_world_pos
		current_tile = target_tile
		is_moving = false

# ----------------------------
# TILE UTILS
# ----------------------------
func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / tile_size),
		floor(pos.y / tile_size)
	)

func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(
		tile.x * tile_size + tile_size * 0.5,
		tile.y * tile_size + tile_size * 0.5
	)
