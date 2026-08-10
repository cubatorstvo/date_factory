extends CanvasLayer
## Title / main menu — MODULE24 §§59–64.
class_name TitleMenu

const PAUSE_MENU_SCENE: String = "res://ui/frontend/pause_menu.tscn"
const SAVE_LOAD_SCENE: String = "res://ui/frontend/save_load_panel.tscn"
const SETTINGS_SCENE: String = "res://ui/frontend/settings_panel.tscn"
const OPENING_SCENE: String = "res://game/opening/opening_scene.tscn"

signal game_started

@onready var _root: Control = %Root
@onready var _continue_btn: Button = %ContinueButton
@onready var _status_label: Label = %StatusLabel
@onready var _version_label: Label = %VersionLabel
@onready var _confirm_dialog: ConfirmationDialogView = %ConfirmationDialog
var _busy: bool = false
var _opening_scene: OpeningScene = null


func _ready() -> void:
	add_to_group("title_menu")
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	UiScaleHelper.apply_to_control(_root)
	_wire_controls()
	_refresh_continue()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_hud_title_suppressed(true)
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("prepare_for_title"):
		world.call("prepare_for_title")


func show_menu() -> void:
	visible = true
	_refresh_continue()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_hud_title_suppressed(true)
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = false


func hide_menu() -> void:
	visible = false
	_set_hud_title_suppressed(false)


func _wire_controls() -> void:
	_continue_btn.pressed.connect(_on_continue)
	%NewGameButton.pressed.connect(_on_new_game)
	%LoadButton.pressed.connect(_on_load)
	%SettingsButton.pressed.connect(_on_settings)
	%ExitButton.pressed.connect(_on_exit)
	var app_version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	_version_label.text = "v%s" % app_version


func _refresh_continue() -> void:
	if _continue_btn == null:
		return
	_continue_btn.disabled = not FrontendSaveApi.has_any_valid_save()


func _on_continue() -> void:
	if _busy:
		return
	_audio_ui(AudioIds.UI_CLICK)
	_busy = true
	var ok: bool = FrontendSaveApi.continue_latest()
	_busy = false
	if ok:
		_enter_gameplay()
	else:
		_status_label.text = "Не удалось продолжить игру."
		_audio_ui(AudioIds.UI_DENIED)


func _on_new_game() -> void:
	if _busy:
		return
	_audio_ui(AudioIds.UI_CLICK)
	if FrontendSaveApi.has_any_valid_save():
		_confirm(
			"Начать новую игру?\nТекущие сохранения не удалятся.",
			_start_new_game
		)
	else:
		_start_new_game()


func _start_new_game() -> void:
	if _busy:
		return
	_busy = true
	var packed: PackedScene = load(OPENING_SCENE) as PackedScene
	if packed == null:
		_restore_after_opening_failure("Начальная сцена недоступна.")
		return
	_opening_scene = packed.instantiate() as OpeningScene
	if _opening_scene == null:
		_restore_after_opening_failure("Не удалось открыть начальную сцену.")
		return
	_opening_scene.completed.connect(_on_opening_completed, CONNECT_ONE_SHOT)
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		_opening_scene.free()
		_opening_scene = null
		_restore_after_opening_failure("Не удалось открыть начальную сцену.")
		return
	visible = false
	_set_hud_title_suppressed(true)
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_player"):
		var existing_player: Node = world.call("get_player") as Node
		if existing_player != null and existing_player.has_method("enter_modal_ui"):
			existing_player.call("enter_modal_ui")
	tree.root.add_child(_opening_scene)


func _on_opening_completed() -> void:
	if not _busy:
		return
	var ok: bool = FrontendSaveApi.start_new_game()
	if _opening_scene != null and is_instance_valid(_opening_scene):
		_opening_scene.queue_free()
	_opening_scene = null
	_busy = false
	if ok:
		_enter_gameplay()
	else:
		_restore_after_opening_failure("Не удалось начать новую игру.")


func _restore_after_opening_failure(message: String) -> void:
	_busy = false
	visible = true
	_status_label.text = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_hud_title_suppressed(true)
	_audio_ui(AudioIds.UI_DENIED)


func _on_load() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	var packed: PackedScene = load(SAVE_LOAD_SCENE) as PackedScene
	if packed == null:
		_status_label.text = "Экран загрузки недоступен."
		return
	var panel: SaveLoadPanel = packed.instantiate() as SaveLoadPanel
	if panel == null:
		return
	add_child(panel)
	panel.open_load(func() -> void:
		_refresh_continue()
	)
	panel.action_finished.connect(func(ok: bool) -> void:
		if ok:
			_enter_gameplay()
	)


func _on_settings() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	var packed: PackedScene = load(SETTINGS_SCENE) as PackedScene
	if packed == null:
		_status_label.text = "Экран настроек недоступен."
		return
	var panel: SettingsPanel = packed.instantiate() as SettingsPanel
	if panel == null:
		return
	add_child(panel)
	panel.open(func() -> void:
		UiScaleHelper.apply_to_control(_root)
	)


func _on_exit() -> void:
	_audio_ui(AudioIds.UI_BACK)
	get_tree().quit()


func _enter_gameplay() -> void:
	hide_menu()
	_ensure_pause_menu()
	game_started.emit()
	var world: Node = get_node_or_null("/root/World")
	if world != null and world.has_method("get_player"):
		var player: Node = world.call("get_player") as Node
		if player != null and player.has_method("enter_gameplay"):
			player.call("enter_gameplay")


func _ensure_pause_menu() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var existing: Node = tree.get_first_node_in_group("pause_menu")
	if existing != null:
		return
	var packed: PackedScene = load(PAUSE_MENU_SCENE) as PackedScene
	if packed != null:
		var menu: Node = packed.instantiate()
		tree.root.add_child(menu)


func _confirm(message: String, on_yes: Callable) -> void:
	_confirm_dialog.open(message, on_yes)


func _hide_confirm() -> void:
	_confirm_dialog.close()


func _set_hud_title_suppressed(suppressed: bool) -> void:
	var world: Node = get_node_or_null("/root/World")
	if world == null or not world.has_method("get_game_hud"):
		return
	var hud: Node = world.call("get_game_hud") as Node
	if hud != null and hud.has_method("set_title_suppressed"):
		hud.call("set_title_suppressed", suppressed)


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
