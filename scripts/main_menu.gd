extends Control

@export var playButton: Button
@export var exitButton: Button

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/level.tscn")	

func _on_quit_button_pressed() -> void:
	get_tree().quit()
