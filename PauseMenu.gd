extends Control

var is_paused = false

onready var pause_menu = $PauseMenuMain
onready var text_menu = $PauseMenuMain/TextMenu
onready var volume_sliders = $VolumeSliders


func _ready():
	pause_menu.visible = true
	volume_sliders.visible = false
	volume_sliders.active = false


func _process(_delta):
	visible = is_paused

	if is_paused and Input.is_action_just_pressed("pause"):
		get_tree().paused = false

	is_paused = get_tree().paused


func _on_TextMenu_go_to(screen: String):
	match screen:
		"volume":
			text_menu.active = false
			pause_menu.visible = false
			volume_sliders.active = true
			volume_sliders.visible = true


func _on_VolumeSliders_exit():
	text_menu.active = true
	pause_menu.visible = true
	volume_sliders.active = false
	volume_sliders.visible = false
