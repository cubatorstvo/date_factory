extends CanvasLayer
## GTA/NFS-style district barrier popup: unlock requirements + contents list.

const UiEscapeScript := preload("res://core/ui_escape.gd")

var _root: Control
var _title: Label
var _subtitle: Label
var _unlock: Label
var _contents: VBoxContainer
var _status: Label
var _district_id: StringName = &""


func _ready() -> void:
	add_to_group("district_gate_ui")
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
	dim.color = Color(0.04, 0.06, 0.1, 0.58)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280.0
	panel.offset_top = -240.0
	panel.offset_right = 280.0
	panel.offset_bottom = 240.0
	_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_title)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_subtitle)
	var unlock_hdr := Label.new()
	unlock_hdr.text = "Как открыть"
	unlock_hdr.add_theme_font_size_override("font_size", 16)
	vbox.add_child(unlock_hdr)
	_unlock = Label.new()
	_unlock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_unlock)
	var contents_hdr := Label.new()
	contents_hdr.text = "Что внутри"
	contents_hdr.add_theme_font_size_override("font_size", 16)
	vbox.add_child(contents_hdr)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 140)
	vbox.add_child(scroll)
	_contents = VBoxContainer.new()
	_contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_contents.add_theme_constant_override("separation", 4)
	scroll.add_child(_contents)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_status)
	var close_btn := Button.new()
	close_btn.text = "Понятно"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)


func open(district_id: StringName) -> void:
	_district_id = district_id
	var info: Dictionary = CityDistricts.info(district_id)
	_title.text = str(info.get("title", district_id))
	_subtitle.text = str(info.get("subtitle", ""))
	_unlock.text = str(info.get("unlock_text", "Район ещё закрыт."))
	for c in _contents.get_children():
		c.queue_free()
	var items: Array = info.get("contents", [])
	for raw in items:
		var row := Label.new()
		row.text = "• %s" % str(raw)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_contents.add_child(row)
	var unlocked := false
	if Game != null and Game.city != null and Game.city.has_method("is_district_unlocked"):
		unlocked = bool(Game.city.is_district_unlocked(district_id))
	if unlocked:
		_status.text = "Район уже открыт — барьер снят."
	else:
		_status.text = "Барьер закрыт. Продолжай прогресс, чтобы пройти дальше."
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not visible:
		return
	visible = false
	_district_id = &""
	if UiEscapeScript.any_overlay_open(get_tree()):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
