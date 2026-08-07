class_name DanceMatch
extends RefCounted
## Headless Dance match FSM + perk rules (MODULE 07B).


enum Phase {
	OPPONENT_DEMO,
	PRE_ROLL,
	PLAYER_REPEAT,
	OWN_PREVIEW,
	PLAYER_OWN,
	ROUND_FEEDBACK,
	FINISHED,
}


enum Feedback {
	NONE,
	MISS,
	HIT,
	PERFECT,
	SUCCESS,
	FAIL,
}


const BEAT_INTERVAL: float = 0.80
const PRE_ROLL_DURATION: float = 0.60
const OWN_PREVIEW_DURATION: float = 1.20
const FEEDBACK_DURATION: float = 0.40
const RHYTHM_CLUE_LEAD: float = 0.25

var player_score: int = 0
var rival_score: int = 0
var target_score: int = 3
var is_story: bool = false
var difference: int = 0
var base_window: float = 0.18
var allowed_errors: int = 1
var sequence_length: int = 3
var phase: Phase = Phase.OPPONENT_DEMO
var phase_time: float = 0.0
var streak: int = 0
var ended: bool = false
var result: RivalCompetitionResult = null
var submit_count: int = 0
var last_feedback: Feedback = Feedback.NONE
var last_move_result: DanceTiming.Result = DanceTiming.Result.MISS

var opponent_sequence: Array[DanceTiming.DanceMove] = []
var own_sequence: Array[DanceTiming.DanceMove] = []
var active_sequence: Array[DanceTiming.DanceMove] = []
var previous_sequence: Array[DanceTiming.DanceMove] = []
var demo_index: int = 0
var demo_move: DanceTiming.DanceMove = DanceTiming.DanceMove.UP
var beat_index: int = 0
var sequence_errors: int = 0
var sequence_correct: int = 0
var beat_consumed: bool = false
var pending_own_after_feedback: bool = false
var pending_next_round_after_feedback: bool = false
var last_sequence_success: bool = false
var round_index: int = 0

var perk_staged_walk: bool = false
var perk_rhythm_in_body: bool = false
var used_staged_walk: bool = false
var rhythm_clue_available: bool = false
var rhythm_clue_active_for_phase: bool = false
var rhythm_clue_used: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _pre_roll_target_own: bool = false


func setup(
	player_level: int,
	rival_level: int,
	p_is_story: bool,
	perks: Dictionary = {},
	rng_seed: int = -1,
) -> void:
	is_story = p_is_story
	target_score = 5 if is_story else 3
	sequence_length = 4 if is_story else 3
	difference = player_level - rival_level
	base_window = DanceTiming.compute_base_window(difference)
	allowed_errors = DanceTiming.compute_allowed_errors(difference)
	perk_staged_walk = bool(perks.get("staged_walk", false))
	perk_rhythm_in_body = bool(perks.get("rhythm_in_body", false))
	rhythm_clue_available = perk_rhythm_in_body
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	_begin_round()


func get_effective_window() -> float:
	return DanceTiming.compute_effective_window(base_window, streak, perk_rhythm_in_body)


func get_rhythm_adjusted_base() -> float:
	return DanceTiming.apply_rhythm_to_base(base_window, perk_rhythm_in_body)


func is_input_phase() -> bool:
	return phase == Phase.PLAYER_REPEAT or phase == Phase.PLAYER_OWN


func should_show_rhythm_clue() -> bool:
	if not rhythm_clue_active_for_phase or not is_input_phase():
		return false
	if phase != Phase.PLAYER_REPEAT:
		return false
	if beat_index >= active_sequence.size() or beat_consumed:
		return false
	var beat_time: float = float(beat_index) * BEAT_INTERVAL
	return phase_time >= beat_time - RHYTHM_CLUE_LEAD and phase_time < beat_time + get_effective_window()


func get_clue_move() -> DanceTiming.DanceMove:
	if beat_index < active_sequence.size():
		return active_sequence[beat_index]
	return DanceTiming.DanceMove.UP


func build_result_once() -> RivalCompetitionResult:
	if result == null:
		return null
	submit_count += 1
	return result


func tick(delta: float) -> void:
	if ended or delta <= 0.0:
		return
	phase_time += delta
	match phase:
		Phase.OPPONENT_DEMO:
			_tick_demo()
		Phase.PRE_ROLL:
			if phase_time >= PRE_ROLL_DURATION:
				_enter_player_input_after_pre_roll()
		Phase.OWN_PREVIEW:
			if phase_time >= OWN_PREVIEW_DURATION:
				_enter_pre_roll_for_own()
		Phase.PLAYER_REPEAT, Phase.PLAYER_OWN:
			_tick_player_input()
		Phase.ROUND_FEEDBACK:
			if phase_time >= FEEDBACK_DURATION:
				_after_feedback()
		Phase.FINISHED:
			pass


