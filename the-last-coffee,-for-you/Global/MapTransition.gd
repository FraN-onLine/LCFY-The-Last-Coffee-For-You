extends Node

var pending_spawn_id := 0
var pending_map := ""

func change_map(map_name: String, spawn_id: int, player):
	pending_map = map_name
	pending_spawn_id = spawn_id
	get_tree().change_scene_to_file(
		"res://Areas/%s.tscn" % map_name
	)
	
	if get_tree():
		print("here")
		await get_tree().create_timer(0.005).timeout
		
		var spawn_parent = get_tree().get_first_node_in_group("spawnpoints")
		if not spawn_parent:
			push_error("SpawnPoints missing in map")
			return
		var spawn = spawn_parent.get_node_or_null("Spawn_%d" % pending_spawn_id)
		if not spawn:
			push_error("Spawn_%d missing" % pending_spawn_id)
			return
		player = get_tree().get_first_node_in_group("player")
		TileOccupancy.vacate(map_name, player.mover.current_tile)
		player.global_position = spawn.global_position
		player.mover.snap_owner_to_grid(player)
		TileOccupancy.vacate(map_name, player.mover.current_tile)
		print("snapped")

func place_player(player: Node2D):
	var spawn_parent = get_tree().current_scene.get_node_or_null("spawnpoints")
	if not spawn_parent:
		push_error("spawnpoints missing in map")
		return

	var spawn = spawn_parent.get_node_or_null("Spawn_%d" % pending_spawn_id)
	if not spawn:
		push_error("Spawn_%d missing" % pending_spawn_id)
		return

	player.global_position = spawn.global_position
	player.mover.snap_owner_to_grid(player)
