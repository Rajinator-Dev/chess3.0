extends Control

@onready var container : GridContainer = $GridContainer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for rank : int in range(8):
		for file : int in range(8):
			var button : Button = Button.new()
			button.custom_minimum_size = Vector2(50.0, 50.0)
			button.text = str(Vector2i(file, rank))
			container.add_child(button)
