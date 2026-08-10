class_name FinalDateUI
extends CanvasLayer
## Functional modals for MODULE 21 final date (events, failure, ending).
## MODULE 22: theme + readability only — behavior unchanged.


const ACTION_BUTTON_SCENE: String = "res://ui/common/action_button.tscn"
const SEPARATOR_SCENE: String = "res://ui/common/section_separator.tscn"
const COLOR_NEUTRAL: Color = Color(0.72, 0.76, 0.70, 1.0)
const COLOR_LOCKED: Color = Color(0.78, 0.62, 0.52, 1.0)

signal option_selected(option_id: StringName)
signal continue_pressed()
signal retry_pressed()
signal return_pressed()
signal ending_continue_pressed()

@onready var _root: Control = %Root
@onready var _panel: PanelContainer = %Panel
@onready var _title: Label = %Title
@onready var _body: RichTextLabel = %Body
@onready var _options: VBoxContainer = %Options
@onready var _footer: VBoxContainer = %Footer
var _mode: String = ""
var _option_ids: Array[StringName] = []


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	UiScaleHelper.apply_to_control(_root)
	hide_ui()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	# ESC must not silently abort the final-date attempt (MODULE 21).
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


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
	_set_body_plain(body)
	_add_footer_button(continue_label, _on_continue)
	_open()


func show_event_choices(prompt: String, choices: Array[Dictionary]) -> void:
	_mode = "event"
	_clear_options()
	_title.text = "Финальное свидание"
	_set_body_plain(prompt)
	var inserted_neutral_sep: bool = false
	for choice in choices:
		var oid: StringName = choice.get("id", &"") as StringName
		var label: String = String(choice.get("label", ""))
		var enabled: bool = bool(choice.get("enabled", true))
		var reason: String = String(choice.get("reason", ""))
		var kind: int = int(choice.get("kind", -1))
		var is_neutral: bool = _is_neutral_choice(label, kind)
		if is_neutral and not inserted_neutral_sep:
			var separator: Control = _make_neutral_separator()
			if separator != null:
				_options.add_child(separator)
			inserted_neutral_sep = true
		var packed: PackedScene = load(ACTION_BUTTON_SCENE) as PackedScene
		if packed == null:
			continue
		var btn: Button = packed.instantiate() as Button
		if btn == null:
			continue
		btn.text = _present_choice_label(label, reason, enabled, kind)
		btn.disabled = not enabled
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.custom_minimum_size = Vector2(0, 44)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_neutral:
			btn.add_theme_color_override("font_color", COLOR_NEUTRAL)
			btn.modulate = Color(0.92, 0.95, 0.90, 1.0)
		elif not enabled:
			btn.modulate = Color(0.78, 0.72, 0.68, 1.0)
			btn.add_theme_color_override("font_disabled_color", COLOR_LOCKED)
		var captured: StringName = oid
		if enabled:
			btn.pressed.connect(func() -> void: _emit_option(captured))
		_options.add_child(btn)
		_option_ids.append(oid)
	_open()


func show_failure_rival() -> void:
	_audio_play_sfx(AudioIds.FINAL_FAILURE)
	_mode = "failure_rival"
	_clear_options()
	_title.text = "СВИДАНИЕ ПРЕРВАНО"
	_set_body_failure(
		"Последняя:\n«У нас принято завершать встречу после первого локального свержения.»"
	)
	_add_footer_button("Повторить свидание целиком", _on_retry)
	_add_footer_button("Вернуться", _on_return)
	_open()


func show_failure_connection() -> void:
	_audio_play_sfx(AudioIds.FINAL_FAILURE)
	_mode = "failure_connection"
	_clear_options()
	_title.text = "СВИДАНИЕ ПРЕРВАНО"
	_set_body_failure(
		"Последняя:\n«Ты очень хорошо масштабируешься.\n"
		+ "Я пока не поняла, с кем именно разговариваю.»"
	)
	_add_footer_button("Повторить свидание целиком", _on_retry)
	_add_footer_button("Вернуться", _on_return)
	_open()


func show_success_dialogue() -> void:
	_mode = "success_dialogue"
	_clear_options()
	_title.text = "ЦЕЛЬ ДОСТИГНУТА"
	_set_body_plain(
		"Последняя:\n«Значит, вся эта система была нужна, чтобы в конце дойти сюда лично?»\n\n"
		+ "Герой:\n«Да. Делегировать финал было бы странно.»\n\n"
		+ "Последняя:\n«Это первый разумный предел, который ты назвал сегодня.»"
	)
	_add_footer_button("Далее", _on_continue)
	_open()


