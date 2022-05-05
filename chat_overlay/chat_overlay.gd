extends CanvasLayer

signal actioned(next_id)

const DialogLine = preload("res://addons/dialog_manager/dialog_line.gd")
const ExampleMenuItem = preload("res://chat_overlay/menu_item.tscn")

onready var balloon := $Balloon
onready var margin := $Balloon/Margin
onready var character_label := $Balloon/Margin/VBox/Character
onready var dialog_label := $Balloon/Margin/VBox/Dialog
onready var responses_menu := $Balloon/Margin/VBox/Responses/Menu
onready var portraits := $Portraits
onready var npc_portrait := $Portraits/NPCPortrait
onready var player_portrait := $Portraits/PlayerPortrait
onready var blur := $BackgroundBlur

const npc_portraits = {
	# Phone people
	"Aaron": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	"Cal": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	"Miles": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	"Phone": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	# Bar patrons
	"Brook": preload("res://entities/npc/Bartender/Bartender_portrait.png"),
	"Bartender": preload("res://entities/npc/Bartender/Bartender_portrait.png"),
	"Benny": preload("res://entities/npc/Benny/Benny_portrait.png"),
	"Benny SAD": preload("res://entities/npc/Benny/Benny_portrait_sad.png"),
	"Benny HAPPY": preload("res://entities/npc/Benny/Benny_portrait_happy.png"),
	"Don": preload("res://entities/npc/Don/Don_portrait.png"),
	"Don SAD": preload("res://entities/npc/Don/Don_portrait_sad.png"),
	"Don HAPPY": preload("res://entities/npc/Don/Don_portrait_happy.png"),
	"Kat": preload("res://entities/npc/Kat/Kat_portrait.png"),
	"Kat SAD": preload("res://entities/npc/Kat/Kat_portrait_sad.png"),
	"Kat HAPPY": preload("res://entities/npc/Kat/Kat_portrait_happy.png"),
	"Sarah": preload("res://entities/npc/Sarah/Sarah_portrait.png"),
	"Sarah SAD": preload("res://entities/npc/Sarah/Sarah_portrait_sad.png"),
	"Sarah HAPPY": preload("res://entities/npc/Sarah/Sarah_portrait_happy.png"),
	"Tony Macaroni": preload("res://entities/npc/TonyMacaroni/TonyMacaroni_portrait.png"),
	"Tony Macaroni SAD": preload("res://entities/npc/TonyMacaroni/TonyMacaroni_portrait_sad.png"),
	"Tony Macaroni HAPPY":
	preload("res://entities/npc/TonyMacaroni/TonyMacaroni_portrait_happy.png"),
	"Troy": preload("res://entities/npc/Troy/Troy_portrait.png"),
	"Troy SAD": preload("res://entities/npc/Troy/Troy_portrait_sad.png"),
	"Troy HAPPY": preload("res://entities/npc/Troy/Troy_portrait_happy.png"),
	# Player
	"Player": preload("res://entities/player/froggyman_portrait.png"),
	"Player SAD": preload("res://entities/player/froggyman_sad_portrait.png"),
	"Player HAPPY": preload("res://entities/player/froggyman_happy_portrait.png"),
}

var dialog: DialogLine


func _ready() -> void:
	var do_hide = false
	balloon.visible = false
	blur.visible = false
	responses_menu.is_active = false
	portraits.visible = true

	if not dialog:
		queue_free()
		return

	player_portrait.visible = false
	npc_portrait.visible = false
	character_label.visible = false
	if dialog.character != "":
		character_label.visible = true
		if dialog.character.begins_with("Player"):
			if dialog.character in npc_portraits:
				player_portrait.texture = npc_portraits[dialog.character]
			character_label.bbcode_text = GameState.get_name()
			player_portrait.visible = true
		elif dialog.character == "HIDE":
			do_hide = true
		else:
			if dialog.character in npc_portraits:
				npc_portrait.texture = npc_portraits[dialog.character]
			if dialog.character.ends_with(" HAPPY"):
				character_label.bbcode_text = dialog.character.substr(
					0, dialog.character.length() - 6
				)
			elif dialog.character.ends_with(" SAD"):
				character_label.bbcode_text = dialog.character.substr(
					0, dialog.character.length() - 4
				)
			else:
				character_label.bbcode_text = dialog.character
			npc_portrait.visible = true

	dialog_label.dialog = dialog

	if not do_hide:
		blur.visible = true
	else:
		portraits.visible = false

	yield(dialog_label.reset_height(), "completed")

	# Show any responses we have
	for item in responses_menu.get_children():
		item.queue_free()

	if dialog.responses.size() > 0:
		for response in dialog.responses:
			var item = ExampleMenuItem.instance()
			item.bbcode_text = response.prompt
			item.is_allowed = response.is_allowed
			responses_menu.add_child(item)

	# Make sure our responses get included in the height reset
	responses_menu.visible = true
	margin.rect_size = Vector2(0, 0)

	yield(get_tree(), "idle_frame")

	balloon.rect_min_size = margin.rect_size
	balloon.rect_size = Vector2(0, 0)
	balloon.rect_global_position.y = balloon.get_viewport_rect().size.y - balloon.rect_size.y - 20

	# Ok, we can hide it now. It will come back later if we have any responses
	responses_menu.visible = false

	if not do_hide:
		# Show our box
		balloon.visible = true

	dialog_label.type_out()
	yield(dialog_label, "finished")

	# Wait for input
	var next_id: String = ""
	if dialog.responses.size() > 0:
		responses_menu.is_active = true
		responses_menu.visible = true
		responses_menu.index = 0
		var response = yield(responses_menu, "actioned")
		$ActionedBoop.play()
		yield($ActionedBoop, "finished")
		next_id = dialog.responses[response[0]].next_id
	elif dialog.time != null:
		var time = (
			dialog.dialog.length() * 0.02
			if dialog.time == "auto"
			else dialog.time.to_float()
		)
		yield(get_tree().create_timer(time), "timeout")
		next_id = dialog.next_id
	else:
		while true:
			if Input.is_action_just_pressed("ui_accept"):
				next_id = dialog.next_id
				break
			yield(get_tree(), "idle_frame")

	# Send back input
	emit_signal("actioned", next_id)
	queue_free()


var ignore_first_boop = 1


func _on_Menu_selection_changed(_index):
	if dialog.responses.size() > 0 and responses_menu.visible and responses_menu.is_active:
		if ignore_first_boop <= 0:
			$MenuBoop.play()
		ignore_first_boop -= 1
