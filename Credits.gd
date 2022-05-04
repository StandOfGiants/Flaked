extends Control

signal credits_done


func play():
	$AnimationPlayer.play("Play Credits")


func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "Play Credits":
		emit_signal("credits_done")
