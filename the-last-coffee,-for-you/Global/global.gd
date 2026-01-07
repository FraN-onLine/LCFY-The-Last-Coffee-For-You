extends Node

var player_name: String = "Milieu"
var parent_relation: String = "Son"
var current_day: int = 1           # Day number (1-28, or more)
var current_hour: int = 7          # Current hour (0-23)
var current_minute: int = 0        # Current minute (0-59)
var morning: bool = true
var is_new_day: bool = false       # Set true at the start of a new day, false after systems update
var player_paused: bool = false    # Used to freeze player movement (e.g. during UI/dialogue)
var npcs_paused: bool = false      # Used to freeze NPCs (e.g. during cutscenes/UI)
var is_paused: bool = false          # Global pause state for the game

# ---------------------------
# MONEY
# ---------------------------
var money = 500

func add_money(amount):
	money += amount

func lose_money(amount):
	money = max(money - amount, 0)

func spend_money(amount) -> bool:
	if money >= amount:
		money -= amount
		return true
	return false


signal new_day

func _process(delta: float) -> void:
	if Global.is_new_day:
		is_new_day = false
		emit_signal("new_day")

func is_time_in_range(min_h, min_m, max_h, max_m) -> bool:
	var now = current_hour * 60 + current_minute
	var min_t = min_h * 60 + min_m
	var max_t = max_h * 60 + max_m
	return now >= min_t and now <= max_t
