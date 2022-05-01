extends Node

const DialogConstants = preload("res://addons/dialog_manager/constants.gd")

var dialog_manager

var type: String = DialogConstants.TYPE_DIALOG
var next_id: String
var translation_key: String

var mutation: Dictionary

var character: String
var character_replacements: Array
var dialog: String
var replacements: Array

var responses: Array = []

var pauses: Dictionary = {}
var speeds: Array = []
var inline_mutations: Array = []

var time = null


func _init(data: Dictionary, should_translate: bool = true) -> void:
	type = data.get("type")
	next_id = data.get("next_id")

	match data.get("type"):
		DialogConstants.TYPE_DIALOG:
			character = data.get("character")
			character_replacements = data.get("character_replacements", [])
			dialog = tr(data.get("translation_key")) if should_translate else data.get("text")
			translation_key = data.get("translation_key")
			replacements = data.get("replacements", [])
			pauses = data.get("pauses", {})
			speeds = data.get("speeds", [])
			inline_mutations = data.get("inline_mutations", [])
			time = data.get("time")

		DialogConstants.TYPE_MUTATION:
			mutation = data.get("mutation")


func get_pause(index: int) -> float:
	return pauses.get(index, 0)


func get_speed(index: int) -> float:
	var speed = 1
	for s in speeds:
		if s[0] > index:
			return speed
		speed = s[1]
	return speed


func mutate_inline_mutations(index: int) -> void:
	for inline_mutation in inline_mutations:
		# inline mutations are an array of arrays in the form of [character index, resolvable function]
		if inline_mutation[0] > index:
			return
		if inline_mutation[0] == index:
			dialog_manager.mutate(inline_mutation[1])
