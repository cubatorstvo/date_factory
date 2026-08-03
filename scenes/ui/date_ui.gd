extends Control
## Manual dating overlay. Observation → interpretation (hypothesis).

@onready var title: Label = $Panel/VBox/Title
@onready var hints: Label = $Panel/VBox/Hints
@onready var phase_label: Label = $Panel/VBox/Phase
@onready var emotion_label: Label = $Panel/VBox/Emotion
@onready var buttons: VBoxContainer = $Panel/VBox/Buttons

var _prompt_label: Label
var _coach_label: Label
var _feedback_label: Label


func _ready() -> void:
	add_to_group("date_ui")
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := get_node_or_null("Dim") as ColorRect
	if dim:
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_prompt_label()
	_ensure_coach_labels()
	Game.dating.date_ui_open.connect(_open)
	Game.dating.date_ui_close.connect(_close)
	Game.dating.date_phase.connect(_on_phase)
	EventBus.notify.connect(_on_notify)


func _ensure_prompt_label() -> void:
	if _prompt_label != null and is_instance_valid(_prompt_label):
		return
	var vbox := get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return
	_prompt_label = Label.new()
	_prompt_label.name = "Prompt"
	_prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_prompt_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_prompt_label)
	vbox.move_child(_prompt_label, phase_label.get_index() + 1)


func _ensure_coach_labels() -> void:
	var vbox := get_node_or_null("Panel/VBox") as VBoxContainer
	if vbox == null:
		return
	if _coach_label == null or not is_instance_valid(_coach_label):
		_coach_label = Label.new()
		_coach_label.name = "Coach"
		_coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_coach_label.add_theme_font_size_override("font_size", 14)
		_coach_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
		vbox.add_child(_coach_label)
		vbox.move_child(_coach_label, phase_label.get_index())
	if _feedback_label == null or not is_instance_valid(_feedback_label):
		_feedback_label = Label.new()
		_feedback_label.name = "Feedback"
		_feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_feedback_label.add_theme_font_size_override("font_size", 13)
		_feedback_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
		vbox.add_child(_feedback_label)
		vbox.move_child(_feedback_label, emotion_label.get_index() + 1)


func _close() -> void:
	visible = false
	if buttons:
		for c in buttons.get_children():
			c.queue_free()


func _on_notify(message: String, kind: StringName) -> void:
	if kind != &"date_fx":
		return
	if message.begins_with("DATE_EMOTION:"):
		var emo := message.trim_prefix("DATE_EMOTION:")
		emotion_label.text = "Реакция: %s" % _emo_ru(emo)
	elif message == "DATE_CHOICE_DONE":
		_show_choice_feedback()


func _emo_ru(emo: String) -> String:
	match emo:
		"delighted":
			return "в восторге"
		"happy":
			return "довольна"
		"annoyed":
			return "раздражена"
		_:
			return "нейтрально"


func _open(payload: Dictionary) -> void:
	_ensure_prompt_label()
	_ensure_coach_labels()
	title.text = "Свидание: %s" % str(payload.get("title", ""))
	var hs: PackedStringArray = PackedStringArray()
	for h in payload.get("hints", []):
		hs.append(str(h))
	hints.text = "\n".join(hs)
	if _prompt_label:
		_prompt_label.text = str(payload.get("prompt", ""))
	emotion_label.text = "Реакция: нейтрально"
	if _feedback_label:
		_feedback_label.text = ""
	_refresh_coach()
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.modulate.a = 0.0


func show_after_intro() -> void:
	visible = true
	_refresh_coach()
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.22)
	Sfx.play_ui(&"date_ok")


func _refresh_coach() -> void:
	if _coach_label == null:
		return
	if bool(Game.quests.flags.get("date_hypothesis_taught", false)):
		_coach_label.text = ""
		return
	_coach_label.text = "Обучение: сверху — наблюдение (факт). Твой ответ — гипотеза о том, что ей важно. Одна верная реакция не раскрывает черту: нужно подтвердить на другом наблюдении. Связь растёт отдельно от знания."


func _mark_hypothesis_taught() -> void:
	if bool(Game.quests.flags.get("date_hypothesis_taught", false)):
		return
	Game.quests.flags["date_hypothesis_taught"] = true
	if _coach_label:
		_coach_label.text = ""


func _show_choice_feedback() -> void:
	if _feedback_label == null:
		return
	var choices: Array = Game.dating.active_manual.get("choices", [])
	if choices.is_empty():
		return
	var last: Dictionary = choices[choices.size() - 1]
	var quality: String = str(last.get("quality", "ok"))
	if bool(last.get("confirmed", false)):
		_feedback_label.text = "Черта подтверждена — можно опираться на неё дальше."
	elif bool(last.get("hypothesis", false)):
		_feedback_label.text = "Гипотеза записана. Нужно ещё одно похожее подтверждение."
	elif bool(last.get("rejected", false)):
		_feedback_label.text = "Гипотеза не подтвердилась. Наблюдение остаётся в журнале."
	elif quality == "ok":
		_feedback_label.text = "Нейтрально — связь чуть сдвинулась, знание почти нет."
	else:
		_feedback_label.text = ""
	_mark_hypothesis_taught()


func _on_phase(phase_index: int, options: Array) -> void:
	_ensure_prompt_label()
	_ensure_coach_labels()
	_show_choice_feedback()
	phase_label.text = "Наблюдение %d/3 — ответь реакцией, не названием черты" % (phase_index + 1)
	var prompt := ""
	if not options.is_empty():
		prompt = str(options[0].get("prompt", ""))
	if prompt.is_empty():
		prompt = str(Game.dating.active_manual.get("prompt", ""))
	if _prompt_label:
		_prompt_label.text = prompt
	var tid := str(Game.dating.active_manual.get("target_id", ""))
	if not tid.is_empty():
		hints.text = "\n".join(Game.dating.profile_hints(tid, true))
	_refresh_coach()
	for c in buttons.get_children():
		c.queue_free()
	for o in options:
		var b := Button.new()
		b.text = str(o.get("label", o.get("id", "?")))
		b.custom_minimum_size = Vector2(0, 36)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var oid := str(o.get("id", ""))
		b.pressed.connect(func(): Game.dating.choose_manual(oid))
		buttons.add_child(b)
