extends Node

var met_npcs = {}


func has_met(name: String) -> bool:
	return name in met_npcs


func set_has_met(name: String):
	met_npcs[name] = true
