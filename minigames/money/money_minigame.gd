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

@onready var _root: Control = %Root
@onready var _title_label: Label = %Title
@onready var _score_label: Label = %ScoreLabel
@onready var _lot_label: Label = %LotLabel
@onready var _bid_label: Label = %BidLabel
@onready var _money_label: Label = %MoneyLabel
@onready var _tell_label: Label = %TellLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _timer_label: Label = %TimerLabel
@onready var _btn_stop: Button = %StopButton
@onready var _btn_raise: Button = %RaiseButton
@onready var _btn_outbid: Button = %OutbidButton
@onready var _btn_buyout: Button = %BuyoutButton


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	MinigameShell.apply_theme(_root)
	_btn_stop.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.STOP))
	_btn_raise.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.RAISE))
	_btn_outbid.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.OUTBID))
	_btn_buyout.pressed.connect(func() -> void: _attempt_action(MoneyMatch.Action.BUYOUT))


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
