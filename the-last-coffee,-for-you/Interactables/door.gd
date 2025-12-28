extends StaticBody2D

@export var locked: bool = false
@export var locked_popup_text: String = "The door is locked."
@export var open_popup_text: String = "You open the door."
var popup_instance: Node = null
const PopupText = preload("res://Interactables/pop_up_text.tscn")
var closed = true

var player_nearby := false

func _ready():
	$Area2D.body_entered.connect(_on_body_entered)
	$Area2D.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _input(event):
	if player_nearby and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if locked:
			show_popup(locked_popup_text)
		elif closed:
			open_door()
			show_popup(open_popup_text)
		else: 
			close_door()	
			

func show_popup(text):
	if popup_instance:
		popup_instance.queue_free()
	var popup = PopupText.instantiate()
	add_child(popup)
	popup_instance = popup
	popup.show_popup(text)

func open_door():
	closed = false
	$CollisionShape2D.disabled = true
	$Sprite2D.texture.region = Rect2(32,192, 32, 32)
	
func close_door():
	closed = true
	$CollisionShape2D.disabled = false
	$Sprite2D.texture.region = Rect2(32,160, 32, 32)
