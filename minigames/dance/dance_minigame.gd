class_name DanceMinigame
extends CanvasLayer
## Dance sequence overlay UI (MODULE 07B / MODULE 22 presentation). World stays visible behind.


signal match_finished(result: RivalCompetitionResult)

const TITLE_TEXT: String = "Танцевальное противостояние"

var match_state: DanceMatch = null
var accept_input: bool = true
var auto_tick: bool = true
var _finished_emitted: bool = false
var _result_hold: float = 0.0
var _pending_result: RivalCompetitionResult = null
var _request: RivalCompetitionRequest = null
var _rival_actor: Node3D = null

@onready var _root: Control = %Root
@onready var _title_label: Label = %Title
@onready var _score_label: Label = %ScoreLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _hint_label: Label = %HintLabel
@onready var _sequence_label: Label = %SequenceLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _streak_label: Label = %StreakLabel
@onready var _pulse: ColorRect = %Pulse
var _pulse_base: float = 18.0


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	MinigameShell.apply_theme(_root)


func setup(
	request: RivalCompetitionRequest,
	is_story: bool,
	perks: Dictionary = {},
	rng_seed: int = -1,
	rival_actor: Node3D = null,
) -> void:
	_request = request
	_rival_actor = rival_actor
	var effective: Dictionary = perks.duplicate()
	if effective.is_empty():
		effective = _read_perks_from_game_state()
	match_state = DanceMatch.new()
	match_state.setup(
		request.player_level,
		request.rival_level,
		is_story,
		effective,
		rng_seed,
	)
	_finished_emitted = false
	_result_hold = 0.0
	_pending_result = null
	_refresh_ui()


func setup_match(state: DanceMatch) -> void:
	match_state = state
	_finished_emitted = false
	_result_hold = 0.0
	_pending_result = null
	_refresh_ui()


func force_finish_emit() -> void:
	_result_hold = 0.0
	_try_emit_finished(true)


func _read_perks_from_game_state() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Dictionary = {
		"staged_walk": false,
		"rhythm_in_body": false,
	}
	if gs == null:
		return out
	out["staged_walk"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_STAGED_WALK))
	out["rhythm_in_body"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_RHYTHM_IN_BODY))
	return out


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
	var prev_phase: DanceMatch.Phase = match_state.phase
	var prev_demo: int = match_state.demo_index
	var prev_fb: DanceMatch.Feedback = match_state.last_feedback
	if auto_tick:
		match_state.tick(delta)
	if (
		match_state.phase == DanceMatch.Phase.OPPONENT_DEMO
		and match_state.demo_index != prev_demo
	):
		_present_rival_move(match_state.demo_move)
		_audio_play_sfx(AudioIds.DANCE_PROMPT)
	elif prev_phase != DanceMatch.Phase.OPPONENT_DEMO and match_state.phase == DanceMatch.Phase.OPPONENT_DEMO:
		_present_rival_move(match_state.demo_move)
		_audio_play_sfx(AudioIds.DANCE_PROMPT)
	if match_state.last_feedback != prev_fb and match_state.last_feedback != DanceMatch.Feedback.NONE:
		_present_feedback_sfx(match_state.last_feedback)
	_refresh_ui()
	_try_emit_finished(false)


func _unhandled_input(event: InputEvent) -> void:
	if not accept_input or match_state == null or match_state.ended:
		return
	if _result_hold > 0.0:
		return
	if not match_state.is_input_phase():
		return
	if not event is InputEventKey and not event is InputEventAction:
		pass
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	var move: int = -1
	if event.is_action_pressed("move_forward", false, true):
		move = int(DanceTiming.DanceMove.UP)
	elif event.is_action_pressed("move_backward", false, true):
		move = int(DanceTiming.DanceMove.DOWN)
	elif event.is_action_pressed("move_left", false, true):
		move = int(DanceTiming.DanceMove.LEFT)
	elif event.is_action_pressed("move_right", false, true):
		move = int(DanceTiming.DanceMove.RIGHT)
	if move < 0:
		return
	var before_fb: DanceMatch.Feedback = match_state.last_feedback
	if match_state.press_move(move as DanceTiming.DanceMove):
		if match_state.last_feedback != before_fb and match_state.last_feedback != DanceMatch.Feedback.NONE:
			_present_feedback_sfx(match_state.last_feedback)
		_refresh_ui()
		_try_emit_finished(false)
	get_viewport().set_input_as_handled()


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


func _present_rival_move(move: DanceTiming.DanceMove) -> void:
	if _rival_actor == null or not is_instance_valid(_rival_actor):
		return
	var alias: StringName = &""
	match move:
		DanceTiming.DanceMove.UP:
			alias = &"dance_up"
		DanceTiming.DanceMove.DOWN:
			alias = &"dance_down"
		DanceTiming.DanceMove.LEFT:
			alias = &"dance_left"
		DanceTiming.DanceMove.RIGHT:
			alias = &"dance_right"
	if _rival_actor.has_method("play_semantic") and bool(_rival_actor.call("has_animation", alias)):
		_rival_actor.call("play_semantic", alias)
		return
	if _rival_actor.has_method("play_semantic") and bool(_rival_actor.call("has_animation", &"gesture")):
		_rival_actor.call("play_semantic", &"gesture")
	var visual: Node3D = _rival_actor.get_node_or_null("VisualRoot") as Node3D
	if visual == null:
		visual = _rival_actor
	var offset: Vector3 = Vector3.ZERO
	match move:
		DanceTiming.DanceMove.LEFT:
			offset = Vector3(-0.12, 0.0, 0.0)
		DanceTiming.DanceMove.RIGHT:
			offset = Vector3(0.12, 0.0, 0.0)
		DanceTiming.DanceMove.UP:
			offset = Vector3(0.0, 0.08, -0.08)
		DanceTiming.DanceMove.DOWN:
			offset = Vector3(0.0, -0.06, 0.08)
	var tween: Tween = visual.create_tween()
	var origin: Vector3 = visual.position
	tween.tween_property(visual, "position", origin + offset, 0.12)
	tween.tween_property(visual, "position", origin, 0.18)


