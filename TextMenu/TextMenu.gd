extends GridContainer

class_name TextMenu

onready var label = preload("res://TextMenu/TextMenuLabel.tscn")
# onready var animation = preload("res://entities/player-frames.tres")

export(bool) var active = true

onready var selection_icon = $Pointer
var selection = 0
var options = []

# func _ready():
# 	var sprite := AnimatedSprite.new()
# 	sprite.name = "Selection"
# 	sprite.frames = animation
# 	sprite.animation = "Walk"
# 	sprite.playing = true
# 	sprite.position.x = -15
# 	add_child(sprite)
# 	selection_icon = sprite


func reset_options():
	for option in options:
		remove_child(option)
		option.queue_free()
	options = []


func add_option(text: String, meta: Dictionary = {}):
	var l = label.instance()
	l.text = text
	l.meta = meta
	if l.connect("gui_input", self, "_on_item_input", [options.size()]) != OK:
		printerr("Failed to listen for gui_input")
	add_child(l)
	options.push_back(l)
	if options.size() == 1:  #First item added
		hover_option(l.text, l.meta)


func handle_option(_text: String, _meta):
	pass


func hover_option(_text: String, _meta):
	pass


func _process(_delta):
	if not active or options.empty():
		return

	var selection_changed = false
	selection_icon.position.y = options[selection].margin_top + 30
	if Input.is_action_just_pressed("ui_up"):
		selection += options.size() - 1
		selection_changed = true
	if Input.is_action_just_pressed("ui_down"):
		selection += 1
		selection_changed = true
	if Input.is_action_just_pressed("ui_accept"):
		var element = options[selection]
		handle_option(element.text, element.meta)
	selection %= options.size()
	selection = abs(selection)
	if selection_changed:
		var element = options[selection]
		hover_option(element.text, element.meta)


func _on_item_input(event: InputEvent, option: int):
	if not active:
		return

	if event is InputEventMouseMotion:
		selection = option
		var element = options[selection]
		hover_option(element.text, element.meta)
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed == false:
			var element = options[option]
			handle_option(element.text, element.meta)
