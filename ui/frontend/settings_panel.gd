extends CanvasLayer
## Settings panel — MODULE24 §§68–78. Working copy + Apply/Cancel/Defaults.
class_name SettingsPanel

signal closed

var _on_closed: Callable = Callable()
var _saved_snapshot: Dictionary = {}
var _working: Dictionary = {}
@onready var _root: Control = %Root
@onready var _status_label: Label = %StatusLabel
var _sliders: Dictionary = {}
@onready var _fov_slider: HSlider = %FovSlider
var _ui_scale_buttons: Dictionary = {}
@onready var _fullscreen_btn: CheckButton = %FullscreenButton
@onready var _vsync_btn: CheckButton = %VsyncButton
@onready var _show_fps_btn: CheckButton = %ShowFpsButton
var _building: bool = false


func _ready() -> void:
	UiScaleHelper.apply_to_control(_root)
	_wire_controls()


func open(on_closed: Callable = Callable()) -> void:
	_on_closed = on_closed
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_saved_snapshot = FrontendSaveApi.get_settings()
	_working = _saved_snapshot.duplicate(true)
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


func _wire_controls() -> void:
	_register_linear_slider("master", %MasterSlider, true)
	_register_linear_slider("music", %MusicSlider, true)
	_register_linear_slider("sfx", %SfxSlider, true)
	_register_linear_slider("ui", %UiSlider, true)
	_register_linear_slider("ambience", %AmbienceSlider, true)
	_register_slider(
		"mouse_sensitivity",
		%SensitivitySlider,
		func(v: float) -> float: return lerpf(0.04, 0.30, (v - 1.0) / 99.0),
		func(s: float) -> float:
			return clampf(1.0 + ((s - 0.04) / 0.26) * 99.0, 1.0, 100.0),
		false
	)
	_register_linear_slider("camera_feedback", %CameraSlider, false)
	_fov_slider.value_changed.connect(_on_fov_changed)
	_ui_scale_buttons = {
		100: %Scale100Button,
		125: %Scale125Button,
		150: %Scale150Button,
	}
	for percent: int in _ui_scale_buttons.keys():
		var button: Button = _ui_scale_buttons[percent] as Button
		button.pressed.connect(_set_ui_scale_percent.bind(percent))
	_fullscreen_btn.toggled.connect(func(on: bool) -> void:
		if not _building:
			_working["fullscreen"] = on
	)
	_vsync_btn.toggled.connect(func(on: bool) -> void:
		if not _building:
			_working["vsync"] = on
	)
	_show_fps_btn.toggled.connect(func(on: bool) -> void:
		if not _building:
			_working["show_fps"] = on
	)
	%ResetTutorialsButton.pressed.connect(_on_reset_tutorials)
	%ApplyButton.pressed.connect(_on_apply)
	%DefaultsButton.pressed.connect(_on_defaults)
	%CancelButton.pressed.connect(_on_cancel)


func _register_linear_slider(key: String, slider: HSlider, preview_audio: bool) -> void:
	_register_slider(
		key,
		slider,
		func(v: float) -> float: return clampf(v / 100.0, 0.0, 1.0),
		func(s: float) -> float: return clampf(s * 100.0, 0.0, 100.0),
		preview_audio
	)


func _register_slider(
	key: String,
	slider: HSlider,
	to_setting: Callable,
	from_setting: Callable,
	preview_audio: bool,
) -> void:
	slider.value_changed.connect(func(value: float) -> void:
		if _building:
			return
		_working[key] = to_setting.call(value)
		if preview_audio:
			FrontendSaveApi.preview_audio(_working)
	)
	_sliders[key] = {"slider": slider, "from_setting": from_setting}


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


func _audio_ui(sound_id: StringName) -> void:
	var audio: Node = get_node_or_null("/root/AudioDirector")
	if audio != null and audio.has_method("play_ui"):
		audio.call("play_ui", sound_id)