func press_move(direction: DanceTiming.DanceMove) -> bool:
	if ended or not is_input_phase() or beat_consumed:
		return false
	if beat_index >= active_sequence.size():
		return false
	var beat_time: float = float(beat_index) * BEAT_INTERVAL
	var window: float = get_effective_window()
	var eval_result: DanceTiming.Result = DanceTiming.evaluate_move(
		active_sequence[beat_index],
		direction,
		phase_time,
		beat_time,
		window,
	)
	# Too-early press still consumes (spec §30) even when evaluate returns MISS for distance.
	_apply_move_result(eval_result)
	return true


func debug_skip_to_player_repeat() -> void:
	if ended:
		return
	_prepare_player_repeat()


func debug_skip_to_player_own() -> void:
	if ended:
		return
	own_sequence = _generate_sequence(sequence_length)
	active_sequence = own_sequence.duplicate()
	_enter_player_own()


func debug_apply_move_result(eval_result: DanceTiming.Result) -> void:
	if ended or not is_input_phase():
		return
	if beat_index >= active_sequence.size():
		return
	_apply_move_result(eval_result)


func debug_finish_sequence_with_pattern(correct_flags: Array) -> void:
	## correct_flags: Array[bool] length == sequence; false = MISS, true = HIT
	if ended:
		return
	if not is_input_phase():
		if phase == Phase.OPPONENT_DEMO or phase == Phase.PRE_ROLL:
			_prepare_player_repeat()
		elif phase == Phase.OWN_PREVIEW:
			_enter_player_own()
	for flag in correct_flags:
		if ended or not is_input_phase():
			break
		if bool(flag):
			debug_apply_move_result(DanceTiming.Result.HIT)
		else:
			debug_apply_move_result(DanceTiming.Result.MISS)


func _begin_round() -> void:
	if ended:
		return
	round_index += 1
	opponent_sequence = _generate_sequence(sequence_length)
	previous_sequence = opponent_sequence.duplicate()
	active_sequence = opponent_sequence.duplicate()
	demo_index = 0
	demo_move = opponent_sequence[0]
	phase = Phase.OPPONENT_DEMO
	phase_time = 0.0
	last_feedback = Feedback.NONE
	pending_own_after_feedback = false
	pending_next_round_after_feedback = false


func _tick_demo() -> void:
	var next_index: int = int(floor(phase_time / BEAT_INTERVAL))
	if next_index < opponent_sequence.size():
		demo_index = next_index
		demo_move = opponent_sequence[demo_index]
	var demo_end: float = float(opponent_sequence.size()) * BEAT_INTERVAL
	if phase_time >= demo_end:
		_enter_pre_roll_for_repeat()


func _enter_pre_roll_for_repeat() -> void:
	phase = Phase.PRE_ROLL
	phase_time = 0.0
	last_feedback = Feedback.NONE
	pending_own_after_feedback = false
	_pre_roll_target_own = false


func _enter_pre_roll_for_own() -> void:
	phase = Phase.PRE_ROLL
	phase_time = 0.0
	_pre_roll_target_own = true
	last_feedback = Feedback.NONE


func _enter_player_input_after_pre_roll() -> void:
	if _pre_roll_target_own:
		_enter_player_own()
	else:
		_prepare_player_repeat()


func _prepare_player_repeat() -> void:
	active_sequence = opponent_sequence.duplicate()
	phase = Phase.PLAYER_REPEAT
	phase_time = 0.0
	beat_index = 0
	beat_consumed = false
	sequence_errors = 0
	sequence_correct = 0
	streak = 0
	last_feedback = Feedback.NONE
	rhythm_clue_active_for_phase = false
	if (
		rhythm_clue_available
		and not rhythm_clue_used
		and DanceTiming.is_complex_sequence(active_sequence.size())
	):
		rhythm_clue_active_for_phase = true
		rhythm_clue_used = true
		rhythm_clue_available = false


func _enter_own_preview() -> void:
	own_sequence = _generate_sequence(sequence_length)
	previous_sequence = own_sequence.duplicate()
	active_sequence = own_sequence.duplicate()
	phase = Phase.OWN_PREVIEW
	phase_time = 0.0
	last_feedback = Feedback.NONE


func _enter_player_own() -> void:
	active_sequence = own_sequence.duplicate()
	phase = Phase.PLAYER_OWN
	phase_time = 0.0
	beat_index = 0
	beat_consumed = false
	sequence_errors = 0
	sequence_correct = 0
	streak = 0
	last_feedback = Feedback.NONE
	rhythm_clue_active_for_phase = false


