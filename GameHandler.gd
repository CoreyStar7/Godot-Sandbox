extends Node3D

@export var exitKeybind = KEY_ESCAPE

func _ready():
	get_window().title = "3D Player Controller Demo"

func _process(delta):
	pass

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == exitKeybind:
			get_tree().quit(0)
