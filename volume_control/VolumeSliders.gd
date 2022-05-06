extends Control

signal exit

var index = 0

onready var sliders = $Sliders

export(bool) var active = true setget set_active


func set_active(now_active: bool):
	if not active and now_active:
		index = 0
	active = now_active


func _process(_delta):
	if not active:
		return

	if Input.is_action_just_pressed("ui_down"):
		index += 1
	elif Input.is_action_just_pressed("ui_up"):
		index -= 1
	if index < 0:
		index = sliders.get_children().size() - 1
	index %= sliders.get_children().size()

	var node = sliders.get_children()[index]
	$Pointer.position.y = node.rect_position.y + (node.rect_size.y / 2)
	if Input.is_action_just_pressed("ui_left"):
		node.value -= 1
	if Input.is_action_just_pressed("ui_right"):
		node.value += 1

	if Input.is_action_just_pressed("ui_cancel"):
		emit_signal("exit")


func _on_Back_Button_pressed():
	emit_signal("exit")
