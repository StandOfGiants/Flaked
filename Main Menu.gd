extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var main_menu = $Main
onready var text_menu = $Main/TextMenu
onready var volume_sliders = $VolumeSliders


# Called when the node enters the scene tree for the first time.
func _ready():
	main_menu.visible = true
	volume_sliders.visible = false
	volume_sliders.active = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if $EnterName.visible and Input.is_action_just_pressed("ui_accept"):
		start($EnterName/TextEdit.text)


func _on_TextMenu_new_game():
	$Main.visible = false
	text_menu.active = false
	$EnterName.visible = true
	$EnterName/TextEdit.grab_focus()


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


func _on_TextMenu_go_to(screen: String):
	match screen:
		"volume":
			text_menu.active = false
			main_menu.visible = false
			volume_sliders.active = true
			volume_sliders.visible = true


func _on_VolumeSliders_exit():
	text_menu.active = true
	main_menu.visible = true
	volume_sliders.active = false
	volume_sliders.visible = false
