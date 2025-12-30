extends Node

class_name GridMover

@export var tile_size := 32
@export var move_speed := 3.0
@export var move_repeat_delay := 0.0

var is_moving := false
var current_tile: Vector2i
var target_world_pos: Vector2
var move_timer := 0.0

func setup(start_world_pos: Vector2):
	current_tile = world_to_tile(start_world_pos)
	return tile_to_world(current_tile)

func update(delta, owner: CharacterBody2D):
	if is_moving:
		move_towards_target(delta, owner)
		return

	move_timer -= delta

func try_move(dir: Vector2i, owner: CharacterBody2D, can_move_cb: Callable, location: String) -> bool:
	var next_tile := current_tile + dir

	if TileOccupancy.is_occupied(location, next_tile):
		return false

	if not can_move_cb.call(next_tile):
		return false

	TileOccupancy.vacate(location, current_tile)
	TileOccupancy.occupy(location, next_tile, owner)

	current_tile = next_tile
	target_world_pos = tile_to_world(current_tile)
	is_moving = true
	move_timer = move_repeat_delay
	return true


func move_towards_target(delta, owner: CharacterBody2D):
	var step = move_speed * tile_size * delta
	owner.global_position = owner.global_position.move_toward(target_world_pos, step)

	if owner.global_position.distance_to(target_world_pos) < 0.5:
		owner.global_position = target_world_pos
		is_moving = false

# --- tile utils ---

func world_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / tile_size), floor(pos.y / tile_size))

func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * tile_size + tile_size / 2,
				   tile.y * tile_size + tile_size / 2)

func snap_owner_to_grid(owner: Node2D):
	current_tile = world_to_tile(owner.global_position)
	owner.global_position = tile_to_world(current_tile)
	is_moving = false
