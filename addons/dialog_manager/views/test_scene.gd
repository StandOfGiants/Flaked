extends Node2D

onready var settings = $Settings


func _ready():
	get_tree().set_screen_stretch(
		SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920, 1080)
	)

	DialogManager.connect("dialog_finished", self, "_on_dialog_finished")

	var title = settings.get_editor_value("run_title")
	var dialog_resource = load(settings.get_editor_value("run_resource"))
	DialogManager.show_example_dialog_balloon(title, dialog_resource)


### Signals


func _on_dialog_finished():
	get_tree().quit()
