extends Node2D

@export var popup_text: String = "You interacted with me!"

var popup_instance: Node = null
const PopupText = preload("res://Interactables/pop_up_text.tscn")

func _ready():
	$Area2D.input_event.connect(_on_area_input_event)

func _on_area_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		show_popup()

func show_popup():
	if popup_instance:
		popup_instance.queue_free()
	var popup = PopupText.instantiate()
	add_child(popup)
	popup_instance = popup
	popup.show_popup(popup_text)
