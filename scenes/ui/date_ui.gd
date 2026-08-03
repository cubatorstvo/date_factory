extends Control
## Manual dating overlay with profile hints. High canvas layer.

@onready var title: Label = $Panel/VBox/Title
@onready var hints: Label = $Panel/VBox/Hints
@onready var phase_label: Label = $Panel/VBox/Phase
@onready var emotion_label: Label = $Panel/VBox/Emotion
@onready var buttons: VBoxContainer = $Panel/VBox/Buttons


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
	Game.dating.date_ui_open.connect(_open)
	Game.dating.date_ui_close.connect(_close)
	Game.dating.date_phase.connect(_on_phase)
	EventBus.notify.connect(_on_notify)


func _close() -> void:
	visible = false
	if buttons:
		for c in buttons.get_children():
			c.queue_free()


func _on_notify(message: String, kind: StringName) -> void:
	if kind == &"date_fx" and message.begins_with("DATE_EMOTION:"):
		var emo := message.trim_prefix("DATE_EMOTION:")
		emotion_label.text = "Реакция: %s" % _emo_ru(emo)


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
	# Content only — DateStage reveals the panel after the walk-in intro.
	title.text = "Свидание: %s" % str(payload.get("title", ""))
	var hs: PackedStringArray = PackedStringArray()
	for h in payload.get("hints", []):
		hs.append(str(h))
	hints.text = "\n".join(hs)
	emotion_label.text = "Реакция: нейтрально"
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.modulate.a = 0.0


func show_after_intro() -> void:
	visible = true
	var panel := get_node_or_null("Panel") as Control
	if panel:
		panel.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(panel, "modulate:a", 1.0, 0.22)
	Sfx.play_ui(&"date_ok")


func _on_phase(phase_index: int, options: Array) -> void:
	phase_label.text = "Фаза %d/3 — выбери реплику (подсказка в скобках)" % (phase_index + 1)
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
