extends CanvasLayer
## Personal double acceptance terminal (stage 7). Not an instant Create button.

var _root: Control
var _title: Label
var _prompt: Label
var _body: RichTextLabel
var _buttons: VBoxContainer
var _open: bool = false


func _ready() -> void:
	layer = 25
	add_to_group("clone_accept_ui")
	_build()
	visible = false
	Game.clones.acceptance_open.connect(_on_open)
	Game.clones.acceptance_close.connect(_on_close)
	Game.clones.acceptance_step.connect(_on_step)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 420)
	panel.position = Vector2(-280, -210)
	_root.add_child(panel)
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_title)
	_prompt = Label.new()
	_prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_prompt)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.custom_minimum_size = Vector2(0, 180)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body)
	_buttons = VBoxContainer.new()
	vbox.add_child(_buttons)


func _on_open(payload: Dictionary) -> void:
	_open = true
	visible = true
	_title.text = "Приёмка: %s" % str(payload.get("name", "Дубль"))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_close() -> void:
	_open = false
	visible = false
	_clear_buttons()


func _on_step(_idx: int, payload: Dictionary) -> void:
	if not _open:
		visible = true
		_open = true
	_title.text = "%s — %s" % [str(payload.get("name", "Дубль")), str(payload.get("title", ""))]
	_prompt.text = "Шаг %d/%d: %s" % [int(payload.get("step", 0)) + 1, 6, str(payload.get("prompt", ""))]
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]Наблюдение капсулы / тестов[/b]")
	var defects: Array = payload.get("defects", [])
	if defects.is_empty() and not bool(payload.get("is_decide", false)):
		lines.append("Явных аномалий на этом шаге не видно — или они тонкие.")
	else:
		for d in defects:
			lines.append("• %s" % str(d.get("text", d.get("label", "?"))))
	var marks: Array = payload.get("marks", [])
	if not marks.is_empty():
		lines.append("")
		var mark_txt: PackedStringArray = PackedStringArray()
		for m in marks:
			mark_txt.append(str(m))
		lines.append("[b]Отмечено на терминале:[/b] %s" % ", ".join(mark_txt))
	_body.text = "\n".join(lines)
	_rebuild_buttons(payload)


func _clear_buttons() -> void:
	for c in _buttons.get_children():
		c.queue_free()


func _rebuild_buttons(payload: Dictionary) -> void:
	_clear_buttons()
	if bool(payload.get("is_decide", false)):
		_add_btn("Одобрить в строй", func(): Game.clones.decide_acceptance("approve"))
		_add_btn("Условно одобрить", func(): Game.clones.decide_acceptance("conditional"))
		_add_btn("На доработку", func(): Game.clones.decide_acceptance("rework"))
		_add_btn("Утилизировать", func(): Game.clones.decide_acceptance("scrap"))
		return
	var defects: Array = payload.get("defects", [])
	for d in defects:
		var did := str(d.get("id", ""))
		var label := "Отметить: %s" % str(d.get("label", did))
		_add_btn(label, func(): Game.clones.mark_defect(did); _refresh_current())
	# Soft miss option always available.
	_add_btn("Продолжить осмотр (ничего не отмечать)", func(): Game.clones.advance_acceptance())
	if not defects.is_empty():
		_add_btn("Всё выглядит нормально → дальше", func(): Game.clones.advance_acceptance())


func _refresh_current() -> void:
	# Re-emit current step visuals after a mark.
	if Game.clones.pending.is_empty():
		return
	Game.clones._emit_step()


func _add_btn(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 34)
	b.pressed.connect(cb)
	_buttons.add_child(b)
