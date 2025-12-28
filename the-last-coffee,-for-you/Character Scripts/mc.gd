extends CharacterBody2D

@export var speed := 160
var paused: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@export var inv: Inventory
@onready var held_item_sprite: Sprite2D = $HeldItemSprite
var animation: String = "idle"
var direction: String = "-up"

func set_held_item_texture(texture: Texture2D):
	held_item_sprite.texture = texture
	held_item_sprite.visible = texture != null
	$ItemCollision.disabled = texture == null

func _physics_process(delta):
	if Global.is_paused or paused:
		animation = "idle"
		animation = animation + direction 
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		var slot_index = inv_ui.selected_index
		var s = inv.slots[slot_index]
		if s.item:
			animation = animation + "-hold"
		anim_sprite.animation = animation
		anim_sprite.play()
		return
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input_vector = input_vector.normalized()
	velocity = input_vector * speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		animation = "walk"
		if abs(input_vector.x) > abs(input_vector.y):
			if input_vector.x < 0:
				direction = "-left"
			else:
				direction = "-right"
		elif input_vector.y < 0:
			direction = "-up"
		else:
			direction = "-down"
		animation = animation + direction 
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		var slot_index = inv_ui.selected_index
		var s = inv.slots[slot_index]
		if s.item:
			animation = animation + "-hold"
		anim_sprite.animation = animation
		anim_sprite.play()
	else:
		animation = "idle"
		animation = animation + direction 
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		var slot_index = inv_ui.selected_index
		var s = inv.slots[slot_index]
		if s.item:
			animation = animation + "-hold"
		anim_sprite.animation = animation
		anim_sprite.play()
