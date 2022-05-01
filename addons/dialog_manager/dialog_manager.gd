extends Node

signal dialog_started
signal dialog_finished

const DialogResource = preload("res://addons/dialog_manager/dialog_resource.gd")
const DialogConstants = preload("res://addons/dialog_manager/constants.gd")
const DialogLine = preload("res://addons/dialog_manager/dialog_line.gd")
const DialogResponse = preload("res://addons/dialog_manager/dialog_response.gd")

const DialogSettings = preload("res://addons/dialog_manager/components/settings.gd")
const DialogParser = preload("res://addons/dialog_manager/components/parser.gd")

const ExampleBalloon = preload("res://addons/dialog_manager/example_balloon/example_balloon.gd")

var resource: DialogResource
var game_states: Array = []
var auto_translate: bool = true
var settings: DialogSettings = DialogSettings.new()

var is_dialog_running := false setget set_is_dialog_running

var _node_properties: Array = []
var _resource_cache: Array = []
var _trash: Node = Node.new()


func _ready() -> void:
	# Cache the known Node2D properties
	_node_properties = ["Script Variables"]
	var temp_node = Node2D.new()
	for property in temp_node.get_property_list():
		_node_properties.append(property.name)
	temp_node.free()

	# Load the config file (if there is one) so we can set up any global state objects
	add_child(settings)
	for node_name in settings.get_runtime_value("states", []):
		var state = get_node("/root/" + node_name)
		if state:
			game_states.append(state)

	# Add a node for cleaning up
	add_child(_trash)


# Step through lines and run any mutations until we either
# hit some dialog or the end of the conversation
func get_next_dialog_line(key: String, override_resource: DialogResource = null) -> DialogLine:
	cleanup()

	# Fix up any keys that have spaces in them
	key = key.replace(" ", "_").strip_edges()

	# You have to provide a dialog resource
	assert(resource != null or override_resource != null, "No dialog resource provided")

	var local_resource: DialogResource = (
		override_resource
		if override_resource != null
		else resource
	)

	assert(
		local_resource.syntax_version == DialogConstants.SYNTAX_VERSION,
		"This dialog resource is older than the runtime expects."
	)

	var resource_path = local_resource.resource_path
	if local_resource.lines.size() == 0:
		# We probably have pre-baking turned off so we need to compile on the fly
		local_resource = compile_resource(local_resource)

	if local_resource.errors.size() > 0:
		# Store in a local var for debugger convenience
		var errors = local_resource.errors
		printerr("There are %d error(s) in %s" % [errors.size(), resource_path])
		for error in errors:
			printerr("\tLine %s: %s" % [error.get("line"), error.get("message")])
		assert(false, "The provided DialogResource contains errors. See Output for details.")

	var dialog = get_line(key, local_resource)

	yield(get_tree(), "idle_frame")

	self.is_dialog_running = true

	# If our dialog is nothing then we hit the end
	if dialog == null or not is_valid(dialog):
		self.is_dialog_running = false
		return null

	# Run the mutation if it is one
	if dialog.type == DialogConstants.TYPE_MUTATION:
		yield(mutate(dialog.mutation), "completed")
		dialog.queue_free()
		if dialog.next_id in [DialogConstants.ID_END_CONVERSATION, DialogConstants.ID_NULL, null]:
			# End the conversation
			self.is_dialog_running = false
			return null
		else:
			return get_next_dialog_line(dialog.next_id, local_resource)
	else:
		return dialog


func replace_values(line_or_response) -> String:
	if line_or_response is DialogLine:
		var line: DialogLine = line_or_response
		return get_with_replacements(line.dialog, line.replacements)
	elif line_or_response is DialogResponse:
		var response: DialogResponse = line_or_response
		return get_with_replacements(response.prompt, response.replacements)
	else:
		return ""


func get_resource_from_text(text: String) -> DialogResource:
	var parser = DialogParser.new()
	var new_resource = DialogResource.new()

	var results = parser.parse(text)
	parser.queue_free()

	new_resource.raw_text = text
	new_resource.syntax_version = DialogConstants.SYNTAX_VERSION
	new_resource.titles = results.get("titles")
	new_resource.lines = results.get("lines")
	new_resource.errors = results.get("errors")

	return new_resource


func show_example_dialog_balloon(title: String, local_resource: DialogResource = null) -> void:
	var dialog = yield(get_next_dialog_line(title, local_resource), "completed")
	if dialog != null:
		var balloon = preload("res://addons/dialog_manager/example_balloon/example_balloon.tscn").instance()
		balloon.dialog = dialog
		get_tree().current_scene.add_child(balloon)
		show_example_dialog_balloon(yield(balloon, "actioned"), local_resource)


