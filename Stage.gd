extends Spatial

signal player_enter
signal player_exit
signal music_started

var player_was_inside = false


func _process(_delta):
	var player_inside = false
	for body in $OnStage.get_overlapping_bodies():
		if body is Player:
			player_inside = true

	if player_inside and not player_was_inside:
		emit_signal("player_enter")
	if not player_inside and player_was_inside:
		emit_signal("player_exit")
	player_was_inside = player_inside


func quiet_down():
	position_guitar()
	$Performance/Guitarist.who = GameState.who_plays("Guitar")
	$Performance/Keyboardist.who = GameState.who_plays("Keyboard")
	$Performance/Drummer.who = GameState.who_plays("Drums")

	var sfx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx, -20)
	var bgm = AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_volume_db(bgm, -20)


func position_guitar():
	$Performance/Guitar.visible = true
	$Performance/Guitar.translation.y = 1

	match GameState.who_plays("Guitar"):
		"Benny":
			$Performance/Guitar.translation.y = 0.694
		"Don":
			$Performance/Guitar.translation.y = 1.873
		"Kat":
			$Performance/Guitar.translation.y = 1.098
		"Sarah":
			$Performance/Guitar.translation.y = 0.597
		"TonyMacaroni":
			$Performance/Guitar.translation.y = 0.408
		"Troy":
			$Performance/Guitar.translation.y = 1.154
		"NONE":
			$Performance/Guitar.visible = false

	$Performance/Drummer.translation.y = 0.12
	match GameState.who_plays("Drums"):
		"Sarah":
			$Performance/Drummer.translation.y = 0.5

	$Performance/Stool.visible = false
	if GameState.who_plays("Keyboard") == "TonyMacaroni":
		$Performance/Stool.visible = true
		$Performance/Keyboardist.translation.y = 0.9


func play_song():
	if $"Main BG".playing:
		$"Main BG".stop()

		$Music/Bass.play()
		if not GameState.instrument_available("Drums"):
			if GameState.played_well("Drums"):
				$"Music/Good Drums".play()
			else:
				$"Music/Bad Drums".play()

		if not GameState.instrument_available("Keyboard"):
			if GameState.played_well("Keyboard"):
				$"Music/Good Keys".play()
			else:
				$"Music/Bad Keys".play()

		if not GameState.instrument_available("Guitar"):
			if GameState.played_well("Guitar"):
				$"Music/Good Guitar".play()
			else:
				$"Music/Bad Guitar".play()

		emit_signal("music_started")
