extends CanvasLayer

@export var duration := 1.2
var timer := 0.0
@onready var label = $Label

func show_popup(popup_text):
	label.text = "[pulse] " + popup_text + " [/pulse]"
	label.visible = true
	timer = 0.0

func _process(delta):
	if label.visible:
		timer += delta
		if timer > duration:
			label.visible = false
			queue_free()
