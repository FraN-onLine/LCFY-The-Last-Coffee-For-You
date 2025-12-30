extends Resource
class_name NPCData

@export var name: String
@export var friendship: int = 0

# -------- SCHEDULES --------
@export var schedules: Array[NPCSchedule] = []

# -------- CUTSCENES --------
@export var cutscenes: Array[NPCCutscene] = []

# -------- DIALOGUE / ITEMS --------
@export var animations: Dictionary
@export var loved_items: Array[Inventory_Item]
@export var hated_items: Array[Inventory_Item]
@export var dialogue_path: DialogueResource
