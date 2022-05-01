extends Resource
class_name DialogResource

const DialogLine := preload("res://addons/dialog_manager/dialog_line.gd")
const DialogConstants := preload("res://addons/dialog_manager/constants.gd")

export(int) var syntax_version
export(String) var raw_text
export(Array, Dictionary) var errors
export(Dictionary) var titles
export(Dictionary) var lines


func _init():
	syntax_version = DialogConstants.SYNTAX_VERSION
	raw_text = "~ this_is_a_node_title\n\nNathan: This is some dialog.\nNathan: Here are some choices.\n- First one\n\tNathan: You picked the first one.\n- Second one\n\tNathan: You picked the second one.\n- Start again => this_is_a_node_title\n- End the conversation => END\nNathan: For more information about conditional dialog, mutations, and all the fun stuff, see the online documentation."
	errors = []
	titles = {}
	lines = {}


func get_next_dialog_line(title: String) -> DialogLine:
	# NOTE: For some reason get_singleton doesn't work here so we have to get creative
	var tree: SceneTree = Engine.get_main_loop()
	if tree:
		var dialog_manager = tree.current_scene.get_node_or_null("/root/DialogManager")
		if dialog_manager != null:
			return dialog_manager.get_next_dialog_line(title, self)

	assert(false, 'The "DialogManager" autoload does not appear to be loaded.')
	return null
