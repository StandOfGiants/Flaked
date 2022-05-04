extends Spatial


func _ready():
	$AnimationPlayer.play("RESET")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("Entry")


func go_to_stage():
	$AnimationPlayer.play("Go To Stage")
	$HUD.visible = false


func _on_Stage_music_started():
	yield(get_tree().create_timer(30.0), "timeout")
	$Credits.play()


func _on_Credits_credits_done():
	$Player.end_dialog()


func go_back_to_main():
	if $Player.in_dialog():
		yield($Player, "out_of_dialog")

	yield(get_tree().create_timer(10.0), "timeout")
	GameState.clear_data()
	var result = get_tree().change_scene("res://Main Menu.tscn")
	if result != 0:
		print("Failed to change to main scene.")
