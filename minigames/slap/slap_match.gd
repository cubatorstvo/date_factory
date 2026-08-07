class_name SlapMatch
extends RefCounted
## Headless Slap match FSM + perk rules (MODULE 07A).


enum Phase {
	ATTACK,
	DEFENSE,
}


enum Feedback {
	NONE,
	MISS,
	HIT,
	PERFECT,
	BLOCK,
	PERFECT_BLOCK,
}


var player_score: int = 0
var rival_score: int = 0
var target_score: int = 3
var is_story: bool = false
var difference: int = 0
var base_width: float = 0.20
var pointer_speed: float = 0.70
var phase: Phase = Phase.ATTACK
var pointer_position: float = 0.0
var streak: int = 0
var ended: bool = false
var result: RivalCompetitionResult = null
var submit_count: int = 0
var last_feedback: Feedback = Feedback.NONE

var target_center: float = 0.5
var target_width: float = 0.20
var target_start: float = 0.4
var target_end: float = 0.6
var perfect_start: float = 0.45
var perfect_end: float = 0.55
var previous_center: float = -1.0

var perk_no_warmup: bool = false
var perk_tough_cheek: bool = false
var perk_double_slap: bool = false
var perk_counter_argument: bool = false
var perk_mass_reserve: bool = false
var perk_two_handed: bool = false

var used_tough_cheek: bool = false
var used_double_slap: bool = false
var used_mass_reserve: bool = false
var used_two_handed: bool = false
var double_armed: bool = false
var two_handed_armed: bool = false
var counter_armed: bool = false
var defense_penalty_pending: bool = false
var first_attack_zone_pending: bool = true
var primary_consumed: bool = false
var half_resolved: bool = false

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func setup(
	player_level: int,
	rival_level: int,
	p_is_story: bool,
	perks: Dictionary = {},
	rng_seed: int = -1,
) -> void:
	is_story = p_is_story
	target_score = 5 if is_story else 3
	difference = player_level - rival_level
	base_width = SlapTiming.compute_target_width(difference)
	pointer_speed = SlapTiming.compute_pointer_speed(difference)
	perk_no_warmup = bool(perks.get("no_warmup", false))
	perk_tough_cheek = bool(perks.get("tough_cheek", false))
	perk_double_slap = bool(perks.get("double_slap", false))
	perk_counter_argument = bool(perks.get("counter_argument", false))
	perk_mass_reserve = bool(perks.get("mass_reserve", false))
	perk_two_handed = bool(perks.get("two_handed", false)) and is_story
	if rng_seed >= 0:
		rng.seed = rng_seed
	else:
		rng.randomize()
	_start_attack()


func snapshot_perks_from_game_state(gs: Node) -> void:
	if gs == null:
		return
	perk_no_warmup = bool(gs.call("has_perk", PerkIds.MUSCLE_NO_WARMUP))
	perk_tough_cheek = bool(gs.call("has_perk", PerkIds.MUSCLE_TOUGH_CHEEK))
	perk_double_slap = bool(gs.call("has_perk", PerkIds.MUSCLE_DOUBLE_SLAP))
	perk_counter_argument = bool(gs.call("has_perk", PerkIds.MUSCLE_COUNTER_ARGUMENT))
	perk_mass_reserve = bool(gs.call("has_perk", PerkIds.MUSCLE_MASS_RESERVE))
	perk_two_handed = bool(gs.call("has_perk", PerkIds.MUSCLE_TWO_HANDED_ARGUMENT)) and is_story


func can_arm_double() -> bool:
	return (
		not ended
		and phase == Phase.ATTACK
		and perk_double_slap
		and not used_double_slap
		and not primary_consumed
		and not half_resolved
		and not two_handed_armed
	)


func can_arm_two_handed() -> bool:
	return (
		not ended
		and phase == Phase.ATTACK
		and perk_two_handed
		and not used_two_handed
		and not primary_consumed
		and not half_resolved
		and not double_armed
	)


func arm_double_slap() -> bool:
	if not can_arm_double():
		return false
	double_armed = true
	used_double_slap = true
	return true


func arm_two_handed() -> bool:
	if not can_arm_two_handed():
		return false
	two_handed_armed = true
	used_two_handed = true
	return true


func set_pointer(position: float) -> void:
	pointer_position = clampf(position, 0.0, 1.0)


func tick(delta: float) -> void:
	if ended or half_resolved:
		return
	if phase == Phase.ATTACK:
		pointer_position = minf(1.0, pointer_position + pointer_speed * delta)
		if pointer_position >= 1.0:
			_resolve_timeout()
	else:
		pointer_position = maxf(0.0, pointer_position - pointer_speed * delta)
		if pointer_position <= 0.0:
			_resolve_timeout()


func press_primary() -> bool:
	if ended or half_resolved or primary_consumed:
		return false
	primary_consumed = true
	var timing: SlapTiming.Result = SlapTiming.evaluate_timing(
		pointer_position,
		target_start,
		target_end,
		perfect_start,
		perfect_end,
	)
	if phase == Phase.ATTACK:
		_resolve_attack(timing)
	else:
		_resolve_defense(timing)
	return true


func build_result_once() -> RivalCompetitionResult:
	if result == null:
		return null
	submit_count += 1
	return result


func get_perfect_fraction() -> float:
	return SlapTiming.perfect_fraction_for_streak(streak)


