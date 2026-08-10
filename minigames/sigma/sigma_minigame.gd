class_name SigmaMinigame
extends CanvasLayer
## Sigma Pressure overlay UI + mouse input (MODULE 07C / MODULE 22 presentation).


signal match_finished(result: RivalCompetitionResult)

const TITLE_TEXT: String = "Сигма-давление"
const TRACK_DESIGNED: float = 520.0

var match_state: SigmaMatch = null
var accept_input: bool = true
var auto_tick: bool = true
var _finished_emitted: bool = false
var _result_hold: float = 0.0
var _pending_result: RivalCompetitionResult = null
var _request: RivalCompetitionRequest = null
var _rival_actor: Node3D = null
var _ignore_first_mouse: bool = true

@onready var _root: Control = %Root
@onready var _title_label: Label = %Title
@onready var _score_label: Label = %ScoreLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _hint_label: Label = %HintLabel
@onready var _special_label: Label = %SpecialLabel
@onready var _feedback_label: Label = %FeedbackLabel
@onready var _progress_label: Label = %ProgressLabel
@onready var _pressure_label: Label = %PressureLabel
@onready var _track_wrap: Control = %TrackWrap
@onready var _track: ColorRect = %Track
@onready var _normal_zone: ColorRect = %NormalZone
@onready var _perfect_zone: ColorRect = %PerfectZone
@onready var _indicator: ColorRect = %Indicator
var _track_width: float = TRACK_DESIGNED
var _was_in_zone: bool = false


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
	override_observers: Variant = null,
) -> void:
	_request = request
	_rival_actor = rival_actor
	var effective: Dictionary = perks.duplicate()
	if effective.is_empty():
		effective = _read_perks_from_game_state()
	var observers: bool = is_story
	if override_observers != null:
		observers = bool(override_observers)
	match_state = SigmaMatch.new()
	match_state.setup(
		request.player_level,
		request.rival_level,
		is_story,
		effective,
		rng_seed,
		observers,
	)
	_finished_emitted = false
	_result_hold = 0.0
	_pending_result = null
	_ignore_first_mouse = true
	_present_rival(&"idle")
	_refresh_ui()


func setup_match(state: SigmaMatch) -> void:
	match_state = state
	_finished_emitted = false
	_result_hold = 0.0
	_pending_result = null
	_ignore_first_mouse = true
	_refresh_ui()


func force_finish_emit() -> void:
	_result_hold = 0.0
	_try_emit_finished(true)


func _read_perks_from_game_state() -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	var out: Dictionary = {
		"pocket_mirror": false,
		"control_profile": false,
		"dont_blink": false,
		"silence_longer": false,
		"reverse_pressure": false,
		"atmospheric_influence": false,
	}
	if gs == null:
		return out
	out["pocket_mirror"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_POCKET_MIRROR))
	out["control_profile"] = bool(gs.call("has_perk", PerkIds.APPEARANCE_CONTROL_PROFILE))
	out["dont_blink"] = bool(gs.call("has_perk", PerkIds.AURA_DONT_BLINK_FIRST))
	out["silence_longer"] = bool(gs.call("has_perk", PerkIds.AURA_SILENCE_LONGER))
	out["reverse_pressure"] = bool(gs.call("has_perk", PerkIds.AURA_REVERSE_PRESSURE))
	out["atmospheric_influence"] = bool(gs.call("has_perk", PerkIds.AURA_ATMOSPHERIC_INFLUENCE))
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
	var prev_telegraph: int = match_state.telegraph_direction
	var prev_feedback: SigmaMatch.Feedback = match_state.last_feedback
	if auto_tick:
		match_state.tick(delta)
	var in_zone: bool = absf(match_state.composure - match_state.zone_center) <= match_state.effective_half_width
	if in_zone and not _was_in_zone and match_state.phase == SigmaMatch.Phase.HOLDING:
		_audio_play_sfx(AudioIds.SIGMA_ZONE_ENTER)
	_was_in_zone = in_zone
	if match_state.telegraph_direction != 0 and prev_telegraph == 0:
		_present_rival(&"gesture")
		_audio_play_sfx(AudioIds.SIGMA_DISTURBANCE)
	elif (
		match_state.last_feedback != prev_feedback
		and match_state.phase == SigmaMatch.Phase.SECTION_FEEDBACK
	):
		if (
			match_state.last_feedback == SigmaMatch.Feedback.HELD
			or match_state.last_feedback == SigmaMatch.Feedback.PERFECT
		):
			_present_rival(&"react")
			_audio_play_sfx(AudioIds.SIGMA_SUCCESS)
		else:
			_present_rival(&"gesture")
	_refresh_ui()
	_try_emit_finished(false)


