extends Node
class_name GridPathfinder

func find_path(start: Vector2i, goal: Vector2i, location: String, tilemap: TileMap) -> Array[Vector2i]:
	var astar := AStarGrid2D.new()
	astar.region = tilemap.get_used_rect()
	astar.cell_size = Vector2i(1, 1)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER

	var region := astar.region
	for x in range(region.position.x, region.position.x + region.size.x):
		for y in range(region.position.y, region.position.y + region.size.y):
			var cell := Vector2i(x, y)
			if not is_walkable(cell, location, tilemap):
				astar.set_point_solid(cell, true)

	# Update the grid after marking solid points
	astar.update()

	var path = astar.get_id_path(start, goal)
	return path

func is_walkable(tile: Vector2i, location: String, tilemap: TileMap) -> bool:
	var data = tilemap.get_cell_tile_data(0, tile)
	if data and data.get_custom_data("blocked"):
		return false

	if TileOccupancy.is_occupied(location, tile):
		return false

	return true