### Helpers


func compile_resource(resource: DialogResource) -> DialogResource:
	# See if we have this cached, first
	for item in _resource_cache:
		if item[0] == resource.resource_path:
			return item[1]

	# Otherwise, compile it and then cache it
	var next_resource = get_resource_from_text(resource.raw_text)
	_resource_cache.insert(0, [resource.resource_path, next_resource])

	# Only keep recent stuff in the cache
	if _resource_cache.size() > 5:
		_resource_cache.remove(5)

	return next_resource


# Get a line by its ID
func get_line(key: String, local_resource: DialogResource) -> DialogLine:
	# End of conversation
	if key in [DialogConstants.ID_NULL, DialogConstants.ID_END_CONVERSATION, null]:
		return null

	# See if it is a title
	if key.begins_with("~ "):
		key = key.substr(2)
	if local_resource.titles.has(key):
		key = local_resource.titles.get(key)

	# Key not found
	if not local_resource.lines.has(key):
		printerr('Line for key "%s" could not be found in %s' % [key, local_resource.resource_path])
		assert(
			false,
			"The provided DialogResource does not contain that line key. See Output for details."
		)

	var data = local_resource.lines.get(key)

	# Check condtiions
	if data.get("type") == DialogConstants.TYPE_CONDITION:
		# "else" will have no actual condition
		if data.get("condition") == null or check(data.get("condition")):
			return get_line(data.get("next_id"), local_resource)
		else:
			return get_line(data.get("next_conditional_id"), local_resource)

	# Evaluate early exits
	if data.get("type") == DialogConstants.TYPE_GOTO:
		return get_line(data.get("next_id"), local_resource)

	# Set up a line object
	var line = DialogLine.new(data, auto_translate)
	line.dialog_manager = self

	# If we are the first of a list of responses then get the other ones
	if data.get("type") == DialogConstants.TYPE_RESPONSE:
		line.responses = get_responses(data.get("responses"), local_resource)
		return line

	# Add as a child so that it gets cleaned up automatically
	_trash.add_child(line)

	# Replace any variables in the dialog text
	if data.get("type") == DialogConstants.TYPE_DIALOG and data.has("replacements"):
		line.character = get_with_replacements(line.character, line.character_replacements)
		line.dialog = get_with_replacements(line.dialog, line.replacements)

	# Inject the next node's responses if they have any
	var next_line = local_resource.lines.get(line.next_id)
	if next_line != null and next_line.get("type") == DialogConstants.TYPE_RESPONSE:
		line.responses = get_responses(next_line.get("responses"), local_resource)

	return line


func set_is_dialog_running(value: bool) -> void:
	if is_dialog_running != value:
		if value:
			emit_signal("dialog_started")
		else:
			emit_signal("dialog_finished")

	is_dialog_running = value


func get_game_states() -> Array:
	var current_scene = get_tree().current_scene
	var unique_states = []
	for state in [current_scene] + game_states:
		if not unique_states.has(state):
			unique_states.append(state)
	return unique_states


# Check if a condition is met
func check(condition: Dictionary) -> bool:
	if condition.size() == 0:
		return true

	return resolve(condition.get("expression").duplicate(true))


# Make a change to game state or run a method
func mutate(mutation: Dictionary) -> void:
	if mutation == null:
		return

	if mutation.has("function"):
		# If lhs is a function then we run it and return because you can't assign to a function
		var function_name = mutation.get("function")
		var args = resolve_each(mutation.get("args"))
		match function_name:
			"wait":
				yield(get_tree().create_timer(float(args[0])), "timeout")
				return
			"emit":
				for state in get_game_states():
					if state.has_signal(args[0]):
						match args.size():
							1:
								state.emit_signal(args[0])
							2:
								state.emit_signal(args[0], args[1])
							3:
								state.emit_signal(args[0], args[1], args[2])
							4:
								state.emit_signal(args[0], args[1], args[2], args[3])
							5:
								state.emit_signal(args[0], args[1], args[2], args[3], args[4])
							6:
								state.emit_signal(
									args[0], args[1], args[2], args[3], args[4], args[5]
								)
							7:
								state.emit_signal(
									args[0], args[1], args[2], args[3], args[4], args[5], args[6]
								)
							8:
								state.emit_signal(
									args[0],
									args[1],
									args[2],
									args[3],
									args[4],
									args[5],
									args[6],
									args[7]
								)
			"debug":
				var printable = {}
				for i in range(args.size()):
					printable[mutation.get("args")[i][0].get("value")] = args[i]
				print(printable)
			_:
				for state in get_game_states():
					if state.has_method(function_name):
						var result = state.callv(function_name, args)
						if result is GDScriptFunctionState and result.is_valid():
							yield(result, "completed")
						else:
							yield(get_tree(), "idle_frame")
						return

				printerr(
					(
						"'"
						+ function_name
						+ "' is not a method in any game states ("
						+ str(get_game_states())
						+ ")."
					)
				)
				assert(
					false,
					"Missing function on current scene or game state. See Output for details."
				)

	elif mutation.has("expression"):
		resolve(mutation.get("expression").duplicate(true))

	# Wait one frame to give the dialog handler a chance to yield
	yield(get_tree(), "idle_frame")


