extends CanvasLayer
## Barber overlay: change hero hair/beard/style display tags.

const UiEscapeScript := preload("res://core/ui_escape.gd")

const HAIRS := ["short", "bob", "pony", "long", "bun"]
const BEARDS := ["clean", "stubble", "full", "goatee"]
const STYLES := ["casual", "sharp", "romantic", "sport", "edgy"]

var _root: Control
var _hint: Label
var _hair: String = "short"
var _beard: String = "clean"
var _style: String = "casual"


func _ready() -> void:
	add_to_group("barber_ui")
	layer = 27
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
	dim.color = Color(0.08, 0.04, 0.05, 0.58)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_top = -220.0
	panel.offset_right = 280.0
	panel.offset_bottom = 220.0
	_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Барбер Agency Row"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_hint)
	vbox.add_child(_make_row("Волосы", HAIRS, func(v: String) -> void: _hair = v))
	vbox.add_child(_make_row("Борода", BEARDS, func(v: String) -> void: _beard = v))
	vbox.add_child(_make_row("Стиль", STYLES, func(v: String) -> void: _style = v))
	var apply_btn := Button.new()
	apply_btn.text = "Подстричься (−25$)"
	apply_btn.pressed.connect(_apply)
	vbox.add_child(apply_btn)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)


func _make_row(label: String, options: Array, on_pick: Callable) -> VBoxContainer:
	var box := VBoxContainer.new()
	var l := Label.new()
	l.text = label
	box.add_child(l)
	var row := HBoxContainer.new()
	box.add_child(row)
	for opt in options:
		var btn := Button.new()
		btn.text = str(opt)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured := str(opt)
		btn.pressed.connect(func() -> void:
			on_pick.call(captured)
			_hint.text = "Выбрано: %s / %s / %s" % [_hair, _beard, _style]
		)
		row.add_child(btn)
	return box


func open() -> void:
	if not DatePlaces.is_agency_row_unlocked():
		EventBus.toast("Барбер откроется с районом агентства", &"warn")
		return
	if Game.city != null:
		_hair = str(Game.city.hero_style.get("hair", "short"))
		_beard = str(Game.city.hero_style.get("beard", "clean"))
		var tags: Array = Game.city.hero_style.get("style_tags", [])
		_style = str(tags[0]) if not tags.is_empty() else "casual"
		_hint.text = "Сейчас: %s" % Game.city.hero_style_label()
	else:
		_hint.text = "Выбери волосы, бороду и тег стиля."
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not visible:
		return
	visible = false
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply() -> void:
	if Game.city == null:
		return
	var result: Dictionary = Game.city.apply_barber_style(_hair, _beard, _style)
	if bool(result.get("ok", false)):
		close()