func _tick_player_input() -> void:
	if beat_index >= active_sequence.size():
		return
	var beat_time: float = float(beat_index) * BEAT_INTERVAL
	var window: float = get_effective_window()
	if phase_time > beat_time + window:
		_apply_move_result(DanceTiming.Result.MISS)


func _apply_move_result(eval_result: DanceTiming.Result) -> void:
	if ended or not is_input_phase() or beat_index >= active_sequence.size():
		return
	beat_consumed = true
	last_move_result = eval_result
	match eval_result:
		DanceTiming.Result.PERFECT:
			last_feedback = Feedback.PERFECT
			sequence_correct += 1
			streak += 1
		DanceTiming.Result.HIT:
			last_feedback = Feedback.HIT
			sequence_correct += 1
			streak += 1
		DanceTiming.Result.MISS:
			last_feedback = Feedback.MISS
			sequence_errors += 1
			var prev_streak: int = streak
			if perk_staged_walk and not used_staged_walk and prev_streak > 0:
				streak = maxi(1, int(ceil(float(prev_streak) / 2.0)))
				used_staged_walk = true
			else:
				streak = 0
	# Immediate advance so next press maps to next beat (spec §29).
	beat_consumed = false
	beat_index += 1
	if beat_index >= active_sequence.size():
		_finish_sequence()


func _finish_sequence() -> void:
	var success: bool = DanceTiming.is_sequence_success(
		sequence_errors,
		sequence_correct,
		active_sequence.size(),
		allowed_errors,
	)
	last_sequence_success = success
	if phase == Phase.PLAYER_REPEAT:
		if success:
			player_score += 1
			last_feedback = Feedback.SUCCESS
			if _check_match_end():
				return
			pending_own_after_feedback = true
			pending_next_round_after_feedback = false
		else:
			rival_score += 1
			last_feedback = Feedback.FAIL
			if _check_match_end():
				return
			pending_own_after_feedback = false
			pending_next_round_after_feedback = true
	elif phase == Phase.PLAYER_OWN:
		if success:
			player_score += 1
			last_feedback = Feedback.SUCCESS
		else:
			rival_score += 1
			last_feedback = Feedback.FAIL
		if _check_match_end():
			return
		pending_own_after_feedback = false
		pending_next_round_after_feedback = true
	phase = Phase.ROUND_FEEDBACK
	phase_time = 0.0


func _after_feedback() -> void:
	if ended:
		return
	if pending_own_after_feedback:
		pending_own_after_feedback = false
		_enter_own_preview()
		return
	if pending_next_round_after_feedback:
		pending_next_round_after_feedback = false
		_begin_round()
		return
	_begin_round()


func _check_match_end() -> bool:
	if player_score < target_score and rival_score < target_score:
		return false
	ended = true
	phase = Phase.FINISHED
	phase_time = 0.0
	result = RivalCompetitionResult.new()
	if player_score >= target_score:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
		result.victory_grade = DanceTiming.compute_victory_grade(
			target_score, player_score, rival_score
		)
	else:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
		result.victory_grade = DanceTiming.compute_victory_grade(
			target_score, rival_score, player_score
		)
	result.debug_score_summary = "DANCE %d:%d" % [player_score, rival_score]
	return true


func _generate_sequence(length: int) -> Array[DanceTiming.DanceMove]:
	var best: Array[DanceTiming.DanceMove] = []
	for attempt in 5:
		var seq: Array[DanceTiming.DanceMove] = _generate_one(length)
		if attempt == 0:
			best = seq
		if not _sequences_equal(seq, previous_sequence):
			return seq
		best = seq
	return best


func _generate_one(length: int) -> Array[DanceTiming.DanceMove]:
	var seq: Array[DanceTiming.DanceMove] = []
	for i in length:
		var choices: Array[DanceTiming.DanceMove] = [
			DanceTiming.DanceMove.UP,
			DanceTiming.DanceMove.DOWN,
			DanceTiming.DanceMove.LEFT,
			DanceTiming.DanceMove.RIGHT,
		]
		if i >= 2 and seq[i - 1] == seq[i - 2]:
			var banned: DanceTiming.DanceMove = seq[i - 1]
			var filtered: Array[DanceTiming.DanceMove] = []
			for c in choices:
				if c != banned:
					filtered.append(c)
			choices = filtered
		var pick: DanceTiming.DanceMove = choices[rng.randi_range(0, choices.size() - 1)]
		seq.append(pick)
	return seq


func _sequences_equal(a: Array[DanceTiming.DanceMove], b: Array[DanceTiming.DanceMove]) -> bool:
	if a.size() != b.size() or a.is_empty():
		return false
	for i in a.size():
		if a[i] != b[i]:
			return false
	return true
