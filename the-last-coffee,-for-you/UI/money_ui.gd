extends Control

var current_money
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_money = Global.money
	$MoneyLabel.text = str(current_money)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Global.money != current_money:
		current_money = Global.money
		$MoneyLabel.text = str(current_money)
