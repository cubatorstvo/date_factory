extends CanvasLayer
## Pause menu — MODULE24 §§56, 64. Replaces prototype PauseOverlay.
class_name PauseMenu

const TITLE_MENU_SCENE: String = "res://ui/frontend/title_menu.tscn"
const SAVE_LOAD_SCENE: String = "res://ui/frontend/save_load_panel.tscn"
const SETTINGS_SCENE: String = "res://ui/frontend/settings_panel.tscn"

@onready var _root: Control = %Root
@onready var _main_panel: Control = %MainPanel
@onready var _confirm_dialog: ConfirmationDialogView = %ConfirmationDialog
@onready var _status_label: Label = %StatusLabel
var _player: PlayerController = null
var _subpanel_open: bool = false
var _visible_menu: bool = false


func _ready() -> void:
	add_to_group("pause_menu")
	layer = 52
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiScaleHelper.apply_to_control(_root)
	_wire_controls()
	hide_menu()
	call_deferred("_bind_player")


func handle_pause_action() -> bool:
	## Called from PlayerController. Return true if handled (do not toggle pause).
	if _subpanel_open:
		return true
	if _visible_menu:
		_resume()
		return true
	return false


func open_from_pause() -> void:
	_bind_player()
	_hide_prototype_overlay()
	_subpanel_open = false
	_visible_menu = true
	visible = true
	if _main_panel != null:
		_main_panel.visible = true
	if _status_label != null:
		_status_label.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func hide_menu() -> void:
	_visible_menu = false
	_subpanel_open = false
	visible = false


func _bind_player() -> void:
	var world: Node = get_node_or_null("/root/World")
	var player: PlayerController = null
	if world != null and world.has_method("get_player"):
		player = world.call("get_player") as PlayerController
	if player == null:
		var tree: SceneTree = get_tree()
		if tree != null:
			player = tree.get_first_node_in_group("player") as PlayerController
	if player == null:
		return
	if _player == player:
		return
	if _player != null and is_instance_valid(_player):
		if _player.control_mode_changed.is_connected(_on_control_mode_changed):
			_player.control_mode_changed.disconnect(_on_control_mode_changed)
	_player = player
	if not _player.control_mode_changed.is_connected(_on_control_mode_changed):
		_player.control_mode_changed.connect(_on_control_mode_changed)
	_on_control_mode_changed(_player.get_control_mode())


func _on_control_mode_changed(mode: PlayerController.ControlMode) -> void:
	if mode == PlayerController.ControlMode.PAUSED:
		open_from_pause()
	elif _visible_menu:
		hide_menu()


func _hide_prototype_overlay() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var overlay: Control = _player.get_node_or_null("FpsHud/PauseOverlay") as Control
	if overlay != null:
		overlay.visible = false


func _wire_controls() -> void:
	%ResumeButton.pressed.connect(_resume)
	%SaveButton.pressed.connect(_open_save)
	%LoadButton.pressed.connect(_open_load)
	%SettingsButton.pressed.connect(_open_settings)
	%TitleButton.pressed.connect(_return_to_title)
	%QuitButton.pressed.connect(_quit_game)


func _resume() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	hide_menu()
	if _player != null and is_instance_valid(_player):
		if _player.has_method("enter_gameplay"):
			_player.call("enter_gameplay")
		else:
			_player.set_control_mode(PlayerController.ControlMode.GAMEPLAY)


func _open_save() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	_subpanel_open = true
	if _main_panel != null:
		_main_panel.visible = false
	var packed: PackedScene = load(SAVE_LOAD_SCENE) as PackedScene
	if packed == null:
		_subpanel_open = false
		_main_panel.visible = true
		return
	var panel: SaveLoadPanel = packed.instantiate() as SaveLoadPanel
	if panel == null:
		return
	add_child(panel)
	panel.open_save(func() -> void:
		_subpanel_open = false
		if _main_panel != null:
			_main_panel.visible = true
	)


func _open_load() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	_subpanel_open = true
	if _main_panel != null:
		_main_panel.visible = false
	var packed: PackedScene = load(SAVE_LOAD_SCENE) as PackedScene
	if packed == null:
		_subpanel_open = false
		_main_panel.visible = true
		return
	var panel: SaveLoadPanel = packed.instantiate() as SaveLoadPanel
	if panel == null:
		return
	add_child(panel)
	panel.open_load(func() -> void:
		_subpanel_open = false
		if _main_panel != null and _visible_menu:
			_main_panel.visible = true
	)
	panel.action_finished.connect(func(ok: bool) -> void:
		if ok:
			hide_menu()
			if _player != null and is_instance_valid(_player) and _player.has_method("enter_gameplay"):
				_player.call("enter_gameplay")
	)


func _open_settings() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	_subpanel_open = true
	if _main_panel != null:
		_main_panel.visible = false
	var packed: PackedScene = load(SETTINGS_SCENE) as PackedScene
	if packed == null:
		_subpanel_open = false
		_main_panel.visible = true
		return
	var panel: SettingsPanel = packed.instantiate() as SettingsPanel
	if panel == null:
		return
	add_child(panel)
	panel.open(func() -> void:
		_subpanel_open = false
		if _main_panel != null:
			_main_panel.visible = true
		UiScaleHelper.apply_to_control(_root)
	)


func _return_to_title() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	_confirm(
		"Несохранённый прогресс будет потерян.\nВернуться в главное меню?",
		func() -> void:
			_do_return_to_title()
	)


func _do_return_to_title() -> void:
	hide_menu()
	if get_tree() != null:
		get_tree().paused = false
	if _player != null and is_instance_valid(_player) and _player.has_method("enter_modal_ui"):
		_player.call("enter_modal_ui")
	FrontendSaveApi.return_to_title()
	var title: Node = get_tree().get_first_node_in_group("title_menu") if get_tree() != null else null
	if title != null and title.has_method("show_menu"):
		title.call("show_menu")
	else:
		var packed: PackedScene = load(TITLE_MENU_SCENE) as PackedScene
		if packed != null:
			get_tree().root.add_child(packed.instantiate())


func _quit_game() -> void:
	_audio_ui(AudioIds.UI_BACK)
	_confirm(
		"Выйти из игры?",
		func() -> void:
			get_tree().quit()
	)


func _confirm(message: String, on_yes: Callable) -> void:
	_subpanel_open = true
	var confirmed_callback: Callable = func() -> void:
		_subpanel_open = false
		if on_yes.is_valid():
			on_yes.call()
	var cancelled_callback: Callable = func() -> void:
		_subpanel_open = false
	_confirm_dialog.open(message, confirmed_callback, cancelled_callback)


func _hide_confirm() -> void:
	_confirm_dialog.close()


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
