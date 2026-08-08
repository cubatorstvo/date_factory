class_name MoneyMinigame
extends CanvasLayer
## Money Contest overlay UI + GameState money spend seam (MODULE 07D / MODULE 22).
## Does NOT mutate Authority / defeated / XP / UP / relationships.


signal match_finished(result: RivalCompetitionResult)

const TITLE_TEXT: String = "Денежное противостояние"

var match_state: MoneyMatch = null
var accept_input: bool = true
var auto_tick: bool = true
var _finished_emitted: bool = false
var _result_hold: float = 0.0
var _pending_result: RivalCompetitionResult = null
var _request: RivalCompetitionRequest = null
var _rival_actor: Node3D = null
var _awaiting_spend: bool = false

var _root: Control = null
var _title_label: Label = null
var _score_label: Label = null
var _lot_label: Label = null
var _bid_label: Label = null
var _money_label: Label = null
var _tell_label: Label = null
var _feedback_label: Label = null
var _timer_label: Label = null
var _btn_stop: Button = null
var _btn_raise: Button = null
var _btn_outbid: Button = null
var _btn_buyout: Button = null


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()


func setup(
	request: RivalCompetitionRequest,
	is_story: bool,
	rng_seed: int = -1,
	rival_actor: Node3D = null,
	override_starting_money: int = -1,
) -> void:
	_request = request
	_rival_actor = rival_actor
	var starting: int = override_starting_money
	if starting < 0:
		starting = _read_money()
	var player_cap: int = request.player_level
	var rival_cap: int = request.rival_level
	match_state = MoneyMatch.new()
	match_state.setup(player_cap, rival_cap, is_story, starting, rng_seed)
	_finished_emitted = false
	_result_hold = 0.0
	_pending_result = null
	_awaiting_spend = false
	_present_rival(&"idle")
	_refresh_ui()
	_try_emit_finished(false)


func setup_match(state: MoneyMatch) -> void:
	match_state = state
	_finished_emitted = false
	_result_hold = 0.0
	_pending_result = null
	_awaiting_spend = false
	_refresh_ui()


func force_finish_emit() -> void:
	_result_hold = 0.0
	_try_emit_finished(true)


func _read_money() -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return 0
	return int(gs.call("get_money"))


func _can_afford(amount: int) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("can_afford", amount))


func _spend(amount: int) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("spend_money", amount))


func _process(delta: float) -> void:
	if _result_hold > 0.0:
		_result_hold = maxf(0.0, _result_hold - delta)
		if _result_hold <= 0.0:
			_try_emit_finished(false)
		return
	if match_state == null:
		return
	if match_state.ended:
		_try_emit_finished(false)
		return
	var prev_phase: MoneyMatch.Phase = match_state.phase
	var prev_fb: MoneyMatch.Feedback = match_state.last_feedback
	if auto_tick and not _awaiting_spend:
		match_state.tick(delta, _read_money())
	if (
		match_state.last_feedback != prev_fb
		or match_state.phase != prev_phase
	):
		_on_phase_or_feedback_changed(prev_phase, prev_fb)
	_refresh_ui()
	_try_emit_finished(false)


func _on_phase_or_feedback_changed(
	_prev_phase: MoneyMatch.Phase,
	_prev_fb: MoneyMatch.Feedback,
) -> void:
	match match_state.last_feedback:
		MoneyMatch.Feedback.RIVAL_RAISED:
			_present_rival(&"gesture")
			_audio_play_sfx(AudioIds.MONEY_RIVAL_RAISE)
		MoneyMatch.Feedback.RIVAL_FOLDED:
			_present_rival(&"react")
			_audio_play_sfx(AudioIds.MONEY_WIN)
		MoneyMatch.Feedback.PLAYER_STOPPED:
			_present_rival(&"gesture")
			_audio_play_sfx(AudioIds.MONEY_LOSS)
		MoneyMatch.Feedback.BROKE:
			_present_rival(&"gesture")
			_audio_play_sfx(AudioIds.MONEY_LOSS)
		_:
			pass


func _unhandled_key_input(event: InputEvent) -> void:
	if not accept_input or match_state == null or match_state.ended:
		return
	if _result_hold > 0.0:
		return
	if match_state.phase != MoneyMatch.Phase.PLAYER_DECISION:
		return
	if _awaiting_spend or match_state.action_locked:
		return
	if not (event is InputEventKey):
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			_attempt_action(MoneyMatch.Action.STOP)
			get_viewport().set_input_as_handled()
		KEY_2:
			_attempt_action(MoneyMatch.Action.RAISE)
			get_viewport().set_input_as_handled()
		KEY_3:
			_attempt_action(MoneyMatch.Action.OUTBID)
			get_viewport().set_input_as_handled()
		KEY_4:
			_attempt_action(MoneyMatch.Action.BUYOUT)
			get_viewport().set_input_as_handled()


