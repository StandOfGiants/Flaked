extends CanvasLayer

signal actioned(next_id)

const DialogLine = preload("res://addons/dialog_manager/dialog_line.gd")
const ExampleMenuItem = preload("res://chat_overlay/menu_item.tscn")

onready var balloon := $Balloon
onready var margin := $Balloon/Margin
onready var character_label := $Balloon/Margin/VBox/Character
onready var dialog_label := $Balloon/Margin/VBox/Dialog
onready var responses_menu := $Balloon/Margin/VBox/Responses/Menu
onready var npc_portrait := $Balloon/NPCPortrait
onready var player_portrait := $Balloon/PlayerPortrait

const npc_portraits = {
	# Phone people
	"Aaron": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	"Cal": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	"Miles": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	"Phone": preload("res://entities/npc/Hand-Holding-Cell-Phone.png"),
	# Bar patrons
	"Bartender": preload("res://entities/npc/Bartender/Bartender_portrait.png"),
	"Benny": preload("res://entities/npc/Benny/Benny_portrait.png"),
	"Don": preload("res://entities/npc/Don/Don_portrait.png"),
	"Kat": preload("res://entities/npc/Kat/Kat_portrait.png"),
	"Sarah": preload("res://entities/npc/Sarah/Sarah_portrait.png"),
	"Tony Macaroni": preload("res://entities/npc/TonyMacaroni/TonyMacaroni_portrait.png"),
	"Troy": preload("res://entities/npc/Troy/Troy_portrait.png"),
}

var dialog: DialogLine


func _ready() -> void:
	var do_hide = false
	balloon.visible = false
	responses_menu.is_active = false

	if not dialog:
		queue_free()
		return

	player_portrait.visible = false
	npc_portrait.visible = false
	character_label.visible = false
	if dialog.character != "":
		character_label.visible = true
		if dialog.character == "Player":
			character_label.bbcode_text = "Me"
			player_portrait.visible = true
		elif dialog.character == "HIDE":
			do_hide = true
		else:
			if dialog.character in npc_portraits:
				npc_portrait.texture = npc_portraits[dialog.character]
			character_label.bbcode_text = dialog.character
			npc_portrait.visible = true

	dialog_label.dialog = dialog

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
