extends Node2D

@onready var title = $Title
@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

var fade_duration := 1.5   # seconds

func _ready():
	$StartButton.pressed.connect(_on_start_pressed)


func _on_start_pressed():
	# Prevent double clicking
	start_button.disabled = true
	quit_button.disabled = true

	# Create tween
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade everything out
	tween.tween_property(title, "modulate:a", 0.0, fade_duration)
	tween.tween_property(start_button, "modulate:a", 0.0, fade_duration)
	tween.tween_property(quit_button, "modulate:a", 0.0, fade_duration)

	# Wait until finished
	await tween.finished

	get_tree().change_scene_to_file("res://Cutscenes/cutscene.tscn")
