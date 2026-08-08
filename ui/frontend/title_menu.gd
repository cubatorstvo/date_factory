extends CanvasLayer
## Title / main menu — MODULE24 §§59–64.
class_name TitleMenu

const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const TITLE_FONT_SIZE: int = 42
const BODY_FONT_SIZE: int = 20
const PAUSE_MENU_SCRIPT: String = "res://ui/frontend/pause_menu.gd"

signal game_started

var _root: Control = null
var _continue_btn: Button = null
var _status_label: Label = null
var _confirm_host: Control = null
var _busy: bool = false


func _ready() -> void:
	add_to_group("title_menu")
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
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

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.09, 0.12, 1.0)
	_root.add_child(bg)

	var accent := ColorRect.new()
	accent.set_anchors_preset(Control.PRESET_FULL_RECT)
	accent.offset_left = 0
	accent.offset_right = 0
	accent.offset_top = 0
	accent.offset_bottom = -420
	accent.color = Color(0.16, 0.14, 0.12, 1.0)
	_root.add_child(accent)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 420)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "DATE FACTORY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Главное меню"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	vbox.add_child(subtitle)

	_continue_btn = _menu_button("Продолжить", _on_continue)
	vbox.add_child(_continue_btn)
	vbox.add_child(_menu_button("Новая игра", _on_new_game))
	vbox.add_child(_menu_button("Загрузить", _on_load))
	vbox.add_child(_menu_button("Настройки", _on_settings))
	vbox.add_child(_menu_button("Выход", _on_exit))

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_status_label)

	# Screen-bottom version: sibling of scaled _root so UiScaleHelper cannot push it off-screen.
	var version_label := Label.new()
	var app_version: String = str(ProjectSettings.get_setting("application/config/version", ""))
	version_label.text = "v%s" % app_version
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	version_label.offset_top = -32.0
	version_label.offset_bottom = -10.0
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 0.9))
	add_child(version_label)

	_confirm_host = Control.new()
	_confirm_host.visible = false
	_confirm_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_confirm_host.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_confirm_host)


func _menu_button(text: String, handler: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 40)
	btn.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	btn.pressed.connect(handler)
	return btn


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
	_busy = true
	var ok: bool = FrontendSaveApi.start_new_game()
	_busy = false
	if ok:
		_enter_gameplay()
	else:
		_status_label.text = "Не удалось начать новую игру."
		_audio_ui(AudioIds.UI_DENIED)


func _on_load() -> void:
	_audio_ui(AudioIds.UI_CLICK)
	var panel: SaveLoadPanel = SaveLoadPanel.new()
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
	var panel: SettingsPanel = SettingsPanel.new()
	add_child(panel)
	panel.open(func() -> void:
		if _root != null:
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
	var script_res: Resource = load(PAUSE_MENU_SCRIPT)
	if script_res is GDScript:
		var menu: Node = (script_res as GDScript).new()
		tree.root.add_child(menu)


func _confirm(message: String, on_yes: Callable) -> void:
	_hide_confirm()
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
		if on_yes.is_valid():
			on_yes.call()
	)
	row.add_child(yes)
	var no := Button.new()
	no.text = "Нет"
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(_hide_confirm)
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
