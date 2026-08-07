class_name SigmaMatch
extends RefCounted
## Headless Sigma Pressure match FSM + perk rules (MODULE 07C).


enum Phase {
	HOLDING,
	SECTION_FEEDBACK,
	FINISHED,
}


enum Feedback {
	NONE,
	HELD,
	PERFECT,
	BROKE,
}


enum DistState {
	IDLE,
	TELEGRAPH,
	ACTIVE,
	DONE,
}


const SECTION_MAX: float = 5.0
const REQUIRED_HOLD: float = 3.0
const FEEDBACK_DURATION: float = 0.35
const MOUSE_CONTROL: float = 0.0025
const RIVAL_WOBBLE_AMP: float = 0.035
const OBSERVER_WOBBLE_AMP: float = 0.050
const ERROR_PENALTY: float = 0.65
const PERFECT_TIME_THRESHOLD: float = 1.80
const SECTION_GRACE: float = 0.35
const TELEGRAPH_DURATION: float = 0.35
const DISTURBANCE_ACTIVE: float = 0.55
const SURVIVAL_POST: float = 0.75
const MIRROR_DURATION: float = 2.50
const SILENCE_DURATION: float = 2.00
const MIRROR_WIDTH_MULT: float = 1.20
const MIRROR_WIDTH_MAX: float = 0.46
const DISTURBANCE_MULT: float = 1.65
const DIR_LEFT: int = -1
const DIR_RIGHT: int = 1


var player_score: int = 0
var rival_score: int = 0
var target_score: int = 3
var is_story: bool = false
var difference: int = 0
var observers_present: bool = false

var base_normal_half_width: float = 0.30
var pressure_strength: float = 0.32
var pressure_direction: int = DIR_RIGHT

var phase: Phase = Phase.HOLDING
var phase_time: float = 0.0
var section_time: float = 0.0
var hold_progress: float = 0.0
var perfect_time: float = 0.0
var composure: float = 0.0
var total_error_count: int = 0
var was_inside: bool = true
var last_section_perfect: bool = false
var last_feedback: Feedback = Feedback.NONE
var ended: bool = false
var result: RivalCompetitionResult = null
var submit_count: int = 0

var zone_phase: float = 0.0
var observer_phase: float = 0.0
var zone_center: float = 0.0
var effective_half_width: float = 0.30

var disturbance_schedule_time: float = 0.0
var disturbances: Array[Dictionary] = []
var active_disturbance_index: int = -1
var telegraph_direction: int = 0

var survival_tracking: bool = false
var survival_failed: bool = false
var survival_timer: float = 0.0
var reverse_pressure_armed: bool = false

var perk_pocket_mirror: bool = false
var perk_control_profile: bool = false
var perk_dont_blink: bool = false
var perk_silence: bool = false
var perk_reverse_pressure: bool = false
var perk_atmospheric: bool = false

var used_mirror: bool = false
var used_silence: bool = false
var used_dont_blink: bool = false
var mirror_remaining: float = 0.0
var silence_remaining: float = 0.0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var pending_mouse_delta: float = 0.0


static func compute_normal_half_width(diff: int) -> float:
	return clampf(0.30 + float(diff) * 0.015, 0.20, 0.40)


static func compute_pressure_strength(diff: int) -> float:
	return clampf(0.32 - float(diff) * 0.020, 0.18, 0.48)


static func compute_victory_grade(
	target: int,
	winner_score: int,
	loser_score: int,
) -> GameTypes.VictoryGrade:
	return SlapTiming.compute_victory_grade(target, winner_score, loser_score)


func setup(
	player_aura: int,
	rival_aura: int,
	p_is_story: bool,
	perks: Dictionary = {},
	rng_seed: int = -1,
	p_observers_present: bool = false,
) -> void:
	is_story = p_is_story
	target_score = 5 if is_story else 3
	difference = player_aura - rival_aura
	observers_present = p_observers_present
	base_normal_half_width = compute_normal_half_width(difference)
	pressure_strength = compute_pressure_strength(difference)
	perk_pocket_mirror = bool(perks.get("pocket_mirror", false))
	perk_control_profile = bool(perks.get("control_profile", false))
	perk_dont_blink = bool(perks.get("dont_blink", false))
	perk_silence = bool(perks.get("silence_longer", false))
	perk_reverse_pressure = bool(perks.get("reverse_pressure", false))
	perk_atmospheric = bool(perks.get("atmospheric_influence", false))
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	_begin_section()


