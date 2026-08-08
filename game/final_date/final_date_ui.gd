class_name FinalDateUI
extends CanvasLayer
## Functional modals for MODULE 21 final date (events, failure, ending).


signal option_selected(option_id: StringName)
signal continue_pressed()
signal retry_pressed()
signal return_pressed()
signal ending_continue_pressed()

var _panel: PanelContainer = null
var _title: Label = null
var _body: RichTextLabel = null
var _options: VBoxContainer = null
var _footer: HBoxContainer = null
var _mode: String = ""
var _option_ids: Array[StringName] = []


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide_ui()


func is_open() -> bool:
	return visible and _panel != null and _panel.visible


func get_mode() -> String:
	return _mode


func get_option_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for oid in _option_ids:
		out.append(oid)
	return out


func hide_ui() -> void:
	visible = false
	_mode = ""
	_option_ids.clear()
	if _panel != null:
		_panel.visible = false


func show_plain(title: String, body: String, continue_label: String = "Далее") -> void:
	_mode = "plain"
	_clear_options()
	_title.text = title
	_body.text = body
	_add_footer_button(continue_label, _on_continue)
	_open()


func show_event_choices(prompt: String, choices: Array[Dictionary]) -> void:
	_mode = "event"
	_clear_options()
	_title.text = "Финальное свидание"
	_body.text = prompt
	for choice in choices:
		var oid: StringName = choice.get("id", &"") as StringName
		var label: String = String(choice.get("label", ""))
		var enabled: bool = bool(choice.get("enabled", true))
		var reason: String = String(choice.get("reason", ""))
		var btn := Button.new()
		btn.text = label if reason == "" else "%s  (%s)" % [label, reason]
		btn.disabled = not enabled
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var captured: StringName = oid
		btn.pressed.connect(func() -> void: _emit_option(captured))
		_options.add_child(btn)
		_option_ids.append(oid)
	_open()


func show_failure_rival() -> void:
	_mode = "failure_rival"
	_clear_options()
	_title.text = "СВИДАНИЕ ПРЕРВАНО"
	_body.text = (
		"Последняя:\n«У нас принято завершать встречу после первого локального свержения.»\n\n"
		+ "Попытка не засчитана."
	)
	_add_footer_button("Повторить свидание целиком", _on_retry)
	_add_footer_button("Вернуться", _on_return)
	_open()


func show_failure_connection() -> void:
	_mode = "failure_connection"
	_clear_options()
	_title.text = "СВИДАНИЕ НЕ СЛОЖИЛОСЬ"
	_body.text = (
		"Последняя:\n«Ты очень хорошо масштабируешься.\n"
		+ "Я пока не поняла, с кем именно разговариваю.»\n\n"
		+ "Попытка не засчитана."
	)
	_add_footer_button("Повторить свидание целиком", _on_retry)
	_add_footer_button("Вернуться", _on_return)
	_open()


func show_success_dialogue() -> void:
	_mode = "success_dialogue"
	_clear_options()
	_title.text = "ЦЕЛЬ ДОСТИГНУТА"
	_body.text = (
		"Последняя:\n«Значит, вся эта система была нужна, чтобы в конце дойти сюда лично?»\n\n"
		+ "Герой:\n«Да. Делегировать финал было бы странно.»\n\n"
		+ "Последняя:\n«Это первый разумный предел, который ты назвал сегодня.»"
	)
	_add_footer_button("Далее", _on_continue)
	_open()


func show_ending(summary: String) -> void:
	_mode = "ending"
	_clear_options()
	_title.text = "ПЛАНЕТАРНЫЙ ПРОЕКТ:\nЗАВЕРШЁН"
	var text: String = "ПРИЧИНА:\nЦЕЛЬ ДОСТИГНУТА\n\nDATE FACTORY"
	if summary.strip_edges() != "":
		text += "\n\n" + summary
	_body.text = text
	_add_footer_button("Продолжить", _on_ending_continue)
	_open()


func select_option_by_id(option_id: StringName) -> bool:
	if _mode != "event":
		return false
	if not _option_ids.has(option_id):
		return false
	_emit_option(option_id)
	return true


func press_continue() -> bool:
	if _mode == "plain" or _mode == "success_dialogue":
		_on_continue()
		return true
	if _mode == "ending":
		_on_ending_continue()
		return true
	return false


func press_retry() -> bool:
	if _mode.begins_with("failure"):
		_on_retry()
		return true
	return false


func press_return() -> bool:
	if _mode.begins_with("failure"):
		_on_return()
		return true
	return false


func _build() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(720, 420)
	_panel.offset_left = -360
	_panel.offset_top = -210
	_panel.offset_right = 360
	_panel.offset_bottom = 210
	root.add_child(_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	_panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.fit_content = true
	_body.scroll_active = true
	_body.custom_minimum_size = Vector2(0, 160)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body)
	_options = VBoxContainer.new()
	_options.add_theme_constant_override("separation", 8)
	vbox.add_child(_options)
	_footer = HBoxContainer.new()
	_footer.alignment = BoxContainer.ALIGNMENT_END
	_footer.add_theme_constant_override("separation", 10)
	vbox.add_child(_footer)


func _open() -> void:
	visible = true
	if _panel != null:
		_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _clear_options() -> void:
	_option_ids.clear()
	if _options != null:
		for child in _options.get_children():
			child.queue_free()
	if _footer != null:
		for child in _footer.get_children():
			child.queue_free()


func _add_footer_button(text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(cb)
	_footer.add_child(btn)


func _emit_option(option_id: StringName) -> void:
	option_selected.emit(option_id)


func _on_continue() -> void:
	continue_pressed.emit()


func _on_retry() -> void:
	retry_pressed.emit()


func _on_return() -> void:
	return_pressed.emit()


func _on_ending_continue() -> void:
	ending_continue_pressed.emit()
