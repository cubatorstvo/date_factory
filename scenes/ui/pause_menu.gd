class_name PauseMenu
extends CanvasLayer

const UiEscapeScript := preload("res://core/ui_escape.gd")

@onready var continue_button: Button = $Center/Panel/Content/Continue
@onready var settings_button: Button = $Center/Panel/Content/Settings
@onready var save_button: Button = $Center/Panel/Content/Save
@onready var load_button: Button = $Center/Panel/Content/Load
@onready var main_menu_button: Button = $Center/Panel/Content/MainMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	add_to_group("pause_ui")
	continue_button.pressed.connect(close)
	settings_button.pressed.connect(_open_settings)
	save_button.pressed.connect(Game.save_game)
	load_button.pressed.connect(Game.load_game)
	main_menu_button.pressed.connect(_main_menu)


func _input(event: InputEvent) -> void:
	# Use _input (not unhandled) so Esc wins even when a LineEdit/Button has focus.
	if not event.is_action_pressed("ui_cancel"):
		return
	if not _in_gameplay_scene():
		return

	# 1) Settings on top of pause
	var settings := get_node_or_null("../SettingsMenu")
	if settings != null and bool(settings.visible):
		if settings.has_method("close"):
			settings.call("close")
		else:
			settings.visible = false
		get_viewport().set_input_as_handled()
		return

	# 2) Close pause itself
	if visible:
		close()
		get_viewport().set_input_as_handled()
		return

	# 3) Always dismiss any stuck/open UI before opening pause
	if UiEscapeScript.dismiss_overlays(get_tree()):
		get_viewport().set_input_as_handled()
		return

	# 4) Nothing open → open pause
	open()
	get_viewport().set_input_as_handled()


func open() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	Sfx.play_ui(&"click")


func close() -> void:
	visible = false
	get_tree().paused = false
	if not UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	var settings := get_node_or_null("../SettingsMenu")
	if settings != null and settings.has_method("open"):
		settings.call("open")


func _main_menu() -> void:
	close()
	get_tree().change_scene_to_file("res://scenes/boot/boot.tscn")


func _in_gameplay_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and (scene.scene_file_path.contains("main.tscn") or scene.name == "Main")
