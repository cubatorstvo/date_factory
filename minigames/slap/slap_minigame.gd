class_name SlapMinigame
extends CanvasLayer
## Slap timing overlay UI (MODULE 07A / MODULE 22 presentation). World stays visible behind.


signal match_finished(result: RivalCompetitionResult)

const FEEDBACK_HOLD: float = 0.2
const TITLE_TEXT: String = "Пощёчинный бой"
const TRACK_DESIGNED: float = 640.0

var match_state: SlapMatch = null
var accept_input: bool = true
var auto_tick: bool = true
var _feedback_timer: float = 0.0
var _result_hold: float = 0.0
var _finished_emitted: bool = false
var _pending_result: RivalCompetitionResult = null
var _request: RivalCompetitionRequest = null

@onready var _root: Control = %Root
@onready var _title_label: Label = %Title
@onready var _score_label: Label = %ScoreLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _hint_label: Label = %HintLabel
@onready var _special_label: Label = %SpecialLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _track_wrap: Control = %TrackWrap
@onready var _track: ColorRect = %Track
@onready var _zone: ColorRect = %Zone
@onready var _perfect: ColorRect = %Perfect
@onready var _pointer: ColorRect = %Pointer
var _track_width: float = TRACK_DESIGNED


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	MinigameShell.apply_theme(_root)


func setup(
	request: RivalCompetitionRequest,
	is_story: bool,
	perks: Dictionary = {},
	rng_seed: int = -1,
) -> void:
	_request = request
	var effective: Dictionary = perks.duplicate()
	if effective.is_empty():
		effective = _read_perks_from_game_state()
	match_state = SlapMatch.new()
	match_state.setup(
		request.player_level,
		request.rival_level,
		is_story,
		effective,
		rng_seed,
	)
	_finished_emitted = false
	_feedback_timer = 0.0
	_result_hold = 0.0
	_pending_result = null
	_refresh_ui()


func _read_perks_from_game_state() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Dictionary = {
		"no_warmup": false,
		"tough_cheek": false,
		"double_slap": false,
		"counter_argument": false,
		"mass_reserve": false,
		"two_handed": false,
	}
	if gs == null:
		return out
	out["no_warmup"] = bool(gs.call("has_perk", PerkIds.MUSCLE_NO_WARMUP))
	out["tough_cheek"] = bool(gs.call("has_perk", PerkIds.MUSCLE_TOUGH_CHEEK))
	out["double_slap"] = bool(gs.call("has_perk", PerkIds.MUSCLE_DOUBLE_SLAP))
	out["counter_argument"] = bool(gs.call("has_perk", PerkIds.MUSCLE_COUNTER_ARGUMENT))
	out["mass_reserve"] = bool(gs.call("has_perk", PerkIds.MUSCLE_MASS_RESERVE))
	out["two_handed"] = bool(gs.call("has_perk", PerkIds.MUSCLE_TWO_HANDED_ARGUMENT))
	return out


func force_finish_emit() -> void:
	_feedback_timer = 0.0
	_result_hold = 0.0
	_try_emit_finished(true)


func setup_match(state: SlapMatch) -> void:
	match_state = state
	_finished_emitted = false
	_feedback_timer = 0.0
	_result_hold = 0.0
	_pending_result = null
	_refresh_ui()


func _process(delta: float) -> void:
	if _result_hold > 0.0:
		_result_hold = maxf(0.0, _result_hold - delta)
		if _result_hold <= 0.0:
			_try_emit_finished(false)
		return
	if match_state == null or match_state.ended:
		_try_emit_finished(false)
		return
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(0.0, _feedback_timer - delta)
		_refresh_ui()
		return
	if auto_tick:
		var before_feedback: SlapMatch.Feedback = match_state.last_feedback
		var before_ended: bool = match_state.ended
		var before_phase: SlapMatch.Phase = match_state.phase
		var before_player_score: int = match_state.player_score
		var before_rival_score: int = match_state.rival_score
		match_state.tick(delta)
		if match_state.last_feedback != before_feedback and match_state.last_feedback != SlapMatch.Feedback.NONE:
			_feedback_timer = FEEDBACK_HOLD
			_present_feedback_sfx(match_state.last_feedback)
		if match_state.ended and not before_ended:
			_feedback_timer = FEEDBACK_HOLD
		var resolved_by_tick: bool = (
			match_state.player_score != before_player_score
			or match_state.rival_score != before_rival_score
			or match_state.phase != before_phase
			or (match_state.ended and not before_ended)
		)
		if resolved_by_tick:
			# Timeout resolution is always a miss / incoming (defense miss).
			_present_camera_impulse(before_phase, SlapTiming.Result.MISS)
	_refresh_ui()
	_try_emit_finished(false)


func _unhandled_input(event: InputEvent) -> void:
	if not accept_input or match_state == null or match_state.ended:
		return
	if _feedback_timer > 0.0 or _result_hold > 0.0:
		return
	if event.is_action_pressed("minigame_special_1"):
		if match_state.arm_double_slap():
			_refresh_ui()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("minigame_special_2"):
		if match_state.arm_two_handed():
			_refresh_ui()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("minigame_primary"):
		var before: SlapMatch.Feedback = match_state.last_feedback
		var phase_before: SlapMatch.Phase = match_state.phase
		var timing_before: SlapTiming.Result = SlapTiming.evaluate_timing(
			match_state.pointer_position,
			match_state.target_start,
			match_state.target_end,
			match_state.perfect_start,
			match_state.perfect_end,
		)
		if match_state.press_primary():
			if match_state.last_feedback != before and match_state.last_feedback != SlapMatch.Feedback.NONE:
				_feedback_timer = FEEDBACK_HOLD
				_present_feedback_sfx(match_state.last_feedback)
			_present_camera_impulse(phase_before, timing_before)
			_refresh_ui()
			_try_emit_finished(false)
		get_viewport().set_input_as_handled()