func resolve_each(array: Array) -> Array:
	var results = []
	for item in array:
		results.append(resolve(item.duplicate(true)))
	return results


# Replace any variables, etc in the dialog with their state values
func get_with_replacements(text: String, replacements: Array) -> String:
	for replacement in replacements:
		var value = resolve(replacement.get("expression").duplicate(true))
		text = text.replace(replacement.get("value_in_text"), str(value))

	return text


# Replace an array of line IDs with their response prompts
func get_responses(ids: Array, local_resource: DialogResource) -> Array:
	var responses: Array = []
	for id in ids:
		var data = local_resource.lines.get(id)
		if (
			settings.get_runtime_value("include_all_responses", false)
			or data.get("condition") == null
			or check(data.get("condition"))
		):
			var response = DialogResponse.new(data, auto_translate)
			response.character = get_with_replacements(
				response.character, response.character_replacements
			)
			response.prompt = get_with_replacements(response.prompt, response.replacements)
			response.is_allowed = data.get("condition") == null or check(data.get("condition"))
			# Add as a child so that it gets cleaned up automatically
			_trash.add_child(response)
			responses.append(response)

	return responses


# Get a value on the current scene or game state
func get_state_value(property: String):
	# It's a variable
	for state in get_game_states():
		if has_property(state, property):
			return state.get(property)

	printerr(
		"'" + property + "' is not a property on any game states (" + str(get_game_states()) + ")."
	)
	assert(false, "Missing property on current scene or game state. See Output for details.")


# Set a value on the current scene or game state
func set_state_value(property: String, value) -> void:
	for state in get_game_states():
		if has_property(state, property):
			state.set(property, value)
			return

	printerr(
		"'" + property + "' is not a property on any game states (" + str(get_game_states()) + ")."
	)
	assert(false, "Missing property on current scene or game state. See Output for details.")


