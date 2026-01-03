extends CharacterBody2D

# ----------------------------
# DATA
# ----------------------------
@export var npc_data: NPCData
@onready var collision_tilemap: TileMapLayer = get_tree().get_first_node_in_group("collision_tilemap")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ----------------------------
# GRID MOVEMENT
# ----------------------------
@onready var mover: GridMover = GridMover.new()

var current_path: Array[Vector2i] = []
var path_index := 0
var last_dir := Vector2i.DOWN

# ----------------------------
# STATE
# ----------------------------


# ----------------------------
# PORTRAITS
# ----------------------------
var normal_portrait: Texture2D
var angry_portrait: Texture2D
var joyous_portrait: Texture2D
var worried_portrait: Texture2D
var sad_portrait: Texture2D

# ----------------------------
# READY
# ----------------------------
func _ready():
	# Portraits from data
	normal_portrait = npc_data.normal_portrait
	angry_portrait = npc_data.angry_portrait
	joyous_portrait = npc_data.joyous_portrait
	worried_portrait = npc_data.worried_portrait
	sad_portrait = npc_data.sad_portrait

	# Grid mover
	add_child(mover)
	mover.move_speed = 3.0
	mover.move_repeat_delay = 0.0

	# Grid-safe spawn
	NpcState.current_location[npc_data.name] = npc_data.current_location
	mover.setup(global_position)
	mover.snap_owner_to_grid(self)
	TileOccupancy.occupy(NpcState.current_location[npc_data.name], mover.current_tile, self)

	set_daily_schedule()
	play_idle_animation()

	Global.connect("new_day", new_day)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

# ----------------------------
# DAY SYSTEM
# ----------------------------
func new_day():
	reset_interaction()
	set_daily_schedule()

func reset_interaction():
	NpcState.interacted_today[npc_data.name] = false
	NpcState.gifted_today[npc_data.name] = false

# ----------------------------
# SCHEDULING
# ----------------------------
func set_daily_schedule():
	current_path.clear()
	path_index = 0
	NpcState.available_today[npc_data.name] = false

	for schedule in npc_data.schedules:
		if not is_schedule_active(schedule):
			continue

		# Move NPC cleanly to schedule start
		TileOccupancy.vacate(NpcState.current_location[npc_data.name], mover.current_tile)
		NpcState.current_location[npc_data.name] = schedule.location
		mover.current_tile = schedule.from_tile
		mover.snap_owner_to_grid(self)
		TileOccupancy.occupy(NpcState.current_location[npc_data.name], mover.current_tile, self)

		current_path = Pathfind.find_path(
			schedule.from_tile,
			schedule.to_tile,
			NpcState.current_location[npc_data.name],
			collision_tilemap
		)

		NpcState.available_today[npc_data.name] = true
		return

func is_schedule_active(schedule: NPCSchedule) -> bool:
	if Global.current_day < schedule.min_day or Global.current_day > schedule.max_day:
		return false

	var time := Global.current_hour * 60 + Global.current_minute
	return time >= schedule.start_time and time <= schedule.end_time

# ----------------------------
# PROCESS
# ----------------------------
func _physics_process(delta):
	if Global.is_paused:
		return

	mover.update(delta, self)

	# Still moving → animate
	if mover.is_moving:
		update_walk_animation()
		return

	# No path → idle
	if path_index >= current_path.size():
		play_idle_animation()
		return

	var next_tile := current_path[path_index]

	# Already arrived
	if next_tile == mover.current_tile:
		path_index += 1
		return

	var dir := next_tile - mover.current_tile

	# Only cardinal movement allowed
	if abs(dir.x) + abs(dir.y) != 1:
		path_index += 1
		return

	if mover.try_move(dir, self, can_move_to_tile, NpcState.current_location[npc_data.name]):
		last_dir = dir
		update_walk_animation()

