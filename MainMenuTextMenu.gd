extends TextMenu

class_name MainMenuTextMenu


func _ready():
	if GameState.get_state("actions_run", "Intro", false):
		add_option("Continue")
	add_option("New Game")
	add_option("Quit Game")


func ensure(error: int):
	if error != 0:
		print("ACTION FAILED: ", error)


func handle_option(option, _meta):
	match option:
		"Continue":
			ensure(get_tree().change_scene("res://MainScene.tscn"))
		"New Game":
			GameState.clear_data()
			ensure(get_tree().change_scene("res://MainScene.tscn"))
		"Quit Game":
			get_tree().quit()