func show_ending(summary: String) -> void:
	_audio_play_sfx(AudioIds.FINAL_ENDING)
	_mode = "ending"
	_clear_options()
	_title.text = "DATE FACTORY"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var lines: PackedStringArray = PackedStringArray()
	lines.append("ЦЕЛЬ ДОСТИГНУТА")
	lines.append("")
	var stats: PackedStringArray = _format_ending_stats(summary)
	for line in stats:
		lines.append(line)
	_set_body_plain("\n".join(lines))
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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


func _open() -> void:
	visible = true
	if _panel != null:
		_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _clear_options() -> void:
	_option_ids.clear()
	if _title != null:
		_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _body != null:
		_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	if _options != null:
		for child in _options.get_children():
			child.queue_free()
	if _footer != null:
		for child in _footer.get_children():
			child.queue_free()


func _add_footer_button(text: String, cb: Callable) -> void:
	var packed: PackedScene = load(ACTION_BUTTON_SCENE) as PackedScene
	if packed == null:
		return
	var btn: Button = packed.instantiate() as Button
	if btn == null:
		return
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
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


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


func _set_body_plain(text: String) -> void:
	_body.bbcode_enabled = false
	_body.text = text


func _set_body_failure(dialogue: String) -> void:
	_body.bbcode_enabled = true
	_body.text = (
		"%s\n\n[color=#f2e6b8][b]Попытка не засчитана[/b][/color]"
		% dialogue
	)


func _is_neutral_choice(label: String, kind: int) -> bool:
	if kind == int(FinalDateTypes.EventOptionKind.NEUTRAL):
		return true
	return label.begins_with("[Нейтрально]")


func _make_neutral_separator() -> Control:
	var packed: PackedScene = load(SEPARATOR_SCENE) as PackedScene
	if packed == null:
		return null
	var separator: Control = packed.instantiate() as Control
	if separator != null:
		var hint: Label = separator.get_node_or_null("Hint") as Label
		if hint != null:
			hint.add_theme_color_override("font_color", COLOR_NEUTRAL)
	return separator


func _present_choice_label(label: String, reason: String, enabled: bool, kind: int) -> String:
	if _is_neutral_choice(label, kind):
		return label
	var char_name: String = ""
	var body: String = label.strip_edges()
	if body.begins_with("[") and "]" in body:
		var end_bracket: int = body.find("]")
		char_name = body.substr(1, end_bracket - 1).strip_edges()
		body = body.substr(end_bracket + 1).strip_edges()
	var level: int = FinalDateTypes.CHAR_LEVEL_REQUIRED
	var reason_clean: String = reason.strip_edges()
	if reason_clean != "":
		var parts: PackedStringArray = reason_clean.split(" ")
		if parts.size() >= 2:
			var maybe_level: int = int(parts[parts.size() - 1])
			if maybe_level > 0:
				level = maybe_level
			if char_name == "":
				var name_parts: PackedStringArray = PackedStringArray()
				for i in range(parts.size() - 1):
					name_parts.append(parts[i])
				char_name = " ".join(name_parts)
	elif char_name == "":
		char_name = FinalDateTypes.char_label(kind as FinalDateTypes.EventOptionKind)
	var badge: String = "[%s %d]" % [char_name, level]
	var text: String = "%s %s" % [badge, body]
	if not enabled:
		var req: String = ""
		if reason_clean.begins_with("Требуется"):
			req = reason_clean
		elif reason_clean != "":
			req = "Требуется %s" % reason_clean
		else:
			req = "Требуется %s %d" % [char_name, level]
		text = "%s     %s" % [text, req]
	return text


func _format_ending_stats(summary: String) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var raw: String = summary.strip_edges()
	if raw == "":
		return out
	for line in raw.split("\n"):
		var row: String = String(line).strip_edges()
		if row == "":
			continue
		var parts: PackedStringArray = row.split(":", true, 1)
		if parts.size() != 2:
			out.append(row)
			continue
		var key: String = parts[0].strip_edges()
		var value_raw: String = parts[1].strip_edges()
		var value_num: int = int(value_raw)
		var display_key: String = key
		if key == "Клонов" or key == "Клоны":
			display_key = "Клоны"
			out.append("%s: %s" % [display_key, UiNumberFormat.format_compact(value_num)])
		elif key.to_lower().contains("money") or key.contains("Деньги"):
			out.append("%s: %s" % [display_key, UiNumberFormat.format_money(value_num)])
		else:
			out.append("%s: %s" % [display_key, UiNumberFormat.format_grouped(value_num)])
	return out
