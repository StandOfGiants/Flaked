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
