extends CanvasLayer
## Dating choice UI presentation (MODULE 22) — DatingCore scoring unchanged.

const ACTION_BUTTON_SCENE: String = "res://ui/common/action_button.tscn"
const FREE_REP_REASON: String = "Представительские расходы"
const PUBLIC_SIG_NOTE: String = "Внешность общественного значения"

@onready var _root: Control = $Root
@onready var _panel: PanelContainer = $Root/Panel
@onready var _girl_name: Label = $Root/Panel/Margin/VBox/Header/GirlName
@onready var _phase_label: Label = $Root/Panel/Margin/VBox/Header/PhaseLabel
@onready var _relationship_label: Label = $Root/Panel/Margin/VBox/Header/RelationshipLabel
@onready var _greeting_note: Label = $Root/Panel/Margin/VBox/Header/GreetingNote
@onready var _title: Label = $Root/Panel/Margin/VBox/Center/EventTitle
@onready var _body: Label = $Root/Panel/Margin/VBox/Center/SetupText
@onready var _reaction_score: Label = $Root/Panel/Margin/VBox/Center/ReactionScore
@onready var _reaction_text: Label = $Root/Panel/Margin/VBox/Center/ReactionText
@onready var _choices: VBoxContainer = $Root/Panel/Margin/VBox/Choices

var _core: Node = null
var _relationships: Node = null
var _last_rel_result: RelationshipDateResult = null
var _reaction_hold: bool = false
var _pending_finish: DatingResult = null
var _showing_finish: bool = false
var _ui_number_format: GDScript = null


func _ready() -> void:
	_core = get_node_or_null("/root/DatingCore")
	_relationships = get_node_or_null("/root/Relationships")
	_ui_number_format = _try_load_number_format()
	UiScaleHelper.apply_to_control(_root)
	visible = false
	set_process_unhandled_input(true)
	if _core != null:
		_core.connect("phase_changed", _on_phase_changed)
		_core.connect("reaction_presented", _on_reaction)
		_core.connect("date_finished", _on_finished)
	if _relationships != null and _relationships.has_signal("date_result_applied"):
		if not _relationships.is_connected("date_result_applied", _on_date_result_applied):
			_relationships.connect("date_result_applied", _on_date_result_applied)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# Active date must not be aborted by ESC.
		if _core != null and bool(_core.call("is_date_active")):
			get_viewport().set_input_as_handled()
			return
		if _showing_finish:
			get_viewport().set_input_as_handled()


func open_for_active_date() -> void:
	_reaction_hold = false
	_pending_finish = null
	_showing_finish = false
	visible = true
	_refresh()


func close_ui() -> void:
	_reaction_hold = false
	_pending_finish = null
	_showing_finish = false
	visible = false


func _on_phase_changed(_phase: DatingTypes.Phase) -> void:
	if not visible:
		return
	if _reaction_hold or _showing_finish:
		return
	_refresh()


func _on_reaction(reaction: int, result_text: String) -> void:
	if not visible and _pending_finish == null:
		visible = true
	_show_reaction(reaction, result_text)


func _on_date_result_applied(rel_result: RelationshipDateResult) -> void:
	_last_rel_result = rel_result


func _on_finished(result: DatingResult) -> void:
	if _reaction_hold:
		_pending_finish = result
		return
	_show_finish(result)


func _show_reaction(reaction: int, result_text: String) -> void:
	_reaction_hold = true
	if reaction > 0:
		_audio_play_sfx(AudioIds.RELATIONSHIP_POSITIVE)
	elif reaction < 0:
		_audio_play_sfx(AudioIds.RELATIONSHIP_NEGATIVE)
	else:
		_audio_play_sfx(AudioIds.RELATIONSHIP_NEUTRAL)
	_showing_finish = false
	_update_header()
	_phase_label.text = "РЕАКЦИЯ"
	_greeting_note.visible = false
	_title.text = ""
	_body.text = ""
	_reaction_score.visible = true
	_reaction_score.text = _format_signed(reaction)
	_reaction_text.visible = true
	var authored: String = result_text.strip_edges()
	_reaction_text.text = authored
	UiAccentPulse.play_dating_reaction(_reaction_score, reaction)
	_try_play_date_reaction(reaction)
	_clear_choices()
	_add_btn("Далее", _on_continue_after_reaction)


func _on_continue_after_reaction() -> void:
	_audio_play_ui(AudioIds.UI_CLICK)
	_reaction_hold = false
	_reaction_score.visible = false
	_reaction_text.visible = false
	_reaction_score.text = ""
	_reaction_text.text = ""
	if _pending_finish != null:
		var finish: DatingResult = _pending_finish
		_pending_finish = null
		_show_finish(finish)
		return
	_refresh()


