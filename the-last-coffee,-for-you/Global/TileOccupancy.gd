extends Node

# location → { Vector2i : Node }
var occupied_tiles := {}

func _ready():
	occupied_tiles.clear()

func is_occupied(location: String, tile: Vector2i) -> bool:
	return occupied_tiles.has(location) and occupied_tiles[location].has(tile)

func occupy(location: String, tile: Vector2i, who: Node):
	if not occupied_tiles.has(location):
		occupied_tiles[location] = {}
	occupied_tiles[location][tile] = who

func vacate(location: String, tile: Vector2i):
	if occupied_tiles.has(location):
		occupied_tiles[location].erase(tile)