func _unhandled_input(event: InputEvent) -> void:
	if not accept_input or match_state == null or match_state.ended:
		return
	if _result_hold > 0.0:
		return
	if match_state.phase != SigmaMatch.Phase.HOLDING:
		return
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if _ignore_first_mouse:
			_ignore_first_mouse = false
			get_viewport().set_input_as_handled()
			return
		match_state.apply_mouse_delta(motion.relative.x)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed("minigame_special_1"):
		if match_state.activate_mirror():
			_refresh_ui()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("minigame_special_2"):
		if match_state.activate_silence():
			_refresh_ui()
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
	_update_track_width()
	_score_label.text = MinigameShell.format_score(
		match_state.player_score,
		match_state.rival_score,
		match_state.target_score,
	)
	_phase_label.text = _phase_text()
	_progress_label.text = "В зоне: %.1f / %.1f" % [
		match_state.hold_progress,
		SigmaMatch.REQUIRED_HOLD,
	]
	_pressure_label.text = _pressure_text()
	_feedback_label.text = _feedback_text(match_state.last_feedback)
	_special_label.text = _special_text()
	_layout_meter()


func _update_track_width() -> void:
	var next_w: float = MinigameShell.responsive_track_width(get_viewport(), TRACK_DESIGNED)
	if is_equal_approx(next_w, _track_width):
		_track.size = Vector2(_track_width, 40.0)
		return
	_track_width = next_w
	if _track_wrap != null:
		_track_wrap.custom_minimum_size = Vector2(_track_width, 48.0)
	if _track != null:
		_track.size = Vector2(_track_width, 40.0)


func _layout_meter() -> void:
	var center_x: float = _track_width * 0.5
	var half_px: float = match_state.effective_half_width * (_track_width * 0.5)
	var center_px: float = center_x + match_state.zone_center * (_track_width * 0.5)
	_normal_zone.position = Vector2(center_px - half_px, 4.0)
	_normal_zone.size = Vector2(half_px * 2.0, 32.0)
	var perfect_half: float = match_state.get_perfect_half_width() * (_track_width * 0.5)
	_perfect_zone.position = Vector2(center_px - perfect_half, 10.0)
	_perfect_zone.size = Vector2(perfect_half * 2.0, 20.0)
	var ind_x: float = center_x + match_state.composure * (_track_width * 0.5)
	_indicator.position = Vector2(ind_x - 3.0, 0.0)


func _phase_text() -> String:
	if match_state.phase == SigmaMatch.Phase.FINISHED:
		return "ФИНИШ"
	if match_state.phase == SigmaMatch.Phase.SECTION_FEEDBACK:
		match match_state.last_feedback:
			SigmaMatch.Feedback.PERFECT:
				return "НЕ ДРОГНУЛ"
			SigmaMatch.Feedback.HELD:
				return "ВЫДЕРЖАЛ"
			SigmaMatch.Feedback.BROKE:
				return "СОРВАЛСЯ"
			_:
				return ""
	if match_state.telegraph_direction != 0:
		var active: bool = false
		if (
			match_state.active_disturbance_index >= 0
			and match_state.active_disturbance_index < match_state.disturbances.size()
		):
			var d: Dictionary = match_state.disturbances[match_state.active_disturbance_index]
			active = int(d.get("state", 0)) == int(SigmaMatch.DistState.ACTIVE)
		return "ДАВЛЕНИЕ" if active else "ДАВЛЕНИЕ →"
	return "СОХРАНЯЙ ПАРАМЕТР В ЗОНЕ"


func _pressure_text() -> String:
	var arrow: String = "←" if match_state.pressure_direction < 0 else "→"
	var extra: String = ""
	if match_state.telegraph_direction != 0:
		var d_arrow: String = "←" if match_state.telegraph_direction < 0 else "→"
		extra = "   помеха %s" % d_arrow
	if match_state.is_mirror_active():
		extra += "   зеркало"
	if match_state.is_silence_active():
		extra += "   тишина"
	return "Давление %s%s" % [arrow, extra]


func _special_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if match_state.perk_pocket_mirror and not match_state.used_mirror:
		parts.append("Q — Карманное зеркало")
	elif match_state.perk_pocket_mirror and match_state.is_mirror_active():
		parts.append("Q — зеркало активно")
	if match_state.perk_silence and not match_state.used_silence:
		parts.append("R — Молчание длиннее нормы")
	elif match_state.perk_silence and match_state.is_silence_active():
		parts.append("R — тишина активна")
	return "   ".join(parts)


func _feedback_text(fb: SigmaMatch.Feedback) -> String:
	match fb:
		SigmaMatch.Feedback.PERFECT:
			return "НЕ ДРОГНУЛ"
		SigmaMatch.Feedback.HELD:
			return "ВЫДЕРЖАЛ"
		SigmaMatch.Feedback.BROKE:
			return "СОРВАЛСЯ"
		_:
			return ""


func _audio_play_sfx(sound_id: StringName) -> void:
	var ad: Node = get_node_or_null("/root/AudioDirector")
	if ad != null and ad.has_method("play_sfx"):
		ad.call("play_sfx", sound_id)
