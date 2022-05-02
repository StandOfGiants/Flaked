extends Spatial


func _process(_delta):
	var player_inside = false
	for body in $OnStage.get_overlapping_bodies():
		if body is Player:
			player_inside = true

	get_tree().call_group("player", "is_inside", "stage", player_inside)
	if (
		player_inside
		and get_parent().get_node("AnimationPlayer").current_animation == ""
		and $"Main BG".playing
	):
		get_parent().get_node("AnimationPlayer").play("Start The Music")


func quiet_down():
	var sfx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx, -20)


func play_song():
	if $"Main BG".playing:
		$"Main BG".stop()

		$Performance/Bass.play()
		if not GameState.instrument_available("Drums"):
			if GameState.played_well("Drums"):
				$"Performance/Good Drums".play()
			else:
				$"Performance/Bad Drums".play()

		if not GameState.instrument_available("Keyboard"):
			if GameState.played_well("Keyboard"):
				$"Performance/Good Keys".play()
			else:
				$"Performance/Bad Keys".play()

		if not GameState.instrument_available("Guitar"):
			if GameState.played_well("Guitar"):
				$"Performance/Good Guitar".play()
			else:
				$"Performance/Bad Guitar".play()
