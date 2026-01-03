extends Resource
class_name NPCData

@export var name: String
@export var friendship: int = 0

# -------- SCHEDULES --------
@export var schedules: Array[NPCSchedule] = []
@export var current_location = "room"
@export var has_first_meet_dialogue: bool = false

# -------- CUTSCENES --------
@export var cutscenes: Array[NPCCutscene] = []

# -------- DIALOGUE / ITEMS --------
@export var loved_items: Array[Inventory_Item]
@export var hated_items: Array[Inventory_Item]
@export var dialogue_path: DialogueResource

# --------- PORTRAITS ----------
@export var normal_portrait: Texture2D
@export var joyous_portrait: Texture2D
@export var sad_portrait: Texture2D
@export var angry_portrait: Texture2D
@export var worried_portrait: Texture2D
