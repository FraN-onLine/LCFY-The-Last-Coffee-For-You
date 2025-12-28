extends Node2D

@export var container_inventory: Inventory
const ContainerUI = preload("res://UI/container_ui.tscn")

var player_nearby := false

func _ready():
	$ProximityArea.body_entered.connect(Callable(self, "_on_proximity_entered"))
	$ProximityArea.body_exited.connect(Callable(self, "_on_proximity_exited"))
	$InteractionArea.input_event.connect(Callable(self, "_on_interaction_area_input"))

func _on_proximity_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_proximity_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _on_interaction_area_input(viewport, event, shape_idx):
	if player_nearby and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		open_container_ui()

func open_container_ui():
	var ui = ContainerUI.instantiate()
	ui.container_inventory = container_inventory
	var canvas_layer = get_tree().current_scene.get_node("UI") # Adjust if needed
	canvas_layer.add_child(ui)
