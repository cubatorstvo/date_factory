class_name DanceTiming
extends RefCounted
## Pure timing / difficulty helpers for Dance minigame (MODULE 07B).


enum Result {
	MISS,
	HIT,
	PERFECT,
}


enum DanceMove {
	UP,
	DOWN,
	LEFT,
	RIGHT,
}


static func evaluate_move(
	expected_direction: DanceMove,
	actual_direction: DanceMove,
	input_time: float,
	beat_time: float,
	effective_window: float,
) -> Result:
	if expected_direction != actual_direction:
		return Result.MISS
	var dt: float = absf(input_time - beat_time)
	var perfect_window: float = compute_perfect_window(effective_window)
	if dt <= perfect_window:
		return Result.PERFECT
	if dt <= effective_window:
		return Result.HIT
	return Result.MISS


static func compute_base_window(difference: int) -> float:
	return clampf(0.18 + float(difference) * 0.01, 0.11, 0.25)


static func compute_allowed_errors(difference: int) -> int:
	if difference <= -3:
		return 0
	if difference >= 3:
		return 2
	return 1


static func compute_streak_bonus(streak: int) -> float:
	return float(mini(maxi(streak, 0), 4)) * 0.015


static func apply_rhythm_to_base(base_window: float, rhythm_in_body: bool) -> float:
	if rhythm_in_body:
		return base_window * 1.20
	return base_window


static func compute_effective_window(
	base_window: float,
	streak: int,
	rhythm_in_body: bool,
) -> float:
	var adjusted: float = apply_rhythm_to_base(base_window, rhythm_in_body)
	var effective: float = adjusted + compute_streak_bonus(streak)
	return minf(effective, 0.30)


static func compute_perfect_window(effective_window: float) -> float:
	return effective_window * 0.35


static func is_sequence_success(
	errors: int,
	correct_moves: int,
	sequence_length: int,
	allowed_errors: int,
) -> bool:
	if errors > allowed_errors:
		return false
	var minimum_correct: int = int(ceil(float(sequence_length) / 2.0))
	return correct_moves >= minimum_correct


static func is_complex_sequence(sequence_length: int) -> bool:
	return sequence_length >= 4


static func compute_victory_grade(
	target_score: int,
	winner_score: int,
	loser_score: int,
) -> GameTypes.VictoryGrade:
	return SlapTiming.compute_victory_grade(target_score, winner_score, loser_score)


static func move_from_index(index: int) -> DanceMove:
	match index % 4:
		0:
			return DanceMove.UP
		1:
			return DanceMove.DOWN
		2:
			return DanceMove.LEFT
		_:
			return DanceMove.RIGHT
