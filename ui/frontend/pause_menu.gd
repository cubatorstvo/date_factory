extends CanvasLayer
## Pause menu — MODULE24 §§56, 64. Replaces prototype PauseOverlay.
class_name PauseMenu

const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const TITLE_FONT_SIZE: int = 28
const BODY_FONT_SIZE: int = 20
const TITLE_MENU_SCRIPT: String = "res://ui/frontend/title_menu.gd"

var _root: Control = null
var _main_panel: Control = null
var _confirm_host: Control = null
var _status_label: Label = null
var _player: PlayerController = null
var _subpanel_open: bool = false
var _visible_menu: bool = false


func _ready() -> void:
	add_to_group("pause_menu")
	layer = 52
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
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


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_apply_theme(_root)
	UiScaleHelper.apply_to_control(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.05, 0.07, 0.72)
	_root.add_child(dim)

	_main_panel = CenterContainer.new()
	_main_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_main_panel)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 420)
	_main_panel.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "ПАУЗА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	vbox.add_child(title)

	vbox.add_child(_menu_button("Продолжить", _resume))
	vbox.add_child(_menu_button("Сохранить", _open_save))
	vbox.add_child(_menu_button("Загрузить", _open_load))
	vbox.add_child(_menu_button("Настройки", _open_settings))
	vbox.add_child(_menu_button("В главное меню", _return_to_title))
	vbox.add_child(_menu_button("Выйти из игры", _quit_game))

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_status_label)

	_confirm_host = Control.new()
	_confirm_host.visible = false
	_confirm_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_confirm_host)


func _menu_button(text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 38)
	btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	btn.pressed.connect(handler)
	return btn


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
	var panel: SaveLoadPanel = SaveLoadPanel.new()
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
	var panel: SaveLoadPanel = SaveLoadPanel.new()
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
	var panel: SettingsPanel = SettingsPanel.new()
	add_child(panel)
	panel.open(func() -> void:
		_subpanel_open = false
		if _main_panel != null:
			_main_panel.visible = true
		if _root != null:
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
		var script_res: Resource = load(TITLE_MENU_SCRIPT)
		if script_res is GDScript:
			var menu: Node = (script_res as GDScript).new()
			get_tree().root.add_child(menu)


func _quit_game() -> void:
	_audio_ui(AudioIds.UI_BACK)
	_confirm(
		"Выйти из игры?",
		func() -> void:
			get_tree().quit()
	)


func _confirm(message: String, on_yes: Callable) -> void:
	_hide_confirm()
	_subpanel_open = true
	_confirm_host.visible = true
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.55)
	_confirm_host.add_child(dim)
	var box := PanelContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(420, 170)
	_confirm_host.add_child(box)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	box.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	var lab := Label.new()
	lab.text = message
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lab)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	var yes := Button.new()
	yes.text = "Да"
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func() -> void:
		_hide_confirm()
		_subpanel_open = false
		if on_yes.is_valid():
			on_yes.call()
	)
	row.add_child(yes)
	var no := Button.new()
	no.text = "Нет"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(func() -> void:
		_hide_confirm()
		_subpanel_open = false
	)
	row.add_child(no)


func _hide_confirm() -> void:
	if _confirm_host == null:
		return
	for child in _confirm_host.get_children():
		child.queue_free()
	_confirm_host.visible = false


func _apply_theme(control: Control) -> void:
	if ResourceLoader.exists(THEME_PATH):
		var theme_res: Resource = load(THEME_PATH)
		if theme_res is Theme:
			control.theme = theme_res as Theme


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