func _show_finish(result: DatingResult) -> void:
	_showing_finish = true
	_reaction_hold = false
	_update_header_for_finish(result.girl_id)
	_title.text = "ИТОГ СВИДАНИЯ"
	_reaction_score.visible = false
	_reaction_text.visible = false
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Свидание: %s" % _format_signed(result.primary_total))
	lines.append("Вечер: %s" % _format_signed(result.secondary_reaction))
	lines.append("Итого: %s" % _format_signed(result.date_delta))
	var rel: RelationshipDateResult = _last_rel_result
	if rel == null and _relationships != null:
		rel = _relationships.call("get_last_applied_result") as RelationshipDateResult
	if rel != null and rel.ok and rel.girl_id == result.girl_id:
		lines.append(
			"Отношения: %s → %s"
			% [_format_signed(rel.relationship_before), _format_signed(rel.relationship_after)]
		)
		if rel.experience_gained > 0:
			lines.append("Опытность +%d" % rel.experience_gained)
		if rel.upgrade_points_gained > 0:
			lines.append("Балл прокачки +%d" % rel.upgrade_points_gained)
		var rel_delta: int = int(rel.relationship_after) - int(rel.relationship_before)
		if rel_delta >= 5:
			UiAccentPulse.play_badge(_relationship_label)
	_body.text = "\n".join(lines)
	_clear_choices()
	_add_btn("Закрыть", _on_close_finished)
	visible = true
	_last_rel_result = null


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
	_showing_finish = false
	_reaction_score.visible = false
	_reaction_text.visible = false
	_reaction_score.text = ""
	_reaction_text.text = ""
	_clear_choices()
	_update_header()
	match session.phase:
		DatingTypes.Phase.ARRIVAL:
			_title.text = "Она пришла"
			_body.text = "Свидание начинается."
			_add_btn("Продолжить", func() -> void: _core.call("continue_arrival"))
			_maybe_second_outfit()
		DatingTypes.Phase.GREETING:
			_title.text = "ПРИВЕТСТВИЕ"
			_body.text = "Выберите, как начать."
			_greeting_note.visible = true
			_greeting_note.text = "Не влияет на отношения"
			_maybe_second_outfit()
			var choices: Array = _core.call("list_greeting_choices") as Array
			for c in choices:
				var d: Dictionary = c as Dictionary
				_add_choice_card(d, true)
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
		DatingTypes.Phase.SECONDARY_EVALUATION:
			_title.text = "Итог"
			_body.text = "Подсчёт вечера…"
		DatingTypes.Phase.FINISHED:
			pass
		_:
			pass


func _fill_actions() -> void:
	var choices: Array = _core.call("list_action_choices") as Array
	for c in choices:
		var d: Dictionary = c as Dictionary
		_add_choice_card(d, false)


func _add_choice_card(d: Dictionary, is_greeting: bool) -> void:
	var label: String = String(d.get("label", ""))
	var available: bool = bool(d.get("available", false))
	var reason: String = String(d.get("reason", "")).strip_edges()
	var aid: StringName = d.get("id", &"") as StringName
	var lines: PackedStringArray = PackedStringArray()
	lines.append(label)
	var req_badge: String = _requirement_badge(d, is_greeting)
	if req_badge != "":
		lines.append(req_badge)
	var free_via_rep: bool = bool(d.get("free_via_representation", false))
	var cost: int = int(d.get("money_cost", 0))
	if free_via_rep:
		lines.append("Бесплатно — %s" % FREE_REP_REASON)
	elif cost > 0 and not is_greeting:
		lines.append("$%d" % cost)
	if bool(d.get("uses_public_significance", false)):
		lines.append(PUBLIC_SIG_NOTE)
	if not available and reason != "":
		lines.append(_format_unavailable_reason(reason))
	var text: String = "\n".join(lines)
	if is_greeting:
		_add_btn(text, func() -> void: _core.call("select_greeting", aid), available)
	else:
		_add_btn(text, func() -> void: _core.call("select_action", aid), available)


func _requirement_badge(d: Dictionary, is_greeting: bool) -> String:
	if is_greeting:
		var reason: String = String(d.get("reason", "")).strip_edges()
		if reason != "" and not bool(d.get("available", false)):
			# Greeting API exposes requirement only when locked; show as badge too.
			if not reason.begins_with("Нужен") and not reason.begins_with("Деньги"):
				return "[%s]" % reason
		return ""
	var need: int = int(d.get("required_level", 0))
	if need <= 0:
		return ""
	var ch_label: String = _char_label(d.get("characteristic", 0))
	return "[%s %d]" % [ch_label, need]


func _format_unavailable_reason(reason: String) -> String:
	if reason.begins_with("Требуется") or reason.begins_with("Нужен"):
		return reason
	if reason.begins_with("Деньги"):
		return reason
	return "Требуется %s" % reason


func _maybe_second_outfit() -> void:
	if bool(_core.call("can_use_second_outfit")):
		_add_btn("Второй образ", func() -> void: _core.call("use_second_outfit"))


func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()