func is_mirror_active() -> bool:
	return mirror_remaining > 0.0


func is_silence_active() -> bool:
	return silence_remaining > 0.0


func get_perfect_half_width() -> float:
	return effective_half_width * 0.40


func get_observer_wobble() -> float:
	if not observers_present:
		return 0.0
	if perk_atmospheric:
		return 0.0
	return sin(section_time * TAU * 0.80 + observer_phase) * OBSERVER_WOBBLE_AMP


func get_rival_wobble() -> float:
	return sin(section_time * TAU * 0.45 + zone_phase) * RIVAL_WOBBLE_AMP


func can_activate_mirror() -> bool:
	return (
		perk_pocket_mirror
		and not used_mirror
		and not ended
		and phase == Phase.HOLDING
	)


func can_activate_silence() -> bool:
	return (
		perk_silence
		and not used_silence
		and not ended
		and phase == Phase.HOLDING
	)


func activate_mirror() -> bool:
	if not can_activate_mirror():
		return false
	used_mirror = true
	mirror_remaining = MIRROR_DURATION
	return true


func activate_silence() -> bool:
	if not can_activate_silence():
		return false
	used_silence = true
	silence_remaining = SILENCE_DURATION
	return true


func apply_mouse_delta(delta_x: float) -> void:
	if ended or phase != Phase.HOLDING:
		return
	pending_mouse_delta += delta_x


func consume_pending_mouse() -> void:
	if pending_mouse_delta == 0.0:
		return
	composure += pending_mouse_delta * MOUSE_CONTROL
	composure = clampf(composure, -1.0, 1.0)
	pending_mouse_delta = 0.0


func build_result_once() -> RivalCompetitionResult:
	if result == null:
		return null
	submit_count += 1
	return result


func tick(delta: float) -> void:
	if ended or delta <= 0.0:
		return
	_tick_match_timers(delta)
	match phase:
		Phase.HOLDING:
			_tick_holding(delta)
		Phase.SECTION_FEEDBACK:
			phase_time += delta
			if phase_time >= FEEDBACK_DURATION:
				_after_feedback()
		Phase.FINISHED:
			pass


func debug_set_composure(value: float) -> void:
	composure = clampf(value, -1.0, 1.0)


func debug_set_hold_progress(value: float) -> void:
	hold_progress = maxf(value, 0.0)


func debug_force_pressure_strength(value: float) -> void:
	pressure_strength = value


func debug_set_pressure_direction(direction: int) -> void:
	pressure_direction = DIR_LEFT if direction < 0 else DIR_RIGHT


func debug_clear_disturbances() -> void:
	disturbances.clear()
	active_disturbance_index = -1
	telegraph_direction = 0
	survival_tracking = false


func debug_schedule_disturbance(start_time: float, direction: int) -> void:
	var d: Dictionary = {
		"start": start_time,
		"direction": DIR_LEFT if direction < 0 else DIR_RIGHT,
		"state": DistState.IDLE,
		"telegraph_t": 0.0,
		"active_t": 0.0,
	}
	disturbances.append(d)


func debug_win_section(as_perfect: bool = false) -> void:
	if ended or phase != Phase.HOLDING:
		return
	if as_perfect:
		total_error_count = 0
		perfect_time = PERFECT_TIME_THRESHOLD
	_resolve_section(true)


func debug_lose_section() -> void:
	if ended or phase != Phase.HOLDING:
		return
	_resolve_section(false)


func _tick_match_timers(delta: float) -> void:
	if mirror_remaining > 0.0:
		mirror_remaining = maxf(mirror_remaining - delta, 0.0)
	if silence_remaining > 0.0:
		silence_remaining = maxf(silence_remaining - delta, 0.0)


