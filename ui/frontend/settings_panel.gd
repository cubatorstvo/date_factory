extends CanvasLayer
## Settings panel — MODULE24 §§68–78. Working copy + Apply/Cancel/Defaults.
class_name SettingsPanel

signal closed

const THEME_PATH: String = "res://ui/theme/date_factory_theme.tres"
const BODY_FONT_SIZE: int = 18
const TITLE_FONT_SIZE: int = 26

var _on_closed: Callable = Callable()
var _saved_snapshot: Dictionary = {}
var _working: Dictionary = {}
var _root: Control = null
var _status_label: Label = null
var _sliders: Dictionary = {}
var _fov_slider: HSlider = null
var _ui_scale_buttons: Dictionary = {}
var _fullscreen_btn: CheckButton = null
var _vsync_btn: CheckButton = null
var _show_fps_btn: CheckButton = null
var _building: bool = false


func open(on_closed: Callable = Callable()) -> void:
	_on_closed = on_closed
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_saved_snapshot = FrontendSaveApi.get_settings()
	_working = _saved_snapshot.duplicate(true)
	_build_ui()
	_sync_controls_from_working()
	visible = true


func close(apply_cancel_restore: bool = true) -> void:
	if apply_cancel_restore:
		FrontendSaveApi.apply_settings(_saved_snapshot)
	visible = false
	var cb: Callable = _on_closed
	_on_closed = Callable()
	closed.emit()
	if cb.is_valid():
		cb.call()
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_cancel()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_sliders.clear()
	_ui_scale_buttons.clear()

	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_apply_theme(_root)
	UiScaleHelper.apply_to_control(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.05, 0.07, 0.78)
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(640, 620)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "НАСТРОЙКИ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", TITLE_FONT_SIZE)
	vbox.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 420)
	vbox.add_child(scroll)

	var form := VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 10)
	scroll.add_child(form)

	_add_audio_slider(form, "master", "Общая громкость")
	_add_audio_slider(form, "music", "Музыка")
	_add_audio_slider(form, "sfx", "Эффекты")
	_add_audio_slider(form, "ui", "Интерфейс")
	_add_audio_slider(form, "ambience", "Окружение")

	_add_mapped_slider(
		form,
		"mouse_sensitivity",
		"Чувствительность мыши",
		1.0,
		100.0,
		func(v: float) -> float: return lerpf(0.04, 0.30, (v - 1.0) / 99.0),
		func(s: float) -> float: return clampf(1.0 + ((s - 0.04) / 0.26) * 99.0, 1.0, 100.0)
	)
	_add_audio_slider(form, "camera_feedback", "Движение камеры")

	var fov_row := _labeled_row(form, "Поле зрения (FOV)")
	_fov_slider = HSlider.new()
	_fov_slider.min_value = 60.0
	_fov_slider.max_value = 100.0
	_fov_slider.step = 1.0
	_fov_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fov_slider.value_changed.connect(_on_fov_changed)
	fov_row.add_child(_fov_slider)

	var scale_row := _labeled_row(form, "Масштаб UI")
	for percent in [100, 125, 150]:
		var btn := Button.new()
		btn.text = "%d%%" % percent
		btn.toggle_mode = true
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var bound: int = percent
		btn.pressed.connect(func() -> void:
			_set_ui_scale_percent(bound)
		)
		scale_row.add_child(btn)
		_ui_scale_buttons[percent] = btn

	_fullscreen_btn = CheckButton.new()
	_fullscreen_btn.text = "Полноэкранный"
	_fullscreen_btn.toggled.connect(func(on: bool) -> void:
		if _building:
			return
		_working["fullscreen"] = on
	)
	form.add_child(_fullscreen_btn)

	_vsync_btn = CheckButton.new()
	_vsync_btn.text = "Вертикальная синхронизация"
	_vsync_btn.toggled.connect(func(on: bool) -> void:
		if _building:
			return
		_working["vsync"] = on
	)
	form.add_child(_vsync_btn)
	_show_fps_btn = CheckButton.new()
	_show_fps_btn.text = "Показывать FPS"
	_show_fps_btn.toggled.connect(func(on: bool) -> void:
		if _building:
			return
		_working["show_fps"] = on
	)
	form.add_child(_show_fps_btn)

	var reset_tut := Button.new()
	reset_tut.text = "Сбросить подсказки"
	reset_tut.pressed.connect(_on_reset_tutorials)
	form.add_child(reset_tut)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	vbox.add_child(_status_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	vbox.add_child(actions)
	var apply_btn := Button.new()
	apply_btn.text = "Применить"
	apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_btn.pressed.connect(_on_apply)
	actions.add_child(apply_btn)
	var defaults_btn := Button.new()
	defaults_btn.text = "По умолчанию"
	defaults_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defaults_btn.pressed.connect(_on_defaults)
	actions.add_child(defaults_btn)
	var cancel_btn := Button.new()
	cancel_btn.text = "Отмена"
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(_on_cancel)
	actions.add_child(cancel_btn)


func _add_audio_slider(parent: Control, key: String, label_text: String) -> void:
	_add_mapped_slider(
		parent,
		key,
		label_text,
		0.0,
		100.0,
		func(v: float) -> float: return clampf(v / 100.0, 0.0, 1.0),
		func(s: float) -> float: return clampf(s * 100.0, 0.0, 100.0)
	)


func _add_mapped_slider(
	parent: Control,
	key: String,
	label_text: String,
	ui_min: float,
	ui_max: float,
	to_setting: Callable,
	from_setting: Callable,
) -> void:
	var row := _labeled_row(parent, label_text)
	var slider := HSlider.new()
	slider.min_value = ui_min
	slider.max_value = ui_max
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void:
		if _building:
			return
		_working[key] = to_setting.call(v)
		if key in ["master", "music", "sfx", "ui", "ambience"]:
			FrontendSaveApi.preview_audio(_working)
	)
	row.add_child(slider)
	_sliders[key] = {"slider": slider, "from_setting": from_setting}


