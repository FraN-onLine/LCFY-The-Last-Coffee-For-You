extends Node

var player_name: String = "MC"
var current_day: int = 1           # Day number (1-28, or more)
var current_hour: int = 7          # Current hour (0-23)
var current_minute: int = 0        # Current minute (0-59)
var is_new_day: bool = false       # Set true at the start of a new day, false after systems update
var player_paused: bool = false    # Used to freeze player movement (e.g. during UI/dialogue)
var npcs_paused: bool = false      # Used to freeze NPCs (e.g. during cutscenes/UI)
var is_paused: bool = false          # Global pause state for the game
var friendship: Dictionary[String, int] = {} # e.g. {"Mary": 5, "Elliot": 2}
var weather: String = "Sunny"      # If you have weather
var event_flags: Dictionary[String, bool] = {} # For tracking triggered events/cutscenes

signal new_day

func _process(delta: float) -> void:
	if Global.is_new_day:
		is_new_day = false
		emit_signal("new_day")
