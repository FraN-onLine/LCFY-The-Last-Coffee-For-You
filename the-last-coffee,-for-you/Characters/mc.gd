extends CharacterBody2D

@export var tile_size := 32
@export var move_speed := 3 # tiles per second
@export var move_repeat_delay := 0 # delay when holding key
@export var inv: Inventory

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var held_item_sprite: Sprite2D = $HeldItemSprite

var paused := false
var is_moving := false

var current_tile: Vector2i
var target_world_pos: Vector2

var held_dir := Vector2i.ZERO
var move_timer := 0.0

var direction := "-down"
var animation := "idle"

# ----------------------------
# READY
# ----------------------------

func _ready():
	current_tile = world_to_tile(global_position)
	global_position = tile_to_world(current_tile)

# ----------------------------
# PROCESS
# ----------------------------

func _physics_process(delta):
	if Global.is_paused or paused:
		play_idle_animation()
		return

	if is_moving:
		move_towards_target(delta)
		return

	handle_held_input(delta)
	update_animation()

# ----------------------------
# INPUT (HOLD-BASED)
# ----------------------------

func handle_held_input(delta):
	move_timer -= delta

	var dir := get_input_direction()
	if dir == Vector2i.ZERO:
		move_timer = 0
		return

	held_dir = dir

	if move_timer > 0:
		return

	try_start_move(dir)

func get_input_direction() -> Vector2i:
	if Input.is_action_pressed("up"):
		direction = "-up"
		return Vector2i.UP
	if Input.is_action_pressed("down"):
		direction = "-down"
		return Vector2i.DOWN
	if Input.is_action_pressed("left"):
		direction = "-left"
		return Vector2i.LEFT
	if Input.is_action_pressed("right"):
		direction = "-right"
		return Vector2i.RIGHT
	return Vector2i.ZERO

# ----------------------------
# MOVEMENT
# ----------------------------

func try_start_move(dir: Vector2i):
	var next_tile := current_tile + dir
	if not can_move_to_tile(next_tile):
		return

	current_tile = next_tile
	target_world_pos = tile_to_world(current_tile)
	is_moving = true
	move_timer = move_repeat_delay

func move_towards_target(delta):
	var step = move_speed * tile_size * delta
	global_position = global_position.move_toward(target_world_pos, step)

	if global_position.distance_to(target_world_pos) < 0.5:
		global_position = target_world_pos
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
		tile.x * tile_size + tile_size / 2,
		tile.y * tile_size + tile_size / 2
	)

func can_move_to_tile(tile: Vector2i) -> bool:
	# Replace with TileMap collision later
	return true

# ----------------------------
# ANIMATION
# ----------------------------

func update_animation():
	animation = "walk" if is_moving else "idle"
	animation += direction

	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		var s = inv.slots[inv_ui.selected_index]
		if s.item:
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
	held_item_sprite.texture = texture
	held_item_sprite.visible = texture != null
