extends Resource
class_name NPCData

@export var name: String
@export var friendship: int = 0
@export var schedule: Dictionary
@export var dialogues: Dictionary[int, String]
@export var animations: Dictionary
@export var loved_items: Array[Inventory_Item]
@export var hated_items: Array[Inventory_Item]
@export var dialogue_path: DialogueResource
