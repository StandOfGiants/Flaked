extends TextMenu

class_name PauseMenu

signal go_to(screen)


func _ready():
	add_option("Resume")
	add_option("Volume Settings")
	add_option("Quit to Main Menu")
	add_option("Quit Game")


func ensure(error: int):
	if error != 0:
		print("ACTION FAILED: ", error)


func handle_option(option, _meta):
	match option:
		"Resume":
			get_tree().paused = false
		"Volume Settings":
			emit_signal("go_to", "volume")
		"Quit to Main Menu":
			get_tree().paused = false
			ensure(get_tree().change_scene("res://Main Menu.tscn"))
		"Quit Game":
			get_tree().quit()


func _process(_delta):
	active = get_tree().paused
