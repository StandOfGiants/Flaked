extends Node

signal update_beers(amount)
signal update_money(amount)

var state = {"money": 30}
var preferences = {}
const KEYBOARD = "Keyboard"


func _ready():
	load_data()


func sound_fx(name: String):
	print("PLAYING SOUND: ", name)
	if not has_node(name):
		print("NO FX NODE NAMED: ", name)
		return

	if not get_node(name).has_method("play"):
		print("FX NODE HAS NO PLAY: ", name)
		return

	get_node(name).play()


func set_name(name: String):
	state["name"] = name


func get_name() -> String:
	if "name" in state:
		return state["name"]
	return "Froggit"


func get_category(category: String):
	if not category in state:
		return {}
	return state[category]


func get_state(category: String, name: String, or_else = null):
	if not category in state:
		return or_else

	if not name in state[category]:
		return or_else

	return state[category][name]


func set_state(category: String, name: String, value, or_else = null):
	var retval = get_state(category, name, or_else)

	if retval != value:
		if not category in state:
			state[category] = {}

		state[category][name] = value
		print(state)
		save_data()

	return retval


func has_run_once(name: String) -> bool:
	return set_state("actions_run", name, true, false)


func first_visit(name: String) -> bool:
	return not set_state("npcs_visited", name, true, false)


func update_karma(character: String, amount: int):
	set_state("karma", character, get_state("karma", character, 0) + amount)


func has_positive_karma(character: String) -> bool:
	return get_state("karma", character, 0) >= 0


func karma(character: String) -> int:
	return get_state("karma", character, 0)


func complete_character(character: String):
	set_state("complete", character, true)


func is_complete(character: String) -> bool:
	return get_state("complete", character, false)


const INSTRUMENTS = ["Guitar", "Drums", "Keyboard"]


func available_instruments():
	var instruments_available = []
	for instrument in INSTRUMENTS:
		if instrument_available(instrument):
			instruments_available.push_back(instrument)
	return instruments_available


func name_player(instrument: String) -> String:
	match instrument:
		"Guitar":
			return "a guitar player"
		"Drums":
			return "a drummer"
		"Keyboard":
			return "a keyboard player"
	return "SOMETHING"


func missing_musicians():
	var instruments = available_instruments()
	if instruments.size() == 3:
		return (
			"%s, %s, and %s"
			% [
				name_player(instruments[0]),
				name_player(instruments[1]),
				name_player(instruments[2])
			]
		)
	if instruments.size() == 2:
		return "%s and %s" % [name_player(instruments[0]), name_player(instruments[1])]
	else:
		return name_player(instruments[0])


func all_alone():
	return available_instruments().size() == 3


func band_full():
	return available_instruments().size() == 0


func is_not_assigned(character: String) -> bool:
	for instrument in INSTRUMENTS:
		if get_state("instruments", instrument, null) == character:
			return false
	return true


func is_assigned(character: String) -> bool:
	return not is_not_assigned(character)


func instrument_available(instrument: String) -> bool:
	return get_state("instruments", instrument, null) == null


func assign_instrument(instrument: String, character: String):
	complete_character(character)
	set_state("instruments", instrument, character)


const PREFERRED_INSTRUMENTS = {
	"Don": "Keyboard",
	"Troy": "Guitar",
	"TonyMacaroni": "Drums",
	"Benny": "Guitar",
	"Kat": "Keyboard",
	"Sarah": "Drums",
}


func who_plays(instrument: String) -> String:
	return get_state("instruments", instrument, "NONE")


func played_well(instrument: String) -> bool:
	var person = get_state("instruments", instrument, null)
	if person == null:
		return false
	if PREFERRED_INSTRUMENTS[person] == instrument:
		return true
	return false


func performance_rating() -> int:
	var rating = 0
	for instrument in INSTRUMENTS:
		if instrument_available(instrument):
			continue
		rating += 1  # One point for getting someone to play
		if played_well(instrument):
			rating += 1  # Another point if you picked someone good
	return rating


func look_around():
	get_tree().call_group("player", "look_around")


func go_to_stage():
	get_tree().call_group("main", "go_to_stage")


func play_song():
	get_tree().call_group("stage", "play_song")


func is_not_resolved(branch: String) -> bool:
	return not get_state("resolved_branches", branch, false)


func resolve_branch(branch: String):
	set_state("resolved_branches", branch, true)


func start_quest(quest_name: String):
	set_state("quests", quest_name, "started")


func on_quest(quest_name: String):
	return get_state("quests", quest_name, "finished") != "finished"


func finish_quest(quest_name: String):
	set_state("quests", quest_name, "finished")


func get_beer():
	state["beer"] = true
	emit_signal("update_beers", 1)
	save_data()


func has_beer():
	return "beer" in state and state["beer"] == true


func lose_beer():
	state["beer"] = false
	emit_signal("update_beers", 0)
	save_data()


func get_beers():
	if "beer" in state and state["beer"]:
		return 1
	return 0


func get_money():
	if not "money" in state:
		state["money"] = 30
	return state["money"]


func lose_money(amount: int):
	if not "money" in state:
		state["money"] = 30
	state["money"] -= amount
	emit_signal("update_money", state["money"])
	save_data()


func get_volume(bus: String):
	var key = "%s volume" % bus
	if key in preferences:
		return preferences[key]
	return null


func set_volume(bus: String, decibel: float):
	var key = "%s volume" % bus
	preferences[key] = decibel
	save_data()


func save_data():
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json(state))
	save_game.close()

	var preferences_file = File.new()
	preferences_file.open("user://preferences.json", File.WRITE)
	preferences_file.store_line(to_json(preferences))
	preferences_file.close()


func load_data():
	var save_game = File.new()
	if save_game.file_exists("user://savegame.save"):
		save_game.open("user://savegame.save", File.READ)
		state = parse_json(save_game.get_line())

		save_game.close()

	var preferences_file = File.new()
	if preferences_file.file_exists("user://preferences.json"):
		preferences_file.open("user://preferences.json", File.READ)
		preferences = parse_json(preferences_file.get_line())

		preferences_file.close()


func clear_data():
	state = {}
	save_data()
