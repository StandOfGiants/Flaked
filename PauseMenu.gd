extends Control

var is_paused = false


func _process(_delta):
	visible = is_paused

	if is_paused and Input.is_action_just_pressed("pause"):
		get_tree().paused = false

	is_paused = get_tree().paused
