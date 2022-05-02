extends TextMenu

class_name PauseMenu


func _ready():
	add_option("Resume")
	add_option("Quit")


func handle_option(option, _meta):
	match option:
		"Resume":
			get_tree().paused = false
		"Quit":
			get_tree().quit()


func _process(_delta):
	active = get_tree().paused