func _attempt_action(action: MoneyMatch.Action) -> void:
	if match_state == null or match_state.ended:
		return
	if match_state.phase != MoneyMatch.Phase.PLAYER_DECISION:
		return
	if _awaiting_spend or match_state.action_locked:
		return
	var money: int = _read_money()
	if action != MoneyMatch.Action.STOP:
		if not match_state.is_action_unlocked(action):
			return
		if not match_state.is_action_affordable(action, money):
			return
	var outcome: Dictionary = match_state.try_player_action(action, money)
	if not bool(outcome.get("ok", false)):
		return
	if action == MoneyMatch.Action.RAISE or action == MoneyMatch.Action.OUTBID:
		_audio_play_sfx(AudioIds.MONEY_STAKE_RAISE)
	if bool(outcome.get("awaiting_spend_confirm", false)):
		var amount: int = int(outcome.get("needs_spend", 0))
		_awaiting_spend = true
		var ok: bool = false
		if amount > 0 and _can_afford(amount):
			ok = _spend(amount)
			if ok:
				_audio_play_sfx(AudioIds.MONEY_SPENT)
		match_state.confirm_player_win_spend(ok)
		_awaiting_spend = false
	_refresh_ui()
	_try_emit_finished(false)


func _try_emit_finished(force: bool) -> void:
	if _finished_emitted or match_state == null or not match_state.ended:
		return
	if _pending_result == null:
		_pending_result = match_state.build_result_once()
		if _pending_result == null:
			return
		if not force:
			MinigameShell.build_result_overlay(_root, _pending_result)
			_result_hold = MinigameShell.RESULT_HOLD_SEC
			accept_input = false
			_refresh_ui()
			return
	if not force and _result_hold > 0.0:
		return
	_finished_emitted = true
	accept_input = false
	match_finished.emit(_pending_result)


func _present_rival(alias: StringName) -> void:
	if _rival_actor == null or not is_instance_valid(_rival_actor):
		return
	if _rival_actor.has_method("play_semantic") and bool(_rival_actor.call("has_animation", alias)):
		_rival_actor.call("play_semantic", alias)
		return
	if alias != &"idle" and _rival_actor.has_method("play_semantic"):
		if bool(_rival_actor.call("has_animation", &"gesture")):
			_rival_actor.call("play_semantic", &"gesture")


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	MinigameShell.apply_theme(_root)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.text = TITLE_TEXT
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_label.offset_left = -360.0
	_title_label.offset_right = 360.0
	_title_label.offset_top = 28.0
	_title_label.offset_bottom = 64.0
	_title_label.add_theme_font_size_override("font_size", 26)
	_root.add_child(_title_label)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -380.0
	panel.offset_right = 380.0
	panel.offset_top = -340.0
	panel.offset_bottom = -20.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_score_label)

	_lot_label = Label.new()
	_lot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lot_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_lot_label)

	_money_label = Label.new()
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_money_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_money_label)

	_bid_label = Label.new()
	_bid_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bid_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(_bid_label)

	_tell_label = Label.new()
	_tell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tell_label.add_theme_font_size_override("font_size", 15)
	vbox.add_child(_tell_label)

	_timer_label = Label.new()
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_timer_label)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_feedback_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)

	_btn_stop = Button.new()
	_btn_stop.text = "ОТСТУПИТЬ"
	_btn_stop.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.STOP))
	row.add_child(_btn_stop)

	_btn_raise = Button.new()
	_btn_raise.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.RAISE))
	row.add_child(_btn_raise)

	_btn_outbid = Button.new()
	_btn_outbid.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.OUTBID))
	row.add_child(_btn_outbid)

	_btn_buyout = Button.new()
	_btn_buyout.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.BUYOUT))
	row.add_child(_btn_buyout)


