extends CharacterBody2D

# ----------------------------
# MOVEMENT
# ----------------------------
@onready var collision_tilemap: = get_tree().get_first_node_in_group("collision_tilemap")

@onready var mover: GridMover = GridMover.new()

# ----------------------------
# INVENTORY / VISUALS
# ----------------------------
@export var inv: Inventory
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var held_item_sprite: Sprite2D = $HeldItemSprite

# ----------------------------
# STATE
# ----------------------------
var paused := false
var direction := "-down"
var animation := "idle"
var current_location = "room"

# ----------------------------
# INVENTORY
# ----------------------------
const ContainerUI = preload("res://UI/container_ui.tscn")

var open_container_ui: Control = null

func open_container(container_id, container_inventory):
	# Prevent duplicate UI
	if open_container_ui and is_instance_valid(open_container_ui):
		return

	Global.is_paused = true

	var ui = ContainerUI.instantiate()
	ui.container_inventory = container_inventory
	var canvas_layer = get_tree().current_scene.get_node("UI") # Adjust if needed
	canvas_layer.add_child(ui)




# ----------------------------
# READY
# ----------------------------
func _ready():
	add_child(mover)
	mover.move_speed = 4.0
	mover.move_repeat_delay = 0.0
	global_position = mover.setup(global_position)
	TileOccupancy.occupy(current_location, mover.current_tile, self)

	MapTransitionManager.place_player(self)
	Global.is_paused = false


# ----------------------------
# PROCESS
# ----------------------------
func _physics_process(delta):
	if Global.is_paused or paused:
		play_idle_animation()
		return

	mover.update(delta, self)

	if mover.is_moving:
		update_animation(null)
		return

	if not mover.is_moving:
		check_teleport_tile()

	var dir := get_input_direction()
	if dir != Vector2i.ZERO:
		direction = dir_to_anim(dir)

		# Try to move; if blocked, we still turn in place
		mover.try_move(dir, self, can_move_to_tile, current_location)
		update_animation(dir)
	else:
		update_animation(dir)

func check_teleport_tile():
	var tilemap: TileMapLayer = get_tree().get_first_node_in_group("collision_tilemap")
	if not tilemap:
		return

	var data = tilemap.get_cell_tile_data(mover.current_tile)
	if not data:
		return

	if not data.get_custom_data("teleport"):
		return

	var target_map = data.get_custom_data("target_map")
	var spawn_id = int(data.get_custom_data("spawn_id"))

	Global.is_paused = true
	TileOccupancy.vacate(current_location, mover.current_tile)
	MapTransitionManager.change_map(target_map, spawn_id, self)


# ----------------------------
# INPUT
# ----------------------------
func get_input_direction() -> Vector2i:
	if Input.is_action_pressed("up"):
		return Vector2i.UP
	if Input.is_action_pressed("down"):
		return Vector2i.DOWN
	if Input.is_action_pressed("left"):
		return Vector2i.LEFT
	if Input.is_action_pressed("right"):
		return Vector2i.RIGHT
	return Vector2i.ZERO

func _input(event):
	if Global.is_paused:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tile_tap(event.position)

func _unhandled_input(event):
	if Global.is_paused:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_tile_tap(event.position)

func handle_tile_tap(screen_pos: Vector2):
	var world_pos = get_global_mouse_position()
	var tapped_tile: Vector2i = mover.world_to_tile(world_pos)

	# --- NPC / entity interaction first ---
	var occupant = TileOccupancy.get_occupant(current_location, tapped_tile)
	if occupant and occupant.has_method("interact_from"):
		occupant.interact_from(self)
		return

	# --- Container tile interaction ---
	try_open_container_tile(tapped_tile)

func try_open_container_tile(tile: Vector2i):
	if Global.is_paused:
		return

	if not is_adjacent_to_tile(tile):
		return

	var tilemap: TileMapLayer = collision_tilemap
	if not tilemap:
		return

	var data = tilemap.get_cell_tile_data(tile)
	if not data:
		return

	if not data.get_custom_data("container"):
		return
	if not data.get_custom_data("container_inventory"):
		return

	var container_id = data.get_custom_data("container_id")
	var container_inventory = data.get_custom_data("container_inventory")
	if container_id == null:
		push_error("Container tile missing container_id")
		return

	open_container(container_id, container_inventory)

func is_adjacent_to_tile(tile: Vector2i) -> bool:
	var diff := tile - mover.current_tile
	return abs(diff.x) + abs(diff.y) == 1



func dir_to_anim(dir: Vector2i) -> String:
	match dir:
		Vector2i.UP: return "-up"
		Vector2i.DOWN: return "-down"
		Vector2i.LEFT: return "-left"
		Vector2i.RIGHT: return "-right"
		_: return direction

# ----------------------------
# COLLISION
# ----------------------------
func can_move_to_tile(tile: Vector2i) -> bool:
	if not collision_tilemap:
		return true

	var data = collision_tilemap.get_cell_tile_data(tile)
	if data == null:
		return true

	return not data.get_custom_data("Blocked")

# ----------------------------
# ANIMATION
# ----------------------------
func update_animation(dir):
	animation = "walk" if (mover.is_moving or dir != Vector2i.ZERO) else "idle"
	animation += direction
	var inv_ui = null
	if get_tree():
		inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		var slot = inv.slots[inv_ui.selected_index]
		if slot.item:
			animation += "-hold"

	anim_sprite.animation = animation
	anim_sprite.play()

func play_idle_animation():
	anim_sprite.animation = "idle" + direction
	anim_sprite.play()

# ----------------------------
# HELD ITEM
# ----------------------------
func set_held_item_texture(texture: Texture2D):
	if held_item_sprite:
		held_item_sprite.texture = texture
		held_item_sprite.visible = texture != null
