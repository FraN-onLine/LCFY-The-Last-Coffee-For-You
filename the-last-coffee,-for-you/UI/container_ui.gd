extends Control

@export var container_inventory: Inventory
@onready var container_slots: Array = $NinePatchRect/GridContainer.get_children()
const PopupText = preload("res://Interactables/pop_up_text.tscn")

var player_inventory: Inventory = null
var player_slots: Array = []
var player_selected_index: int = 0
@onready var popup_instance: Node = null

signal ui_closed

func _ready():
	add_to_group("container_ui")
	container_inventory.slot_updated.connect(update_slots)
	get_tree().paused = true
	# Find player and their inventory
	var player = get_tree().get_first_node_in_group("player")
	if player.inv:
		player_inventory = player.inv
		var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
		if inv_ui:
			player_slots = inv_ui.slots
			# Connect player slot signals
			for i in range(player_slots.size()):
				player_slots[i].slot_index = i
				print(i)
				if not player_slots[i].is_connected("slot_clicked", Callable(self, "_on_player_slot_clicked")):
					player_slots[i].connect("slot_clicked", Callable(self, "_on_player_slot_clicked"))
					print("yes")
	update_slots()
	# Connect container slot signals
	for i in range(container_slots.size()):
		container_slots[i].slot_index = i
		if not container_slots[i].is_connected("slot_clicked", Callable(self, "_on_container_slot_clicked")):
			container_slots[i].connect("slot_clicked", Callable(self, "_on_container_slot_clicked"))
	if player:
		player.paused = true
	var time_ui = get_tree().current_scene.get_node("UI/TimeUI")
	if time_ui:
		time_ui.paused = true

func update_slots():
	for i in range(min(container_inventory.slots.size(), container_slots.size())):
		container_slots[i].update(container_inventory.slots[i])
	for s in container_slots:
		s.modulate = Color(1, 1, 1, 1)

func _on_container_slot_clicked(container_index):
	print(container_index)
	transfer_item_from_container_to_player(container_index)

func _on_player_slot_clicked(player_index):
	transfer_item_from_player_to_container(player_index)

func transfer_item_from_player_to_container(player_index):
	if not player_inventory:
		show_popup("No player inventory found!")
		return
	var player_slot = player_inventory.slots[player_index]
	if player_slot.item == null:
		return # Don't show popup if empty
	# Find first empty or matching container slot
	for container_slot in container_inventory.slots:
		if container_slot.item == null or container_slot.item == player_slot.item:
			if container_slot.item == null:
				container_slot.item = player_slot.item
				container_slot.amount = player_slot.amount
			else:
				container_slot.amount += player_slot.amount
			player_slot.item = null
			player_slot.amount = 0
			update_slots()
			update_player_ui()
			return
	show_popup("Chest full!")

func transfer_item_from_container_to_player(container_index):
	if not player_inventory:
		show_popup("No player inventory found!")
		return
	var container_slot = container_inventory.slots[container_index]
	if container_slot.item == null:
		return # Don't show popup if empty
	# Find first empty or matching player slot
	for player_slot in player_inventory.slots:
		if player_slot.item == null or player_slot.item == container_slot.item:
			if player_slot.item == null:
				player_slot.item = container_slot.item
				player_slot.amount = container_slot.amount
			else:
				player_slot.amount += container_slot.amount
			container_slot.item = null
			container_slot.amount = 0
			update_slots()
			update_player_ui()
			return
	show_popup("Inventory full!")

func get_player_selected_index():
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		return inv_ui.selected_index
	return 0

func update_player_ui():
	var inv_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inv_ui:
		inv_ui.update_slots()

func show_popup(text):
	if popup_instance:
		popup_instance.queue_free()
	popup_instance = PopupText.instantiate()
	add_child(popup_instance)
	popup_instance.show_popup(text)

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_ui()

func close_ui():
	get_tree().paused = false
	emit_signal("ui_closed")
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.paused = false
	var time_ui = get_tree().current_scene.get_node("UI/TimeUI")
	if time_ui:
		time_ui.paused = false
	queue_free()