func _add_btn(text: String, cb: Callable, enabled: bool = true) -> void:
	var packed: PackedScene = load(ACTION_BUTTON_SCENE) as PackedScene
	if packed == null:
		return
	var btn: Button = packed.instantiate() as Button
	if btn == null:
		return
	btn.text = text
	btn.disabled = not enabled
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.custom_minimum_size = Vector2(0, 44)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if enabled:
		btn.pressed.connect(cb)
	else:
		btn.modulate = Color(0.75, 0.72, 0.7, 1.0)
	_choices.add_child(btn)


func _update_header() -> void:
	var session: DatingSession = null
	if _core != null:
		session = _core.call("get_session") as DatingSession
	if session == null:
		_girl_name.text = "Свидание"
		_phase_label.text = ""
		_relationship_label.text = ""
		_greeting_note.visible = false
		return
	_girl_name.text = _resolve_girl_name(session.girl_id)
	_phase_label.text = _phase_title(session.phase)
	_relationship_label.text = _relationship_line(session.girl_id)
	var is_greeting: bool = session.phase == DatingTypes.Phase.GREETING
	_greeting_note.visible = is_greeting and not _reaction_hold
	if is_greeting and not _reaction_hold:
		_greeting_note.text = "Не влияет на отношения"


func _update_header_for_finish(girl_id: StringName) -> void:
	if girl_id != &"":
		_girl_name.text = _resolve_girl_name(girl_id)
		_relationship_label.text = _relationship_line(girl_id)
	_phase_label.text = "ИТОГ"
	_greeting_note.visible = false


func _resolve_girl_name(girl_id: StringName) -> String:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db != null and db.has_method("get_girl"):
		var girl: GirlDefinition = db.call("get_girl", girl_id) as GirlDefinition
		if girl != null and girl.display_name.strip_edges() != "":
			return girl.display_name
	return "Свидание"


func _relationship_line(girl_id: StringName) -> String:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("get_girl_relationship"):
		return ""
	if gs.has_method("has_girl_contact") and not bool(gs.call("has_girl_contact", girl_id)):
		return ""
	var rel: int = int(gs.call("get_girl_relationship", girl_id))
	return "Отношения: %s" % _format_signed(rel)


func _phase_title(phase: DatingTypes.Phase) -> String:
	match phase:
		DatingTypes.Phase.ARRIVAL:
			return "ПРИБЫТИЕ"
		DatingTypes.Phase.GREETING:
			return "ПРИВЕТСТВИЕ"
		DatingTypes.Phase.CENTRAL_EVENT:
			return "СОБЫТИЕ"
		DatingTypes.Phase.RESOLVING_ACTION:
			return "ДЕЙСТВИЕ"
		DatingTypes.Phase.ENCORE_DECISION:
			return "БИС"
		DatingTypes.Phase.FAREWELL:
			return "ПРОЩАНИЕ"
		DatingTypes.Phase.SECONDARY_EVALUATION:
			return "ВЕЧЕР"
		DatingTypes.Phase.FINISHED:
			return "ИТОГ"
	return ""


func _char_label(raw: Variant) -> String:
	var c: int = int(raw)
	match c:
		int(GameTypes.PlayerCharacteristic.MUSCLE):
			return "Мышца"
		int(GameTypes.PlayerCharacteristic.APPEARANCE):
			return "Внешность"
		int(GameTypes.PlayerCharacteristic.CAPITAL):
			return "Капитал"
		int(GameTypes.PlayerCharacteristic.AURA):
			return "Аура"
	return "Характеристика"


func _try_play_date_reaction(reaction: int) -> void:
	# Presentation only: play if a GirlActor for this date is in the tree. Never gate [Далее].
	var session: DatingSession = null
	if _core != null:
		session = _core.call("get_session") as DatingSession
	if session == null or session.girl_id == &"":
		return
	var alias: StringName = &"gesture_short"
	if reaction > 0:
		alias = &"react_positive"
	elif reaction < 0:
		alias = &"react_negative"
	var actor: GirlActor = _find_girl_actor(session.girl_id)
	if actor == null:
		return
	if actor.has_method("play_semantic"):
		actor.call("play_semantic", alias)


func _find_girl_actor(girl_id: StringName) -> GirlActor:
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	var found: Array[Node] = tree.root.find_children("*", "GirlActor", true, false)
	for node in found:
		var actor: GirlActor = node as GirlActor
		if actor != null and actor.girl_id == girl_id:
			return actor
	return null


func _format_signed(value: int) -> String:
	if _ui_number_format != null and _ui_number_format.has_method("format_signed"):
		return str(_ui_number_format.call("format_signed", value))
	if value > 0:
		return "+%d" % value
	if value < 0:
		return "%d" % value
	return "0"


func _try_load_number_format() -> GDScript:
	var path: String = "res://ui/ui_number_format.gd"
	if ResourceLoader.exists(path):
		var script: Resource = load(path)
		if script is GDScript:
			return script as GDScript
	return null


func _audio_play_ui(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_ui"):
		ad.call("play_ui", sound_id)


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