func _refresh_ui() -> void:
	if match_state == null:
		return
	if _score_label == null:
		return
	var money: int = _read_money()
	_score_label.text = MinigameShell.format_score(
		match_state.player_score,
		match_state.rival_score,
		match_state.target_score,
	)
	_lot_label.text = "Лот: %s" % match_state.lot_name
	var bid_amount: int = match_state.amount_for_level(match_state.current_bid_level)
	_money_label.text = "Твои деньги: %s" % UiNumberFormat.format_money(money)
	_bid_label.text = "Текущая ставка: %s" % UiNumberFormat.format_money(bid_amount)
	_tell_label.text = "Соперник: %s" % _tell_text(match_state.get_tell())
	_feedback_label.text = _feedback_text()
	if match_state.phase == MoneyMatch.Phase.PLAYER_DECISION and not match_state.action_locked:
		var left: float = maxf(MoneyMatch.DECISION_TIMEOUT - match_state.decision_time, 0.0)
		_timer_label.text = "%.1f" % left
	else:
		_timer_label.text = ""
	_update_buttons(money)


func _update_buttons(money: int) -> void:
	var deciding: bool = (
		match_state.phase == MoneyMatch.Phase.PLAYER_DECISION
		and not match_state.action_locked
		and not _awaiting_spend
		and accept_input
		and not match_state.ended
	)
	_btn_stop.disabled = not deciding
	var raise_amt: int = match_state.amount_for_level(match_state.current_bid_level + 1)
	var outbid_amt: int = match_state.amount_for_level(match_state.current_bid_level + 2)
	var buyout_amt: int = match_state.amount_for_level(match_state.current_bid_level + 3)
	_btn_raise.text = "ПОДНЯТЬ — %s" % UiNumberFormat.format_money(raise_amt)
	_btn_outbid.text = "ПЕРЕБИТЬ — %s" % UiNumberFormat.format_money(outbid_amt)
	_btn_buyout.text = "ВЫКУПИТЬ — %s" % UiNumberFormat.format_money(buyout_amt)
	var raise_ok: bool = deciding and match_state.is_action_affordable(MoneyMatch.Action.RAISE, money)
	var outbid_unlocked: bool = match_state.is_action_unlocked(MoneyMatch.Action.OUTBID)
	var buyout_unlocked: bool = match_state.is_action_unlocked(MoneyMatch.Action.BUYOUT)
	var outbid_ok: bool = (
		deciding and outbid_unlocked
		and match_state.is_action_affordable(MoneyMatch.Action.OUTBID, money)
	)
	var buyout_ok: bool = (
		deciding and buyout_unlocked
		and match_state.is_action_affordable(MoneyMatch.Action.BUYOUT, money)
	)
	_btn_raise.disabled = not raise_ok
	_btn_outbid.disabled = not outbid_ok
	_btn_buyout.disabled = not buyout_ok
	if not outbid_unlocked:
		_btn_outbid.text = "ПЕРЕБИТЬ (ЗАБЛОКИРОВАНО — Капитал 3)"
		_btn_outbid.disabled = true
	if not buyout_unlocked:
		_btn_buyout.text = "ВЫКУПИТЬ (ЗАБЛОКИРОВАНО — Капитал 6)"
		_btn_buyout.disabled = true


func _tell_text(tell: MoneyMatch.Tell) -> String:
	match tell:
		MoneyMatch.Tell.CALM:
			return "СПОКОЕН"
		MoneyMatch.Tell.LOOKING:
			return "СМОТРИТ НА СУММУ"
		MoneyMatch.Tell.TENSE:
			return "НАПРЯГСЯ"
		MoneyMatch.Tell.LAST:
			return "ПОСЛЕДНЯЯ ПОЗИЦИЯ"
		_:
			return ""


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)


func _feedback_text() -> String:
	if match_state.phase == MoneyMatch.Phase.FINISHED:
		return "ФИНИШ"
	match match_state.last_feedback:
		MoneyMatch.Feedback.RIVAL_RAISED:
			return "СОПЕРНИК ПОВЫСИЛ ДО %s" % UiNumberFormat.format_money(
				match_state.last_feedback_amount
			)
		MoneyMatch.Feedback.RIVAL_FOLDED:
			return "СОПЕРНИК ОТКАЗАЛСЯ ПЛАТИТЬ\nКУПЛЕНО ЗА %s" % UiNumberFormat.format_money(
				match_state.last_feedback_amount
			)
		MoneyMatch.Feedback.PLAYER_STOPPED:
			return "ТЫ РЕШИЛ СОХРАНИТЬ ДЕНЬГИ"
		MoneyMatch.Feedback.BROKE:
			return "НЕЧЕМ ПОВЫШАТЬ"
		_:
			return ""