func _begin_section() -> void:
	if ended:
		return
	phase = Phase.HOLDING
	phase_time = 0.0
	section_time = 0.0
	hold_progress = 0.0
	perfect_time = 0.0
	composure = 0.0
	total_error_count = 0
	was_inside = true
	last_section_perfect = false
	last_feedback = Feedback.NONE
	pending_mouse_delta = 0.0
	disturbance_schedule_time = 0.0
	active_disturbance_index = -1
	telegraph_direction = 0
	survival_tracking = false
	survival_failed = false
	survival_timer = 0.0
	zone_phase = rng.randf() * TAU
	observer_phase = rng.randf() * TAU
	pressure_direction = DIR_LEFT if rng.randf() < 0.5 else DIR_RIGHT
	_schedule_disturbances()
	_refresh_zone_geometry()


func _schedule_disturbances() -> void:
	disturbances.clear()
	var count: int = 2 if is_story else 1
	var starts: Array[float] = []
	if count == 1:
		starts.append(rng.randf_range(0.80, 3.80))
	else:
		var first: float = rng.randf_range(0.80, 3.80 - 1.20)
		var second: float = rng.randf_range(first + 1.20, 3.80)
		starts.append(first)
		starts.append(second)
	for t in starts:
		var direction: int = DIR_LEFT if rng.randf() < 0.5 else DIR_RIGHT
		disturbances.append({
			"start": t,
			"direction": direction,
			"state": DistState.IDLE,
			"telegraph_t": 0.0,
			"active_t": 0.0,
		})


func _tick_holding(delta: float) -> void:
	consume_pending_mouse()
	_refresh_zone_geometry()
	var pressure: float = _compute_external_pressure()
	composure += pressure * delta
	composure = clampf(composure, -1.0, 1.0)
	_refresh_zone_geometry()
	_update_hold_and_errors(delta)
	_advance_disturbances(delta)
	section_time += delta
	if hold_progress >= REQUIRED_HOLD:
		_resolve_section(true)
		return
	if section_time >= SECTION_MAX:
		_resolve_section(false)


func _compute_external_pressure() -> float:
	var grace_mult: float = 0.5 if section_time < SECTION_GRACE else 1.0
	var pressure: float = float(pressure_direction) * pressure_strength * grace_mult
	if active_disturbance_index >= 0 and active_disturbance_index < disturbances.size():
		var d: Dictionary = disturbances[active_disturbance_index]
		if int(d.get("state", DistState.IDLE)) == DistState.ACTIVE:
			var dist_dir: int = int(d.get("direction", DIR_RIGHT))
			pressure += float(dist_dir) * pressure_strength * DISTURBANCE_MULT
	return pressure


func _refresh_zone_geometry() -> void:
	if is_mirror_active():
		zone_center = 0.0
		effective_half_width = minf(base_normal_half_width * MIRROR_WIDTH_MULT, MIRROR_WIDTH_MAX)
	else:
		zone_center = get_rival_wobble() + get_observer_wobble()
		effective_half_width = base_normal_half_width


func _update_hold_and_errors(delta: float) -> void:
	var half: float = effective_half_width
	var inside: bool = absf(composure - zone_center) <= half
	var perfect_inside: bool = absf(composure - zone_center) <= get_perfect_half_width()
	if was_inside and not inside:
		_on_hold_error()
	if inside:
		hold_progress += delta
		if perfect_inside:
			perfect_time += delta
	was_inside = inside
	if survival_tracking and not survival_failed:
		survival_timer += delta


func _on_hold_error() -> void:
	total_error_count += 1
	if survival_tracking:
		survival_failed = true
	if perk_dont_blink and not used_dont_blink:
		used_dont_blink = true
		return
	hold_progress = maxf(hold_progress - ERROR_PENALTY, 0.0)