# ----------------------------
# COLLISION
# ----------------------------
func can_move_to_tile(tile: Vector2i) -> bool:
	if not collision_tilemap:
		return true

	var data = collision_tilemap.get_cell_tile_data(tile)
	if data and data.get_custom_data("Blocked"):
		return false

	return true

# ----------------------------
# INTERACTION
# ----------------------------
func interact_from(player):
	if Global.is_paused:
		return
	if not is_player_adjacent(player):
		return

	face_player(player)
	interact_with_npc()

func is_player_adjacent(player) -> bool:
	var diff = player.mover.current_tile - mover.current_tile
	return abs(diff.x) + abs(diff.y) == 1

func face_player(player):
	var diff = player.mover.current_tile - mover.current_tile
	if abs(diff.x) + abs(diff.y) != 1:
		return

	last_dir = diff
	play_idle_animation()

# ----------------------------
# INTERACTION LOGIC
# ----------------------------
func interact_with_npc():
	# Meet > Gift > Interact first
	if not NpcState.met[npc_data.name] and npc_data.has_first_meet_dialogue:
		Global.is_paused = true
		DialogueManager.show_dialogue_balloon(npc_data.dialogue_path, "first_meet")
		await get_tree().process_frame
		get_tree().get_first_node_in_group("dialogue_balloon").change_portrait(normal_portrait)

		Global.is_paused = true
		NpcState.interacted_today[npc_data.name] = true
		NpcState.met[npc_data.name] = true
		return

	if not NpcState.gifted_today[npc_data.name]:
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		if inv_ui:
			var inv = inv_ui.inv
			var slot_index = inv_ui.selected_index
			var slot = inv.slots[slot_index]
			if slot.item:
				handle_gift(slot.item, inv, slot_index, inv_ui)
				return

	if not NpcState.interacted_today[npc_data.name]:
		Global.is_paused = true
		var key := "day" + str(Global.current_day)
		DialogueManager.show_dialogue_balloon(npc_data.dialogue_path, key)
		await get_tree().process_frame
		get_tree().get_first_node_in_group("dialogue_balloon").change_portrait(normal_portrait)
		NpcState.interacted_today[npc_data.name] = true
		NpcState.met[npc_data.name] = true

func handle_gift(item, inv, slot_index, inv_ui):
	var reaction_key := "neutral"
	var portrait := normal_portrait

	if npc_data.loved_items.has(item):
		reaction_key = "liked"
		npc_data.friendship += 10
		portrait = joyous_portrait
		NpcState.liked_giftcount[npc_data.name] += 1
		if NpcState.liked_giftcount[npc_data.name] == 3:
			reaction_key = "liked_gifted_thrice"
	elif npc_data.hated_items.has(item):
		reaction_key = "hated"
		portrait = worried_portrait
	else:
		npc_data.friendship += 5

	inv.remove_one_from_slot(slot_index)
	inv_ui.update_slots()

	DialogueManager.show_dialogue_balloon(npc_data.dialogue_path, reaction_key)
	await get_tree().process_frame
	get_tree().get_first_node_in_group("dialogue_balloon").change_portrait(portrait)

	Global.is_paused = true
	NpcState.gifted_today[npc_data.name] = true

# ----------------------------
# DIALOGUE END
# ----------------------------
func _on_dialogue_ended(_res):
	Global.is_paused = false
	
	play_idle_animation()

# ----------------------------
# ANIMATION (FIXED)
# ----------------------------
func update_walk_animation():
	if abs(last_dir.x) > abs(last_dir.y):
		play_animation("walk-right" if last_dir.x > 0 else "walk-left")
	else:
		play_animation("walk-down" if last_dir.y > 0 else "walk-up")

func play_idle_animation():
	if abs(last_dir.x) > abs(last_dir.y):
		play_animation("idle-right" if last_dir.x > 0 else "idle-left")
	else:
		play_animation("idle-down" if last_dir.y > 0 else "idle-up")

func play_animation(anim_name: String):
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