# Collapse any expressions
func resolve(tokens: Array):
	# Handle groups first
	for token in tokens:
		if token.get("type") == DialogConstants.TOKEN_GROUP:
			token["type"] = "value"
			token["value"] = resolve(token.get("value"))

	# Then variables/methods
	var i = 0
	var limit = 0
	while i < tokens.size() and limit < 1000:
		var token = tokens[i]

		if token.get("type") == DialogConstants.TOKEN_FUNCTION:
			var function_name = token.get("function")
			var args = resolve_each(token.get("value"))
			if function_name == "str":
				token["type"] = "value"
				token["value"] = str(args[0])
			elif tokens[i - 1].get("type") == DialogConstants.TOKEN_DOT:
				# If we are calling a deeper function then we need to collapse the
				# value into the thing we are calling the function on
				var caller = tokens[i - 2]
				if not caller.get("value").has_method(function_name):
					printerr('"%s" is not a callable method on "%s"' % [function_name, str(caller)])
					assert(
						false, "Missing callable method on calling object. See Output for details."
					)
				caller["type"] = "value"
				caller["value"] = caller.get("value").callv(function_name, args)
				tokens.remove(i)
				tokens.remove(i - 1)
				i -= 2
			else:
				var found = false
				for state in get_game_states():
					if state.has_method(function_name):
						token["type"] = "value"
						token["value"] = state.callv(function_name, args)
						found = true

				if not found:
					printerr(
						(
							'"%s" is not a method on any game states (%s)'
							% [function_name, str(get_game_states())]
						)
					)
					assert(
						false,
						"Missing function on current scene or game state. See Output for details."
					)

		elif token.get("type") == DialogConstants.TOKEN_DICTIONARY_REFERENCE:
			var value = get_state_value(token.get("variable"))
			var index = resolve(token.get("value"))
			if typeof(value) == TYPE_DICTIONARY:
				if (
					tokens.size() > i + 1
					and tokens[i + 1].get("type") == DialogConstants.TOKEN_ASSIGNMENT
				):
					# If the next token is an assignment then we need to leave this as a reference
					# so that it can be resolved once everything ahead of it has been resolved
					token["type"] = "dictionary"
					token["value"] = value
					token["key"] = index
				else:
					if value.has(index):
						token["type"] = "value"
						token["value"] = value[index]
					else:
						printerr(
							(
								'Key "%s" not found in dictionary "%s"'
								% [str(index), token.get("variable")]
							)
						)
						assert(false, "Key not found in dictionary. See Output for details.")
			elif typeof(value) == TYPE_ARRAY:
				if (
					tokens.size() > i + 1
					and tokens[i + 1].get("type") == DialogConstants.TOKEN_ASSIGNMENT
				):
					# If the next token is an assignment then we need to leave this as a reference
					# so that it can be resolved once everything ahead of it has been resolved
					token["type"] = "array"
					token["value"] = value
					token["key"] = index
				else:
					if index >= 0 and index < value.size():
						token["type"] = "value"
						token["value"] = value[index]
					else:
						printerr(
							'Index %d out of bounds of array "%s"' % [index, token.get("variable")]
						)
						assert(false, "Index out of bounds of array. See Output for details.")

		elif token.get("type") == DialogConstants.TOKEN_ARRAY:
			token["type"] = "value"
			token["value"] = resolve_each(token.get("value"))

		elif token.get("type") == DialogConstants.TOKEN_DICTIONARY:
			token["type"] = "value"
			var dictionary = {}
			for key in token.get("value").keys():
				var resolved_key = resolve([key])
				var resolved_value = resolve([token.get("value").get(key)])
				dictionary[resolved_key] = resolved_value
			token["value"] = dictionary

		elif token.get("type") == DialogConstants.TOKEN_VARIABLE:
			if token.get("value") == "null":
				token["type"] = "value"
				token["value"] = null
			elif tokens[i - 1].get("type") == DialogConstants.TOKEN_DOT:
				var caller = tokens[i - 2]
				var property = token.get("value")
				if (
					tokens.size() > i + 1
					and tokens[i + 1].get("type") == DialogConstants.TOKEN_ASSIGNMENT
				):
					# If the next token is an assignment then we need to leave this as a reference
					# so that it can be resolved once everything ahead of it has been resolved
					caller["type"] = "property"
					caller["property"] = property
				else:
					# If we are requesting a deeper property then we need to collapse the
					# value into the thing we are referencing from
					caller["type"] = "value"
					caller["value"] = caller.get("value").get(property)
				tokens.remove(i)
				tokens.remove(i - 1)
				i -= 2
			elif (
				tokens.size() > i + 1
				and tokens[i + 1].get("type") == DialogConstants.TOKEN_ASSIGNMENT
			):
				# It's a normal variable but we will be assigning to it so don't resolve
				# it until everything after it has been resolved
				token["type"] = "variable"
			else:
				token["type"] = "value"
				token["value"] = get_state_value(token.get("value"))

		i += 1

	# Then multiply and divide
	i = 0
	limit = 0
	while i < tokens.size() and limit < 1000:
		limit += 1
		var token = tokens[i]
		if (
			token.get("type") == DialogConstants.TOKEN_OPERATOR
			and token.get("value") in ["*", "/", "%"]
		):
			token["type"] = "value"
			token["value"] = apply_operation(
				token.get("value"), tokens[i - 1].get("value"), tokens[i + 1].get("value")
			)
			tokens.remove(i + 1)
			tokens.remove(i - 1)
			i -= 1
		i += 1

	if limit >= 1000:
		assert(false, "Something went wrong")

	# Then addition and subtraction
	i = 0
	limit = 0
	while i < tokens.size() and limit < 1000:
		limit += 1
		var token = tokens[i]
		if token.get("type") == DialogConstants.TOKEN_OPERATOR and token.get("value") in ["+", "-"]:
			token["type"] = "value"
			token["value"] = apply_operation(
				token.get("value"), tokens[i - 1].get("value"), tokens[i + 1].get("value")
			)
			tokens.remove(i + 1)
			tokens.remove(i - 1)
			i -= 1
		i += 1

	if limit >= 1000:
		assert(false, "Something went wrong")

	# Then negations
	i = 0
	limit = 0
	while i < tokens.size() and limit < 1000:
		limit += 1
		var token = tokens[i]
		if token.get("type") == DialogConstants.TOKEN_NOT:
			token["type"] = "value"
			token["value"] = not tokens[i + 1].get("value")
			tokens.remove(i + 1)
			i -= 1
		i += 1

	if limit >= 1000:
		assert(false, "Something went wrong")

	# Then comparisons
	i = 0
	limit = 0
	while i < tokens.size() and limit < 1000:
		limit += 1
		var token = tokens[i]
		if token.get("type") == DialogConstants.TOKEN_COMPARISON:
			token["type"] = "value"
			token["value"] = compare(
				token.get("value"), tokens[i - 1].get("value"), tokens[i + 1].get("value")
			)
			tokens.remove(i + 1)
			tokens.remove(i - 1)
			i -= 1
		i += 1

	if limit >= 1000:
		assert(false, "Something went wrong")

	# Then and/or
	i = 0
	limit = 0
	while i < tokens.size() and limit < 1000:
		limit += 1
		var token = tokens[i]
		if token.get("type") == DialogConstants.TOKEN_AND_OR:
			token["type"] = "value"
			token["value"] = apply_operation(
				token.get("value"), tokens[i - 1].get("value"), tokens[i + 1].get("value")
			)
			tokens.remove(i + 1)
			tokens.remove(i - 1)
			i -= 1
		i += 1

	if limit >= 1000:
		assert(false, "Something went wrong")

	# Lastly, resolve any assignments
	i = 0
	limit = 0
	while i < tokens.size() and limit < 1000:
		limit += 1
		var token = tokens[i]
		if token.get("type") == DialogConstants.TOKEN_ASSIGNMENT:
			var lhs = tokens[i - 1]
			var value

			match lhs.get("type"):
				"variable":
					value = apply_operation(
						token.get("value"),
						get_state_value(lhs.get("value")),
						tokens[i + 1].get("value")
					)
					set_state_value(lhs.get("value"), value)
				"property":
					value = apply_operation(
						token.get("value"),
						lhs.get("value").get(lhs.get("property")),
						tokens[i + 1].get("value")
					)
					lhs.get("value").set(lhs.get("property"), value)
				"dictionary", "array":
					value = apply_operation(
						token.get("value"),
						lhs.get("value")[lhs.get("key")],
						tokens[i + 1].get("value")
					)
					lhs.get("value")[lhs.get("key")] = value
				_:
					assert(false, "Unknown assignment target")

			token["type"] = "value"
			token["value"] = value
			tokens.remove(i + 1)
			tokens.remove(i - 1)
			i -= 1
		i += 1

	if limit >= 1000:
		assert(false, "Something went wrong")

	return tokens[0].get("value")