func _labeled_row(parent: Control, label_text: String) -> HBoxContainer:
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 2)
	parent.add_child(wrap)
	var lab := Label.new()
	lab.text = label_text
	lab.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	wrap.add_child(lab)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	wrap.add_child(row)
	return row


func _sync_controls_from_working() -> void:
	_building = true
	for key in _sliders.keys():
		var entry: Dictionary = _sliders[key] as Dictionary
		var slider: HSlider = entry["slider"] as HSlider
		var from_setting: Callable = entry["from_setting"] as Callable
		slider.value = float(from_setting.call(float(_working.get(key, 0.0))))
	if _fov_slider != null:
		_fov_slider.value = float(_working.get("fov", 75.0))
	var scale_percent: int = int(round(float(_working.get("ui_scale", 1.0)) * 100.0))
	for percent in _ui_scale_buttons.keys():
		var btn: Button = _ui_scale_buttons[percent] as Button
		btn.button_pressed = int(percent) == scale_percent
	if _fullscreen_btn != null:
		_fullscreen_btn.button_pressed = bool(_working.get("fullscreen", false))
	if _vsync_btn != null:
		_vsync_btn.button_pressed = bool(_working.get("vsync", true))
	if _show_fps_btn != null:
		_show_fps_btn.button_pressed = bool(_working.get("show_fps", true))
	_building = false


func _on_fov_changed(v: float) -> void:
	if _building:
		return
	_working["fov"] = v


func _set_ui_scale_percent(percent: int) -> void:
	if _building:
		return
	_working["ui_scale"] = float(percent) / 100.0
	for p in _ui_scale_buttons.keys():
		var btn: Button = _ui_scale_buttons[p] as Button
		btn.button_pressed = int(p) == percent
	UiScaleHelper.set_ui_scale_percent(percent)
	if _root != null:
		UiScaleHelper.apply_to_control(_root)


func _on_apply() -> void:
	if FrontendSaveApi.apply_settings(_working):
		_saved_snapshot = _working.duplicate(true)
		_status_label.text = "Настройки применены"
		_audio_ui(AudioIds.UI_CLICK)
	else:
		_status_label.text = "Не удалось сохранить настройки"
		_audio_ui(AudioIds.UI_DENIED)


func _on_cancel() -> void:
	_audio_ui(AudioIds.UI_BACK)
	close(true)


func _on_defaults() -> void:
	_working = FrontendSaveApi.get_default_settings()
	_sync_controls_from_working()
	FrontendSaveApi.preview_audio(_working)
	_status_label.text = "Значения по умолчанию — нажмите Применить"
	_audio_ui(AudioIds.UI_CLICK)


func _on_reset_tutorials() -> void:
	if FrontendSaveApi.reset_tutorials():
		_status_label.text = "Подсказки сброшены"
		_audio_ui(AudioIds.UI_CLICK)
	else:
		_status_label.text = "Не удалось сбросить подсказки"
		_audio_ui(AudioIds.UI_DENIED)


func _apply_theme(control: Control) -> void:
	if ResourceLoader.exists(THEME_PATH):
		var theme_res: Resource = load(THEME_PATH)
		if theme_res is Theme:
			control.theme = theme_res as Theme


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
