extends Resource
class_name NPCSchedule

@export var min_day := 1
@export var max_day := 999

@export var min_time := 0        # minutes since midnight
@export var max_time := 1440

@export var location := "town_proper"

@export var spawn_tile: Vector2i
@export var destination_tile: Vector2i
