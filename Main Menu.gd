extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass  # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TextMenu_new_game():
	$Main.visible = false
	$EnterName.visible = true


func start(name: String):
	if name.length() == 0:
		name = "Froggit"
	GameState.set_name(name)
	var result = get_tree().change_scene("res://MainScene.tscn")
	if result != 0:
		print("Failed to change to main scene...")


func _on_TextEdit_text_entered(new_text: String):
	start(new_text)


func _on_Button_pressed():
	start($EnterName/TextEdit.text)