func _advance_disturbances(delta: float) -> void:
	# Advance active telegraph/active with real section time (silence does not pause them).
	if active_disturbance_index >= 0 and active_disturbance_index < disturbances.size():
		var cur: Dictionary = disturbances[active_disturbance_index]
		var st: int = int(cur.get("state", DistState.IDLE))
		if st == DistState.TELEGRAPH:
			var tt: float = float(cur.get("telegraph_t", 0.0)) + delta
			cur["telegraph_t"] = tt
			disturbances[active_disturbance_index] = cur
			if tt >= TELEGRAPH_DURATION:
				cur["state"] = DistState.ACTIVE
				cur["active_t"] = 0.0
				disturbances[active_disturbance_index] = cur
				_begin_survival_window()
		elif st == DistState.ACTIVE:
			var at: float = float(cur.get("active_t", 0.0)) + delta
			cur["active_t"] = at
			disturbances[active_disturbance_index] = cur
			if at >= DISTURBANCE_ACTIVE:
				cur["state"] = DistState.DONE
				disturbances[active_disturbance_index] = cur
				telegraph_direction = 0
				active_disturbance_index = -1
				_enter_post_survival()

	# Schedule clock freezes under Silence; new telegraphs do not start.
	if not is_silence_active():
		disturbance_schedule_time += delta
		_try_start_next_disturbance()

	# Post-active survival window uses real time.
	if survival_tracking and active_disturbance_index < 0:
		if survival_timer >= SURVIVAL_POST:
			_finish_survival_window()


func _try_start_next_disturbance() -> void:
	if active_disturbance_index >= 0:
		return
	if section_time < SECTION_GRACE:
		return
	if is_silence_active():
		return
	for i in disturbances.size():
		var d: Dictionary = disturbances[i]
		if int(d.get("state", DistState.IDLE)) != DistState.IDLE:
			continue
		var start_t: float = float(d.get("start", 0.0))
		if disturbance_schedule_time + 0.0001 >= start_t:
			d["state"] = DistState.TELEGRAPH
			d["telegraph_t"] = 0.0
			disturbances[i] = d
			active_disturbance_index = i
			telegraph_direction = int(d.get("direction", DIR_RIGHT))
			return


func _begin_survival_window() -> void:
	if not perk_reverse_pressure:
		return
	survival_tracking = true
	survival_failed = false
	survival_timer = 0.0


func _enter_post_survival() -> void:
	if not survival_tracking:
		return
	# Active ended; post window counts from now via survival_timer reset to 0 for post phase.
	# During ACTIVE we already accumulated time in survival_timer; switch to post-only clock.
	survival_timer = 0.0


func _finish_survival_window() -> void:
	if not survival_tracking:
		return
	survival_tracking = false
	if not survival_failed:
		reverse_pressure_armed = true


func _resolve_section(player_won: bool) -> void:
	var points: int = 0
	var is_perfect: bool = false
	if player_won:
		is_perfect = (
			total_error_count == 0
			and perfect_time + 0.0001 >= PERFECT_TIME_THRESHOLD
		)
		points = 1
		if is_perfect and is_mirror_active() and perk_control_profile:
			points += 1
		if is_perfect and reverse_pressure_armed and perk_reverse_pressure:
			points += 1
			reverse_pressure_armed = false
		player_score += points
		last_feedback = Feedback.PERFECT if is_perfect else Feedback.HELD
	else:
		rival_score += 1
		last_feedback = Feedback.BROKE
	last_section_perfect = is_perfect
	if _check_match_end():
		return
	phase = Phase.SECTION_FEEDBACK
	phase_time = 0.0


func _after_feedback() -> void:
	if ended:
		return
	_begin_section()


func _check_match_end() -> bool:
	if player_score < target_score and rival_score < target_score:
		return false
	ended = true
	phase = Phase.FINISHED
	phase_time = 0.0
	mirror_remaining = 0.0
	silence_remaining = 0.0
	result = RivalCompetitionResult.new()
	if player_score >= target_score:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
		result.victory_grade = compute_victory_grade(target_score, player_score, rival_score)
	else:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
		result.victory_grade = compute_victory_grade(target_score, rival_score, player_score)
	result.debug_score_summary = "SIGMA %d:%d" % [player_score, rival_score]
	return true
