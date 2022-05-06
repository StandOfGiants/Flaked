tool
extends HSlider

export(String, "Master", "SFX", "BGM") var bus = "Master"
export(String) var label = "Global" setget set_label

onready var bus_index = AudioServer.get_bus_index(bus)


func set_label(new_label):
	label = new_label
	$Label.text = label


func _ready():
	set_label(label)
	if not Engine.editor_hint:
		$TestSound.bus = bus
		var saved_volume = GameState.get_volume(bus)
		if saved_volume != null:
			value = saved_volume
			set_volume(value)
		else:
			value = AudioServer.get_bus_volume_db(bus_index)


func set_volume(decibel: float):
	# Mute if at min value
	AudioServer.set_bus_mute(bus_index, decibel == min_value)
	AudioServer.set_bus_volume_db(bus_index, decibel)
	GameState.set_volume(bus, decibel)


var skip_changes = 1


func _on_value_changed(decibel: float):
	if not Engine.editor_hint:
		set_volume(decibel)
		if skip_changes <= 0:
			$TestSound.play()
		skip_changes -= 1
