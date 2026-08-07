class_name SlapMinigame
extends CanvasLayer
## Slap timing overlay UI (MODULE 07A). World stays visible behind.


signal match_finished(result: RivalCompetitionResult)

const FEEDBACK_HOLD: float = 0.2

var match_state: SlapMatch = null
var accept_input: bool = true
var auto_tick: bool = true
var _feedback_timer: float = 0.0
var _finished_emitted: bool = false
var _request: RivalCompetitionRequest = null

var _score_label: Label = null
var _phase_label: Label = null
var _hint_label: Label = null
var _special_label: Label = null
var _feedback_label: Label = null
var _track: ColorRect = null
var _zone: ColorRect = null
var _perfect: ColorRect = null
var _pointer: ColorRect = null
var _track_width: float = 640.0


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_PAUSABLE
	_build_ui()


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
	_try_emit_finished()


func setup_match(state: SlapMatch) -> void:
	match_state = state
	_finished_emitted = false
	_feedback_timer = 0.0
	_refresh_ui()


func _process(delta: float) -> void:
	if match_state == null or match_state.ended:
		_try_emit_finished()
		return
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(0.0, _feedback_timer - delta)
		_refresh_ui()
		return
	if auto_tick:
		var before_feedback: SlapMatch.Feedback = match_state.last_feedback
		var before_ended: bool = match_state.ended
		match_state.tick(delta)
		if match_state.last_feedback != before_feedback and match_state.last_feedback != SlapMatch.Feedback.NONE:
			_feedback_timer = FEEDBACK_HOLD
		if match_state.ended and not before_ended:
			_feedback_timer = FEEDBACK_HOLD
	_refresh_ui()
	_try_emit_finished()


func _unhandled_input(event: InputEvent) -> void:
	if not accept_input or match_state == null or match_state.ended:
		return
	if _feedback_timer > 0.0:
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
		if match_state.press_primary():
			if match_state.last_feedback != before and match_state.last_feedback != SlapMatch.Feedback.NONE:
				_feedback_timer = FEEDBACK_HOLD
			_refresh_ui()
			_try_emit_finished()
		get_viewport().set_input_as_handled()


func _try_emit_finished() -> void:
	if _finished_emitted or match_state == null or not match_state.ended:
		return
	if _feedback_timer > 0.0:
		return
	_finished_emitted = true
	accept_input = false
	var res: RivalCompetitionResult = match_state.build_result_once()
	if res != null:
		match_finished.emit(res)


func _build_ui() -> void:
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	panel.offset_left = -360.0
	panel.offset_right = 360.0
	panel.offset_top = -220.0
	panel.offset_bottom = -24.0
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_score_label)

	_phase_label = Label.new()
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_phase_label)

	var track_wrap: Control = Control.new()
	track_wrap.custom_minimum_size = Vector2(_track_width, 36.0)
	vbox.add_child(track_wrap)

	_track = ColorRect.new()
	_track.color = Color(0.12, 0.12, 0.14, 0.92)
	_track.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	track_wrap.add_child(_track)

	_zone = ColorRect.new()
	_zone.color = Color(0.35, 0.55, 0.85, 0.75)
	_zone.size = Vector2(80, 36)
	track_wrap.add_child(_zone)

	_perfect = ColorRect.new()
	_perfect.color = Color(0.95, 0.85, 0.25, 0.95)
	_perfect.size = Vector2(30, 36)
	track_wrap.add_child(_perfect)

	_pointer = ColorRect.new()
	_pointer.color = Color(1.0, 1.0, 1.0, 1.0)
	_pointer.size = Vector2(4, 40)
	track_wrap.add_child(_pointer)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.text = "SPACE — попасть в область"
	vbox.add_child(_hint_label)

	_special_label = Label.new()
	_special_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_special_label)

	_feedback_label = Label.new()
	_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_feedback_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_feedback_label)


func _refresh_ui() -> void:
	if match_state == null:
		return
	_score_label.text = "Ты %d : %d Соперник   цель %d" % [
		match_state.player_score,
		match_state.rival_score,
		match_state.target_score,
	]
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
	return "  |  ".join(parts)


func _feedback_text(fb: SlapMatch.Feedback) -> String:
	match fb:
		SlapMatch.Feedback.MISS:
			return "MISS"
		SlapMatch.Feedback.HIT:
			return "HIT"
		SlapMatch.Feedback.PERFECT:
			return "PERFECT"
		SlapMatch.Feedback.BLOCK:
			return "BLOCK"
		SlapMatch.Feedback.PERFECT_BLOCK:
			return "PERFECT BLOCK"
		_:
			return ""
