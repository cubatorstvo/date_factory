extends CanvasLayer
## Short gym activity: pick intensity → timing presses on treadmill/weights.

const UiEscapeScript := preload("res://core/ui_escape.gd")

var _root: Control
var _panel: PanelContainer
var _title: Label
var _hint: Label
var _bar_bg: ColorRect
var _bar_zone: ColorRect
var _bar_needle: ColorRect
var _press_btn: Button
var _row: HBoxContainer
var _phase: String = "pick" ## pick | timing | done
var _intensity: String = "normal"
var _presses_done: int = 0
var _presses_needed: int = 4
var _hits: int = 0
var _needle_t: float = 0.0
var _needle_dir: float = 1.0
var _needle_speed: float = 1.4
var _zone_center: float = 0.55
var _zone_half: float = 0.12
var _active: bool = false


func _ready() -> void:
	add_to_group("gym_ui")
	layer = 26
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.08, 0.05, 0.55)
	_root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -260.0
	_panel.offset_top = -200.0
	_panel.offset_right = 260.0
	_panel.offset_bottom = 200.0
	_root.add_child(_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)
	_title = Label.new()
	_title.text = "Фитнес-зал Leisure"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_hint)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 8)
	vbox.add_child(_row)
	_add_intensity_btn("Лёгкая", "light")
	_add_intensity_btn("Обычная", "normal")
	_add_intensity_btn("Интенсив", "intense")
	var bar_wrap := Control.new()
	bar_wrap.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(bar_wrap)
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.15, 0.18, 0.16)
	_bar_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_wrap.add_child(_bar_bg)
	_bar_zone = ColorRect.new()
	_bar_zone.color = Color(0.25, 0.75, 0.4, 0.55)
	_bar_zone.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_wrap.add_child(_bar_zone)
	_bar_needle = ColorRect.new()
	_bar_needle.color = Color(1.0, 0.95, 0.4)
	_bar_needle.custom_minimum_size = Vector2(6, 36)
	bar_wrap.add_child(_bar_needle)
	_press_btn = Button.new()
	_press_btn.text = "Жми в зелёной зоне"
	_press_btn.pressed.connect(_on_press)
	vbox.add_child(_press_btn)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)
	_set_timing_visible(false)


func _add_intensity_btn(label: String, id: String) -> void:
	var btn := Button.new()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(func() -> void: _start_timing(id))
	_row.add_child(btn)


func open() -> void:
	if Game.city != null and not DatePlaces.is_leisure_unlocked():
		EventBus.toast("Зал откроется с парковым районом", &"warn")
		return
	if Game.city != null and not Game.city.can_use_gym_today():
		EventBus.toast(Game.city.gym_cooldown_hint(), &"warn")
		return
	_phase = "pick"
	_presses_done = 0
	_hits = 0
	_active = false
	_row.visible = true
	_set_timing_visible(false)
	var fit := 0.0
	if Game.city != null:
		fit = float(Game.city.fitness_progress)
	_hint.text = "Фитнес: %.0f / 100\nВыбери нагрузку — дальше короткие тайминги." % fit
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not visible:
		return
	_active = false
	visible = false
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _start_timing(intensity: String) -> void:
	_intensity = intensity
	_phase = "timing"
	_presses_done = 0
	_hits = 0
	match intensity:
		"light":
			_presses_needed = 3
			_needle_speed = 1.1
			_zone_half = 0.16
		"intense":
			_presses_needed = 5
			_needle_speed = 1.9
			_zone_half = 0.09
		_:
			_presses_needed = 4
			_needle_speed = 1.45
			_zone_half = 0.12
	_row.visible = false
	_set_timing_visible(true)
	_roll_zone()
	_active = true
	_hint.text = "Тренажёр: попади в зелёную зону (%d/%d)" % [0, _presses_needed]


func _set_timing_visible(on: bool) -> void:
	_bar_bg.get_parent().visible = on
	_press_btn.visible = on


func _roll_zone() -> void:
	_zone_center = randf_range(0.28, 0.78)
	_needle_t = 0.0 if randf() > 0.5 else 1.0
	_needle_dir = 1.0 if _needle_t < 0.5 else -1.0
	_layout_bar()


func _layout_bar() -> void:
	var w: float = maxf(1.0, _bar_bg.size.x)
	var zh: float = _zone_half * 2.0 * w
	var zx: float = (_zone_center - _zone_half) * w
	_bar_zone.offset_left = zx
	_bar_zone.offset_right = zx + zh - w
	_bar_zone.offset_top = 0.0
	_bar_zone.offset_bottom = 0.0
	var nx: float = _needle_t * w - 3.0
	_bar_needle.position = Vector2(nx, 0.0)
	_bar_needle.size = Vector2(6.0, maxf(36.0, _bar_bg.size.y))


func _process(delta: float) -> void:
	if not visible or not _active or _phase != "timing":
		return
	_needle_t += _needle_dir * _needle_speed * delta
	if _needle_t >= 1.0:
		_needle_t = 1.0
		_needle_dir = -1.0
	elif _needle_t <= 0.0:
		_needle_t = 0.0
		_needle_dir = 1.0
	_layout_bar()


func _on_press() -> void:
	if not _active or _phase != "timing":
		return
	var dist := absf(_needle_t - _zone_center)
	var hit := dist <= _zone_half
	_presses_done += 1
	if hit:
		_hits += 1
		EventBus.toast("Вовремя!", &"ok")
	else:
		EventBus.toast("Мимо ритма", &"warn")
	if _presses_done >= _presses_needed:
		_finish()
	else:
		_hint.text = "Тренажёр: попади в зелёную зону (%d/%d)" % [_presses_done, _presses_needed]
		_roll_zone()


func _finish() -> void:
	_active = false
	_phase = "done"
	var score := float(_hits) / float(maxi(1, _presses_needed))
	if Game.city != null and Game.city.has_method("apply_gym_session"):
		Game.city.apply_gym_session(_intensity, score)
	else:
		EventBus.toast("Тренировка завершена", &"ok")
	close()
