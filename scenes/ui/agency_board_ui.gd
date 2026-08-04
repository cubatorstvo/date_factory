extends CanvasLayer
## Agency office schedule board — overlay, does not replace FPS.

const UiEscapeScript := preload("res://core/ui_escape.gd")

var _root: Control
var _list: VBoxContainer
var _hint: Label


func _ready() -> void:
	add_to_group("agency_board_ui")
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
	dim.color = Color(0.04, 0.06, 0.1, 0.6)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -340.0
	panel.offset_top = -240.0
	panel.offset_right = 340.0
	panel.offset_bottom = 240.0
	_root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "Расписание агентства"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)
	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.text = "Лиды: игрок/клон. Назначения квартир + конфликты вместимости."
	vbox.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 220)
	vbox.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var assign_row := HBoxContainer.new()
	assign_row.add_theme_constant_override("separation", 6)
	vbox.add_child(assign_row)
	var assign_player := Button.new()
	assign_player.text = "Назначить → apt (player)"
	assign_player.pressed.connect(_assign_current.bind("player"))
	assign_row.add_child(assign_player)
	var assign_clone := Button.new()
	assign_clone.text = "Назначить → apt (clone)"
	assign_clone.pressed.connect(_assign_current.bind("clone"))
	assign_row.add_child(assign_clone)
	var buy_row := HBoxContainer.new()
	buy_row.add_theme_constant_override("separation", 4)
	vbox.add_child(buy_row)
	for apt_id in ["apt_cozy", "apt_modern", "apt_creative"]:
		var b := Button.new()
		b.text = "Купить %s" % apt_id.trim_prefix("apt_")
		b.pressed.connect(_buy_apt.bind(apt_id))
		buy_row.add_child(b)
	var refresh := Button.new()
	refresh.text = "Обновить"
	refresh.pressed.connect(_refresh)
	vbox.add_child(refresh)
	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.pressed.connect(close)
	vbox.add_child(close_btn)


func open() -> void:
	if not DatePlaces.is_agency_row_unlocked():
		EventBus.toast("Офис агентства ещё закрыт", &"warn")
		return
	_refresh()
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


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	var entries: Array = []
	if Game.city != null and Game.city.has_method("schedule_board_entries"):
		entries = Game.city.schedule_board_entries()
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "Нет предстоящих свиданий. Назначь в телефоне."
		_list.add_child(empty)
		_hint.text = "Доска пуста — lead=player когда появится бронь."
		return
	var conflicts := 0
	for e in entries:
		var row := PanelContainer.new()
		var vb := VBoxContainer.new()
		row.add_child(vb)
		var line := Label.new()
		var mins := int(e.get("minutes", -1))
		var time_s := "—"
		if mins >= 0:
			time_s = "день %d · %02d:%02d" % [int(e.get("day", 1)), int(mins / 60.0), mins % 60]
		line.text = "%s @ %s" % [str(e.get("girl_name", "?")), str(e.get("place", "?"))]
		vb.add_child(line)
		var meta := Label.new()
		meta.text = "%s · lead=%s" % [time_s, str(e.get("lead", "player"))]
		vb.add_child(meta)
		if bool(e.get("conflict", false)):
			conflicts += 1
			var warn := Label.new()
			warn.text = "⚠ %s" % str(e.get("conflict_note", "Конфликт слота"))
			vb.add_child(warn)
		_list.add_child(row)
	_hint.text = "Записей: %d. Конфликтов: %d." % [entries.size(), conflicts]


func _buy_apt(apt_id: String) -> void:
	if Game.city != null and Game.city.has_method("buy_themed_apartment"):
		Game.city.buy_themed_apartment(StringName(apt_id))
		_refresh()


func _assign_current(lead: String) -> void:
	if Game.city == null or not Game.city.has_method("assign_apartment"):
		return
	var girl := ""
	if Game.dating != null and Game.dating.schedule != null and Game.dating.schedule.has_booking():
		girl = Game.dating.schedule.target_id()
	var apt := "apartment"
	for cand in ["apt_cozy", "apt_modern", "apt_creative"]:
		if Game.city.is_apartment_unlocked(StringName(cand)):
			apt = cand
			break
	Game.city.assign_apartment(StringName(apt), girl, lead)
	_refresh()