func _refresh_ui() -> void:
	if match_state == null:
		return
	_score_label.text = MinigameShell.format_score(
		match_state.player_score,
		match_state.rival_score,
		match_state.target_score,
	)
	_phase_label.text = _phase_text(match_state.phase)
	_sequence_label.text = _sequence_text()
	_streak_label.text = "Серия: %d" % match_state.streak
	_feedback_label.text = _feedback_text(match_state.last_feedback)
	var pulse_scale: float = 1.0
	if match_state.is_input_phase():
		var beat_time: float = float(match_state.beat_index) * DanceMatch.BEAT_INTERVAL
		var dist: float = absf(match_state.phase_time - beat_time)
		pulse_scale = clampf(1.6 - dist * 2.0, 0.7, 1.6)
	elif match_state.phase == DanceMatch.Phase.OPPONENT_DEMO:
		var local_t: float = fmod(match_state.phase_time, DanceMatch.BEAT_INTERVAL)
		pulse_scale = clampf(1.5 - absf(local_t) * 1.5, 0.7, 1.5)
	_pulse.custom_minimum_size = Vector2(_pulse_base * pulse_scale, _pulse_base * pulse_scale)


func _phase_text(p: DanceMatch.Phase) -> String:
	match p:
		DanceMatch.Phase.OPPONENT_DEMO:
			return "СМОТРИ"
		DanceMatch.Phase.PRE_ROLL:
			return "ТВОЙ ХОД" if match_state.is_pre_roll_for_own() else "ПОВТОРИ"
		DanceMatch.Phase.PLAYER_REPEAT:
			return "ПОВТОРИ"
		DanceMatch.Phase.OWN_PREVIEW:
			return "ТВОЙ ХОД"
		DanceMatch.Phase.PLAYER_OWN:
			return "ТВОЙ ХОД"
		DanceMatch.Phase.ROUND_FEEDBACK:
			return "УСПЕХ" if match_state.last_sequence_success else "ПРОВАЛ"
		DanceMatch.Phase.FINISHED:
			return "ФИНИШ"
		_:
			return ""


func _sequence_text() -> String:
	match match_state.phase:
		DanceMatch.Phase.OPPONENT_DEMO:
			return _move_glyph(match_state.demo_move)
		DanceMatch.Phase.PLAYER_REPEAT:
			var slots: PackedStringArray = PackedStringArray()
			for i in match_state.active_sequence.size():
				if i < match_state.beat_index:
					slots.append("·")
				elif (
					i == match_state.beat_index
					and match_state.should_show_rhythm_clue()
				):
					slots.append("[%s]" % _move_glyph(match_state.get_clue_move()))
				else:
					slots.append("_")
			return " ".join(slots)
		DanceMatch.Phase.OWN_PREVIEW, DanceMatch.Phase.PLAYER_OWN:
			var parts: PackedStringArray = PackedStringArray()
			for i in match_state.active_sequence.size():
				var g: String = _move_glyph(match_state.active_sequence[i])
				if (
					match_state.phase == DanceMatch.Phase.PLAYER_OWN
					and i == match_state.beat_index
				):
					parts.append("[%s]" % g)
				else:
					parts.append(g)
			return " ".join(parts)
		_:
			return ""


func _move_glyph(move: DanceTiming.DanceMove) -> String:
	match move:
		DanceTiming.DanceMove.UP:
			return "↑"
		DanceTiming.DanceMove.DOWN:
			return "↓"
		DanceTiming.DanceMove.LEFT:
			return "←"
		DanceTiming.DanceMove.RIGHT:
			return "→"
		_:
			return "?"


func _feedback_text(fb: DanceMatch.Feedback) -> String:
	match fb:
		DanceMatch.Feedback.MISS:
			return "МИМО"
		DanceMatch.Feedback.HIT:
			return "ПОПАЛ"
		DanceMatch.Feedback.PERFECT:
			return "ИДЕАЛЬНО"
		DanceMatch.Feedback.SUCCESS:
			return "УСПЕХ"
		DanceMatch.Feedback.FAIL:
			return "ПРОВАЛ"
		_:
			return ""


func _present_feedback_sfx(fb: DanceMatch.Feedback) -> void:
	match fb:
		DanceMatch.Feedback.HIT, DanceMatch.Feedback.PERFECT:
			_audio_play_sfx(AudioIds.DANCE_CORRECT)
		DanceMatch.Feedback.MISS, DanceMatch.Feedback.FAIL:
			_audio_play_sfx(AudioIds.DANCE_WRONG)
		DanceMatch.Feedback.SUCCESS:
			_audio_play_sfx(AudioIds.DANCE_SEQUENCE_SUCCESS)
		_:
			pass


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
