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
	title.add_theme_font_size_override("font_size", 26)
	phase_label.add_theme_font_size_override("font_size", 18)
	emotion_label.add_theme_font_size_override("font_size", 18)
	emotion_label.add_theme_color_override("font_color", Color("#F2BD69"))
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := get_node_or_null("Dim") as ColorRect
	if dim:
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		_configure_panel_layout(panel)
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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := get_node_or_null("Panel") as Control
	if panel and visible:
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "modulate:a", 0.0, 0.18)
		tween.tween_property(panel, "scale", Vector2(0.98, 0.98), 0.18)
		await tween.finished
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
		_spawn_reaction_vfx(emo)
		_pulse_emotion()
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
	while hs.size() > 2:
		hs.remove_at(hs.size() - 1)
	hints.text = "   •   ".join(hs)
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
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_coach()
	var panel := get_node_or_null("Panel") as Control
	if panel:
		_configure_panel_layout(panel)
		panel.pivot_offset = panel.size * 0.5
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.97, 0.97)
		var tween := create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.34)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.34)
	Sfx.play_ui(&"date_ok")


func _refresh_coach() -> void:
	if _coach_label == null:
		return
	if bool(Game.quests.flags.get("date_hypothesis_taught", false)):
		_coach_label.text = ""
		return
	_coach_label.text = "Наблюдай → выбери реакцию → подтверди догадку повторным сигналом."


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
	phase_label.text = "НАБЛЮДЕНИЕ %d/3" % (phase_index + 1)
	var prompt := ""
	if not options.is_empty():
		prompt = str(options[0].get("prompt", ""))
	if prompt.is_empty():
		prompt = str(Game.dating.active_manual.get("prompt", ""))
	if _prompt_label:
		_prompt_label.text = prompt
	var tid := str(Game.dating.active_manual.get("target_id", ""))
	if not tid.is_empty():
		var phase_hints: PackedStringArray = Game.dating.profile_hints(tid, true)
		while phase_hints.size() > 2:
			phase_hints.remove_at(phase_hints.size() - 1)
		hints.text = "   •   ".join(phase_hints)
	_refresh_coach()
	for c in buttons.get_children():
		c.queue_free()
	var option_index := 0
	var theme_service := load("res://scenes/ui/chrome/date_factory_theme.gd")
	for o in options:
		var b := Button.new()
		b.text = str(o.get("label", o.get("id", "?")))
		b.custom_minimum_size = Vector2(0, 44)
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		var oid := str(o.get("id", ""))
		b.pressed.connect(func(): _choose_option(b, oid))
		buttons.add_child(b)
		if theme_service:
			theme_service.bind_button(b)
		b.modulate.a = 0.0
		b.position.x = 20.0
		var reveal := create_tween().set_parallel(true)
		reveal.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		reveal.tween_property(b, "modulate:a", 1.0, 0.2).set_delay(option_index * 0.05)
		reveal.tween_property(b, "position:x", 0.0, 0.2).set_delay(option_index * 0.05)
		option_index += 1
	if buttons.get_child_count() > 0:
		(buttons.get_child(0) as Button).grab_focus()


func _configure_panel_layout(panel: Control) -> void:
	panel.anchor_left = 0.18
	panel.anchor_top = 1.0
	panel.anchor_right = 0.82
	panel.anchor_bottom = 1.0
	panel.offset_left = 0.0
	panel.offset_top = -448.0
	panel.offset_right = 0.0
	panel.offset_bottom = -16.0


func _choose_option(button: Button, option_id: String) -> void:
	button.disabled = true
	button.pivot_offset = button.size * 0.5
	var press := create_tween()
	press.tween_property(button, "scale", Vector2(0.98, 0.98), 0.06)
	press.tween_property(button, "scale", Vector2.ONE, 0.08)
	await press.finished
	Game.dating.choose_manual(option_id)


func _pulse_emotion() -> void:
	emotion_label.pivot_offset = emotion_label.size * 0.5
	var pulse := create_tween()
	pulse.tween_property(emotion_label, "scale", Vector2(1.07, 1.07), 0.1)
	pulse.tween_property(emotion_label, "scale", Vector2.ONE, 0.16)


func _spawn_reaction_vfx(emotion: String) -> void:
	var positive := emotion in ["delighted", "happy", "positive", "love", "amused"]
	var glyph := "♥" if positive else "✦"
	var color := Color("#FF83AC") if positive else Color("#E7B562")
	var origin := emotion_label.global_position + emotion_label.size * 0.5
	for i in range(5):
		var particle := Label.new()
		particle.text = glyph
		particle.add_theme_font_size_override("font_size", 22 + i * 2)
		particle.add_theme_color_override("font_color", color)
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		particle.position = origin + Vector2(-30.0 + i * 15.0, 4.0)
		add_child(particle)
		var drift := Vector2(-42.0 + i * 21.0, -62.0 - i * 9.0)
		var fx := create_tween().set_parallel(true)
		fx.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		fx.tween_property(particle, "position", particle.position + drift, 0.65)
		fx.tween_property(particle, "modulate:a", 0.0, 0.65)
		fx.tween_property(particle, "scale", Vector2(1.35, 1.35), 0.65)
		fx.chain().tween_callback(particle.queue_free)