func debug_set_zone(center: float, width: float = -1.0) -> void:
	var w: float = target_width if width < 0.0 else width
	var half_w: float = w * 0.5
	target_width = w
	target_center = center
	previous_center = center
	target_start = center - half_w
	target_end = center + half_w
	var p_frac: float = get_perfect_fraction()
	var p_half: float = (w * p_frac) * 0.5
	perfect_start = center - p_half
	perfect_end = center + p_half


func _start_attack() -> void:
	if ended:
		return
	phase = Phase.ATTACK
	pointer_position = 0.0
	primary_consumed = false
	half_resolved = false
	double_armed = false
	two_handed_armed = false
	last_feedback = Feedback.NONE
	var width: float = base_width
	if first_attack_zone_pending and perk_no_warmup:
		width = minf(width * 1.25, 0.34)
	first_attack_zone_pending = false
	_place_zone(width)


func _start_defense() -> void:
	if ended:
		return
	phase = Phase.DEFENSE
	pointer_position = 1.0
	primary_consumed = false
	half_resolved = false
	double_armed = false
	two_handed_armed = false
	last_feedback = Feedback.NONE
	var width: float = base_width
	if defense_penalty_pending:
		width = maxf(width * 0.65, 0.08)
		defense_penalty_pending = false
	_place_zone(width)


func _place_zone(width: float) -> void:
	target_width = width
	var half_w: float = width * 0.5
	var min_c: float = 0.08 + half_w
	var max_c: float = 0.92 - half_w
	if max_c < min_c:
		min_c = 0.5
		max_c = 0.5
	var center: float = rng.randf_range(min_c, max_c)
	var attempts: int = 0
	while previous_center >= 0.0 and absf(center - previous_center) < 0.15 and attempts < 5:
		center = rng.randf_range(min_c, max_c)
		attempts += 1
	previous_center = center
	target_center = center
	target_start = center - half_w
	target_end = center + half_w
	var p_frac: float = get_perfect_fraction()
	var p_half: float = (width * p_frac) * 0.5
	perfect_start = center - p_half
	perfect_end = center + p_half


func _resolve_timeout() -> void:
	if half_resolved or ended:
		return
	primary_consumed = true
	if phase == Phase.ATTACK:
		_resolve_attack(SlapTiming.Result.MISS)
	else:
		_resolve_defense(SlapTiming.Result.MISS)


func _resolve_attack(timing: SlapTiming.Result) -> void:
	if half_resolved or ended:
		return
	half_resolved = true
	if two_handed_armed:
		_resolve_two_handed(timing)
		return
	if timing == SlapTiming.Result.MISS:
		last_feedback = Feedback.MISS
		if (
			perk_mass_reserve
			and not used_mass_reserve
			and not double_armed
		):
			used_mass_reserve = true
			streak = 0
			_start_attack()
			return
		if double_armed:
			defense_penalty_pending = true
		streak = 0
		_start_defense()
		return
	var is_perfect: bool = timing == SlapTiming.Result.PERFECT
	var points: int = 1
	if double_armed:
		if is_perfect:
			points = 2
		else:
			points = 1
			defense_penalty_pending = true
	if counter_armed:
		if is_perfect:
			points += 1
		counter_armed = false
	player_score += points
	streak += 1
	last_feedback = Feedback.PERFECT if is_perfect else Feedback.HIT
	if _check_match_end():
		return
	_start_defense()


func _resolve_two_handed(timing: SlapTiming.Result) -> void:
	var is_perfect: bool = timing == SlapTiming.Result.PERFECT
	if is_perfect:
		var points: int = 2
		if counter_armed:
			points += 1
			counter_armed = false
		player_score += points
		streak += 1
		last_feedback = Feedback.PERFECT
		if _check_match_end():
			return
		_start_defense()
		return
	if counter_armed:
		counter_armed = false
	rival_score += 2
	streak = 0
	last_feedback = Feedback.MISS if timing == SlapTiming.Result.MISS else Feedback.HIT
	if _check_match_end():
		return
	_start_attack()


func _resolve_defense(timing: SlapTiming.Result) -> void:
	if half_resolved or ended:
		return
	half_resolved = true
	if timing == SlapTiming.Result.MISS:
		rival_score += 1
		var prev_streak: int = streak
		if perk_tough_cheek and not used_tough_cheek and prev_streak > 0:
			streak = maxi(1, int(ceil(float(prev_streak) / 2.0)))
			used_tough_cheek = true
		else:
			streak = 0
		last_feedback = Feedback.MISS
		if _check_match_end():
			return
		_start_attack()
		return
	var is_perfect: bool = timing == SlapTiming.Result.PERFECT
	streak += 1
	if is_perfect:
		last_feedback = Feedback.PERFECT_BLOCK
		if perk_counter_argument:
			counter_armed = true
	else:
		last_feedback = Feedback.BLOCK
	if _check_match_end():
		return
	_start_attack()


func _check_match_end() -> bool:
	if player_score < target_score and rival_score < target_score:
		return false
	ended = true
	half_resolved = true
	primary_consumed = true
	result = RivalCompetitionResult.new()
	if player_score >= target_score:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_WIN
		result.victory_grade = SlapTiming.compute_victory_grade(
			target_score, player_score, rival_score
		)
	else:
		result.outcome = GameTypes.RivalCompetitionOutcome.PLAYER_LOSS
		result.victory_grade = SlapTiming.compute_victory_grade(
			target_score, rival_score, player_score
		)
	result.debug_score_summary = "%d:%d" % [player_score, rival_score]
	return true
