extends Node

# location → { tile : Node }
var occupied_tiles := {}

# Node → { location: String, tile: Vector2i }
var node_positions := {}

func _ready():
	occupied_tiles.clear()
	node_positions.clear()

# ----------------------------
# QUERY
# ----------------------------
func is_occupied(location: String, tile: Vector2i) -> bool:
	return (
		occupied_tiles.has(location)
		and occupied_tiles[location].has(tile)
	)

func get_occupant(location: String, tile: Vector2i) -> Node:
	if not occupied_tiles.has(location):
		return null
	return occupied_tiles[location].get(tile, null)

func get_node_tile(who: Node) -> Dictionary:
	return node_positions.get(who, {})

# ----------------------------
# OCCUPY (SAFE)
# ----------------------------
func occupy(location: String, tile: Vector2i, who: Node):
	# 🚨 Remove previous occupancy automatically
	if node_positions.has(who):
		var prev = node_positions[who]
		if occupied_tiles.has(prev.location):
			occupied_tiles[prev.location].erase(prev.tile)

	if not occupied_tiles.has(location):
		occupied_tiles[location] = {}

	occupied_tiles[location][tile] = who
	node_positions[who] = {
		"location": location,
		"tile": tile
	}

# ----------------------------
# VACATE
# ----------------------------
func vacate(location: String, tile: Vector2i):
	if not occupied_tiles.has(location):
		return

	var who = occupied_tiles[location].get(tile)
	if who:
		node_positions.erase(who)

	occupied_tiles[location].erase(tile)

# ----------------------------
# FORCE CLEANUP (scene exit safety)
# ----------------------------
func remove_node(who: Node):
	if not node_positions.has(who):
		return

	var prev = node_positions[who]
	if occupied_tiles.has(prev.location):
		occupied_tiles[prev.location].erase(prev.tile)

	node_positions.erase(who)