func _try_emit_finished(force: bool) -> void:
	if _finished_emitted or match_state == null or not match_state.ended:
		return
	if not force and _feedback_timer > 0.0:
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


func _refresh_ui() -> void:
	if match_state == null:
		return
	_update_track_width()
	_score_label.text = MinigameShell.format_score(
		match_state.player_score,
		match_state.rival_score,
		match_state.target_score,
	)
	if match_state.phase == SlapMatch.Phase.ATTACK:
		_phase_label.text = "ПОЩЁЧИНА"
	else:
		_phase_label.text = "БЛОК"
	var z_x: float = match_state.target_start * _track_width
	var z_w: float = match_state.target_width * _track_width
	_zone.position = Vector2(z_x, 0.0)
	_zone.size = Vector2(maxf(z_w, 2.0), 36.0)
	var p_x: float = match_state.perfect_start * _track_width
	var p_w: float = (match_state.perfect_end - match_state.perfect_start) * _track_width
	_perfect.position = Vector2(p_x, 0.0)
	_perfect.size = Vector2(maxf(p_w, 2.0), 36.0)
	_pointer.position = Vector2(match_state.pointer_position * _track_width - 2.0, -2.0)
	_special_label.text = _special_text()
	_feedback_label.text = _feedback_text(match_state.last_feedback)


func _update_track_width() -> void:
	var next_w: float = MinigameShell.responsive_track_width(get_viewport(), TRACK_DESIGNED)
	if is_equal_approx(next_w, _track_width):
		return
	_track_width = next_w
	if _track_wrap != null:
		_track_wrap.custom_minimum_size = Vector2(_track_width, 36.0)


func _special_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if match_state.perk_double_slap:
		if match_state.used_double_slap and not match_state.double_armed:
			parts.append("Q — Двойная пощёчина (Использовано)")
		elif match_state.double_armed:
			parts.append("Q — Двойная пощёчина (ЗАРЯД)")
		else:
			parts.append("Q — Двойная пощёчина")
	if match_state.perk_two_handed:
		if match_state.used_two_handed and not match_state.two_handed_armed:
			parts.append("R — Двуручный довод (Использовано)")
		elif match_state.two_handed_armed:
			parts.append("R — Двуручный довод (ЗАРЯД)")
		else:
			parts.append("R — Двуручный довод")
	if match_state.counter_armed:
		parts.append("Ответный аргумент готов")
	if parts.is_empty():
		return ""
	return "  |  ".join(parts)


func _feedback_text(fb: SlapMatch.Feedback) -> String:
	match fb:
		SlapMatch.Feedback.MISS:
			return "МИМО"
		SlapMatch.Feedback.HIT:
			return "ПОПАЛ"
		SlapMatch.Feedback.PERFECT:
			return "ИДЕАЛЬНО"
		SlapMatch.Feedback.BLOCK:
			return "БЛОК"
		SlapMatch.Feedback.PERFECT_BLOCK:
			return "ИДЕАЛЬНЫЙ БЛОК"
		_:
			return ""


func _present_camera_impulse(phase: SlapMatch.Phase, timing: SlapTiming.Result) -> void:
	var cam_fb: CameraFeedback = _resolve_camera_feedback()
	if phase == SlapMatch.Phase.ATTACK:
		match timing:
			SlapTiming.Result.HIT:
				if cam_fb != null:
					cam_fb.impulse_rotation(1.2, 0.10)
				ScreenFlash.play_slap_impact(self, false)
			SlapTiming.Result.PERFECT:
				if cam_fb != null:
					cam_fb.impulse_rotation(1.8, 0.10)
					cam_fb.shake(0.015, 0.10)
				ScreenFlash.play_slap_impact(self, true)
			_:
				pass
		return
	# Defense: only failed block = incoming impact. Miss attack already handled above.
	if timing == SlapTiming.Result.MISS and cam_fb != null:
		cam_fb.impulse_rotation(1.5, 0.10)


func _resolve_camera_feedback() -> CameraFeedback:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var player: Node = tree.get_first_node_in_group("player")
	if player == null:
		return null
	if player.has_method("get_camera_feedback"):
		return player.call("get_camera_feedback") as CameraFeedback
	return null


func _present_feedback_sfx(fb: SlapMatch.Feedback) -> void:
	match fb:
		SlapMatch.Feedback.HIT:
			_audio_play_sfx(AudioIds.SLAP_HIT)
		SlapMatch.Feedback.PERFECT:
			_audio_play_sfx(AudioIds.SLAP_PERFECT)
		SlapMatch.Feedback.BLOCK:
			_audio_play_sfx(AudioIds.SLAP_BLOCK)
		SlapMatch.Feedback.PERFECT_BLOCK:
			_audio_play_sfx(AudioIds.SLAP_PERFECT_BLOCK)
		SlapMatch.Feedback.MISS:
			_audio_play_sfx(AudioIds.SLAP_MISS)
		_:
			pass


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
