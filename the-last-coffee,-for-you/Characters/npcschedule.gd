extends Resource
class_name NPCSchedule

@export var min_day := 1
@export var max_day := 999

@export var location := "room"

# Minutes since midnight
@export var start_time := 600
@export var end_time := 720

@export var from_tile: Vector2i
@export var to_tile: Vector2i
