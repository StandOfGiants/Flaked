extends Node

var state = {}


func _ready():
	load_data()


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
		print("Setting ", category, name, value)
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


const INSTRUMENTS = ["Guitar", "Drums", "Keyboard"]


func available_instruments():
	var instruments_available = []
	for instrument in INSTRUMENTS:
		if instrument_available(instrument):
			instruments_available.push_back(instrument)
	return instruments_available


func is_not_assigned(character: String) -> bool:
	for instrument in INSTRUMENTS:
		if get_state("instruments", instrument, null) == character:
			return false
	return true


func instrument_available(instrument: String) -> bool:
	return get_state("instruments", instrument, null) == null


func assign_instrument(instrument: String, character: String):
	set_state("instruments", instrument, character)


const PREFERRED_INSTRUMENTS = {
	"Don": "Keyboard",
	"Troy": "Guitar",
	"Tony Macaroni": "Drums",
	"Benny": "Guitar",
	"Kat": "Keyboard",
	"Sarah": "Drums",
}


func played_well(instrument: String) -> bool:
	var person = get_state("instruments", instrument, null)
	if person == null:
		return false
	if PREFERRED_INSTRUMENTS[person] == instrument:
		return true
	return false


func look_around():
	get_tree().call_group("player", "look_around")


func save_data():
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	save_game.store_line(to_json(state))
	save_game.close()


func load_data():
	var save_game = File.new()
	if not save_game.file_exists("user://savegame.save"):
		return

	save_game.open("user://savegame.save", File.READ)
	state = parse_json(save_game.get_line())

	save_game.close()


func clear_data():
	state = {}
	save_data()
