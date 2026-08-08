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

var _root: Control = null
var _title_label: Label = null
var _score_label: Label = null
var _phase_label: Label = null
var _hint_label: Label = null
var _sequence_label: Label = null
var _feedback_label: Label = null
var _streak_label: Label = null
var _pulse: ColorRect = null
var _pulse_base: float = 18.0


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()


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
	panel.offset_top = -280.0
	panel.offset_bottom = -24.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_score_label)

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_phase_label)

	var pulse_wrap: CenterContainer = CenterContainer.new()
	pulse_wrap.custom_minimum_size = Vector2(0.0, 40.0)
	vbox.add_child(pulse_wrap)
	_pulse = ColorRect.new()
	_pulse.color = Color(0.95, 0.85, 0.35, 0.9)
	_pulse.custom_minimum_size = Vector2(_pulse_base, _pulse_base)
	pulse_wrap.add_child(_pulse)

	_sequence_label = Label.new()
	_sequence_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sequence_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_sequence_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.text = "W A S D — направления"
	vbox.add_child(_hint_label)

	_streak_label = Label.new()
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_streak_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_streak_label)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_feedback_label)


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
