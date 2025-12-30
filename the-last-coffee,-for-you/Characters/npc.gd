extends CharacterBody2D

# ----------------------------
# DATA
# ----------------------------
@export var npc_data: NPCData
@export var collision_tilemap: TileMap

# ----------------------------
# GRID MOVEMENT
# ----------------------------
@onready var mover: GridMover = GridMover.new()

var current_path: Array[Vector2i] = []
var path_index := 0

# ----------------------------
# STATE
# ----------------------------
var interacted_today := false
var gifted_today := false
var liked_giftcount := 0
var met := false
var available_today := true
var current_location = "room"

# ----------------------------
# PORTRAITS
# ----------------------------
var normal_portrait = preload("res://Assets/Characters/AIleen/Aileen-Normal.png")
var angry_portrait = preload("res://Assets/Characters/AIleen/Aileen-Angry.png")
var joyous_portrait = preload("res://Assets/Characters/AIleen/Aileen-Joyous.png")
var worried_portrait = preload("res://Assets/Characters/AIleen/Aileen-Worried.png")
var sad_portrait = preload("res://Assets/Characters/AIleen/Aileen-Sad.png")

# ----------------------------
# READY
# ----------------------------
func _ready():
	add_child(mover)
	mover.move_speed = 3.0
	mover.move_repeat_delay = 0.0
	global_position = mover.setup(global_position)
	TileOccupancy.occupy(current_location, mover.current_tile, self)


	set_daily_schedule()
	play_animation("idle-right")

	$InteractionArea.input_event.connect(_on_interaction_area_input)
	Global.connect("new_day", new_day)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

# ----------------------------
# DAY SYSTEM
# ----------------------------
func new_day():
	reset_interaction()
	set_daily_schedule()

func reset_interaction():
	interacted_today = false
	gifted_today = false

# ----------------------------
# SCHEDULING
# ----------------------------
func set_daily_schedule():
	current_path.clear()
	path_index = 0
	available_today = false

	var day := Global.current_day
	if npc_data.schedule.has(day):
		current_path = npc_data.schedule[day]
		available_today = true

# ----------------------------
# PROCESS
# ----------------------------
func _physics_process(delta):
	if Global.is_paused:
		return

	mover.update(delta, self)

	if mover.is_moving:
		update_walk_animation()
		return

	if current_path.size() > 0 and path_index < current_path.size():
		var next_tile := current_path[path_index]
		if mover.try_move(next_tile - mover.current_tile, self, can_move_to_tile, current_location):
			update_walk_animation()
		else:
			path_index += 1
	elif path_index < current_path.size():
		path_index += 1
	else:
		play_animation("idle-right")

# ----------------------------
# COLLISION
# ----------------------------
func can_move_to_tile(tile: Vector2i) -> bool:
	if not collision_tilemap:
		return true

	var data := collision_tilemap.get_cell_tile_data(collision_layer, tile)
	if data == null:
		return true

	return not data.get_custom_data("blocked")

# ----------------------------
# INTERACTION (TAP TILE)
# ----------------------------
func _on_interaction_area_input(viewport, event, shape_idx):
	if not available_today:
		return
	if not event.is_action_pressed("interact"):
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	#if not is_player_adjacent(player):
		#return

	interact_with_npc()

func is_player_adjacent(player) -> bool:
	var player_tile: Vector2i = player.mover.current_tile
	var my_tile: Vector2i = mover.current_tile
	var diff := player_tile - my_tile
	return abs(diff.x) + abs(diff.y) == 1

# ----------------------------
# INTERACTION LOGIC
# ----------------------------
func interact_with_npc():
	if gifted_today == false:
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		if inv_ui:
			var inv = inv_ui.inv
			var slot_index = inv_ui.selected_index
			var s = inv.slots[slot_index]
			if s.item:
				handle_gift(s.item, inv, slot_index, inv_ui)
				return

	if not interacted_today:
		var day_key = "day" + str(Global.current_day)
		DialogueManager.show_dialogue_balloon(npc_data.dialogue_path, day_key)
		get_tree().get_first_node_in_group("dialogue_balloon").change_portrait(normal_portrait)
		Global.is_paused = true
		interacted_today = true
		met = true

func handle_gift(item, inv, slot_index, inv_ui):
	var reaction_key := "neutral"
	var portrait = normal_portrait

	if npc_data.loved_items.has(item):
		reaction_key = "liked"
		portrait = joyous_portrait
		liked_giftcount += 1
		if liked_giftcount == 3:
			reaction_key = "liked_gifted_thrice"
	elif npc_data.hated_items.has(item):
		reaction_key = "hated"
		portrait = worried_portrait

	inv.remove_one_from_slot(slot_index)
	inv_ui.update_slots()

	DialogueManager.show_dialogue_balloon(npc_data.dialogue_path, reaction_key)
	get_tree().get_first_node_in_group("dialogue_balloon").change_portrait(portrait)

	Global.is_paused = true
	gifted_today = true

# ----------------------------
# DIALOGUE END
# ----------------------------
func _on_dialogue_ended(_res):
	Global.is_paused = false

# ----------------------------
# ANIMATION
# ----------------------------
func update_walk_animation():
	play_animation("walk-right")

func play_animation(anim_type: String):
	if npc_data and npc_data.animations.has(anim_type):
		$AnimatedSprite2D.play(npc_data.animations[anim_type])
