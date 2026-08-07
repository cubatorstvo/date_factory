extends CanvasLayer
## Functional dating choice UI (MODULE 09) — not final art.

@onready var _panel: PanelContainer = $Root/Panel
@onready var _title: Label = $Root/Panel/Margin/VBox/Title
@onready var _body: Label = $Root/Panel/Margin/VBox/Body
@onready var _reaction: Label = $Root/Panel/Margin/VBox/Reaction
@onready var _choices: VBoxContainer = $Root/Panel/Margin/VBox/Choices

var _core: Node = null


func _ready() -> void:
	_core = get_node_or_null("/root/DatingCore")
	visible = false
	if _core != null:
		_core.connect("phase_changed", _on_phase_changed)
		_core.connect("reaction_presented", _on_reaction)
		_core.connect("date_finished", _on_finished)


func open_for_active_date() -> void:
	visible = true
	_refresh()


func close_ui() -> void:
	visible = false


func _on_phase_changed(_phase: DatingTypes.Phase) -> void:
	if visible:
		_refresh()


func _on_reaction(reaction: int, result_text: String) -> void:
	_reaction.text = "Реакция: %+d" % reaction if reaction != 0 else "Реакция: 0"
	if result_text.strip_edges() != "":
		_reaction.text += " — %s" % result_text


func _on_finished(result: DatingResult) -> void:
	_title.text = "Итог свидания"
	_body.text = "Итог свидания: %+d" % result.date_delta
	_reaction.text = "Вечер: %+d" % result.secondary_reaction if result.secondary_reaction != 0 else "Вечер: 0"
	_clear_choices()
	var btn := Button.new()
	btn.text = "Закрыть"
	btn.pressed.connect(_on_close_finished)
	_choices.add_child(btn)
	visible = true


func _on_close_finished() -> void:
	if _core != null:
		_core.call("close_finished_date")
	close_ui()


func _refresh() -> void:
	if _core == null:
		return
	var session: DatingSession = _core.call("get_session") as DatingSession
	if session == null:
		close_ui()
		return
	_clear_choices()
	match session.phase:
		DatingTypes.Phase.ARRIVAL:
			_title.text = "Она пришла"
			_body.text = "Свидание начинается."
			_add_btn("Продолжить", func() -> void: _core.call("continue_arrival"))
			_maybe_second_outfit()
		DatingTypes.Phase.GREETING:
			_title.text = "Приветствие"
			_body.text = "Выберите, как начать."
			_maybe_second_outfit()
			var choices: Array = _core.call("list_greeting_choices") as Array
			for c in choices:
				var d: Dictionary = c as Dictionary
				var label: String = String(d.get("label", ""))
				var available: bool = bool(d.get("available", false))
				var reason: String = String(d.get("reason", ""))
				var gid: StringName = d.get("id", &"") as StringName
				var text: String = label if available else "%s (%s)" % [label, reason]
				_add_btn(text, func() -> void: _core.call("select_greeting", gid), available)
		DatingTypes.Phase.CENTRAL_EVENT:
			var ev: DatingEventDefinition = _core.call("get_current_event") as DatingEventDefinition
			_title.text = ev.title if ev != null else "Событие"
			_body.text = ev.setup_text if ev != null else ""
			_fill_actions()
		DatingTypes.Phase.FAREWELL:
			var fw: DatingFarewellDefinition = _core.call("get_current_farewell") as DatingFarewellDefinition
			_title.text = fw.title if fw != null else "Прощание"
			_body.text = fw.setup_text if fw != null else ""
			_fill_actions()
		DatingTypes.Phase.ENCORE_DECISION:
			_title.text = "Бис"
			_body.text = "Выйти на бис?"
			_add_btn("Выйти на бис", func() -> void: _core.call("resolve_encore", true))
			_add_btn("Продолжить вечер", func() -> void: _core.call("resolve_encore", false))
		DatingTypes.Phase.RESOLVING_ACTION:
			_title.text = "Действие"
			_body.text = "Ожидание внешнего резолвера…"
		DatingTypes.Phase.FINISHED:
			pass
		_:
			pass


func _fill_actions() -> void:
	var choices: Array = _core.call("list_action_choices") as Array
	for c in choices:
		var d: Dictionary = c as Dictionary
		var label: String = String(d.get("label", ""))
		var available: bool = bool(d.get("available", false))
		var reason: String = String(d.get("reason", ""))
		var aid: StringName = d.get("id", &"") as StringName
		if bool(d.get("free_via_representation", false)):
			label += " — Бесплатно — Представительские расходы"
		if bool(d.get("uses_public_significance", false)):
			label += " — Внешность общественного значения"
		var cost: int = int(d.get("money_cost", 0))
		if cost > 0 and not bool(d.get("free_via_representation", false)):
			label += " ($%s)" % cost
		var text: String = label if available else "%s (%s)" % [label, reason]
		_add_btn(text, func() -> void: _core.call("select_action", aid), available)


func _maybe_second_outfit() -> void:
	if bool(_core.call("can_use_second_outfit")):
		_add_btn("Второй образ", func() -> void: _core.call("use_second_outfit"))


func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()


func _add_btn(text: String, cb: Callable, enabled: bool = true) -> void:
	var btn := Button.new()
	btn.text = text
	btn.disabled = not enabled
	if enabled:
		btn.pressed.connect(cb)
	_choices.add_child(btn)