func compare(operator: String, first_value, second_value):
	match operator:
		"in":
			if first_value == null or second_value == null:
				return false
			else:
				return first_value in second_value
		"<":
			if first_value == null:
				return true
			elif second_value == null:
				return false
			else:
				return first_value < second_value
		">":
			if first_value == null:
				return false
			elif second_value == null:
				return true
			else:
				return first_value > second_value
		"<=":
			if first_value == null:
				return true
			elif second_value == null:
				return false
			else:
				return first_value <= second_value
		">=":
			if first_value == null:
				return false
			elif second_value == null:
				return true
			else:
				return first_value >= second_value
		"==":
			if first_value == null:
				if typeof(second_value) == TYPE_BOOL:
					return second_value == false
				else:
					return false
			else:
				return first_value == second_value
		"!=":
			if first_value == null:
				if typeof(second_value) == TYPE_BOOL:
					return second_value == true
				else:
					return false
			else:
				return first_value != second_value


func apply_operation(operator: String, first_value, second_value):
	if first_value == null:
		if typeof(second_value) == TYPE_BOOL and second_value == true:
			return false
		else:
			return second_value
	elif second_value == null:
		if typeof(first_value) == TYPE_BOOL and first_value == true:
			return false
		else:
			return first_value

	match operator:
		"=":
			return second_value
		"+", "+=":
			return first_value + second_value
		"-", "-=":
			return first_value - second_value
		"/", "/=":
			return first_value / second_value
		"*", "*=":
			return first_value * second_value
		"%":
			return first_value % second_value
		"and":
			return first_value and second_value
		"or":
			return first_value or second_value
		_:
			assert(false, "Unknown operator")


# Check if a dialog line contains meaninful information
func is_valid(line: DialogLine) -> bool:
	if line.type == DialogConstants.TYPE_DIALOG and line.dialog == "":
		return false
	if line.type == DialogConstants.TYPE_MUTATION and line.mutation == null:
		return false
	if line.type == DialogConstants.TYPE_RESPONSE and line.responses.size() == 0:
		return false
	return true


# Check if a given property exists
func has_property(thing: Object, name: String) -> bool:
	if thing == null:
		return false

	for p in thing.get_property_list():
		if _node_properties.has(p.name):
			# Ignore any properties on the base Node
			continue
		if p.name == name:
			return true

	return false


func cleanup() -> void:
	for line in _trash.get_children():
		line.queue_free()
