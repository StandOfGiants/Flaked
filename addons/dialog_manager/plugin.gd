tool
extends EditorPlugin

const DialogResource = preload("res://addons/dialog_manager/dialog_resource.gd")
const DialogExportPlugin = preload("res://addons/dialog_manager/editor_export_plugin.gd")

const MainView = preload("res://addons/dialog_manager/views/main_view.tscn")

var export_plugin = DialogExportPlugin.new()
var main_view


func _enter_tree() -> void:
	add_autoload_singleton("DialogManager", "res://addons/dialog_manager/dialog_manager.gd")
	add_custom_type(
		"DialogLabel",
		"RichTextLabel",
		preload("res://addons/dialog_manager/dialog_label.gd"),
		get_plugin_icon()
	)

	if Engine.editor_hint:
		add_export_plugin(export_plugin)

		main_view = MainView.instance()
		get_editor_interface().get_editor_viewport().add_child(main_view)
		print(main_view)
		main_view.plugin = self
		make_visible(false)


func _exit_tree() -> void:
	remove_custom_type("DialogLabel")
	remove_autoload_singleton("DialogManager")

	if is_instance_valid(main_view):
		main_view.queue_free()

	if export_plugin:
		remove_export_plugin(export_plugin)


func has_main_screen() -> bool:
	return true


func make_visible(next_visible: bool) -> void:
	if is_instance_valid(main_view):
		main_view.visible = next_visible


func get_plugin_name() -> String:
	return "Dialog"


func get_plugin_icon() -> Texture:
	var scale = get_editor_interface().get_editor_scale()
	var base_color = get_editor_interface().get_editor_settings().get_setting(
		"interface/theme/base_color"
	)
	var theme = "light" if base_color.v > 0.5 else "dark"
	return load("res://addons/dialog_manager/assets/icons/icon_%s_%d.svg" % [theme, scale]) as Texture


func handles(object) -> bool:
	return object is DialogResource


func edit(object) -> void:
	if is_instance_valid(main_view):
		main_view.open_resource(object)


func apply_changes() -> void:
	if is_instance_valid(main_view):
		main_view.apply_changes()
