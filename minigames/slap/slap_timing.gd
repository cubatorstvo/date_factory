class_name SlapTiming
extends RefCounted
## Pure timing evaluator for Slap minigame (MODULE 07A).


enum Result {
	MISS,
	HIT,
	PERFECT,
}


static func evaluate_timing(
	pointer: float,
	target_start: float,
	target_end: float,
	perfect_start: float,
	perfect_end: float,
) -> Result:
	if pointer >= perfect_start and pointer <= perfect_end:
		return Result.PERFECT
	if pointer >= target_start and pointer <= target_end:
		return Result.HIT
	return Result.MISS


static func compute_target_width(difference: int) -> float:
	return clampf(0.20 + float(difference) * 0.0125, 0.12, 0.28)


static func compute_pointer_speed(difference: int) -> float:
	return clampf(0.70 - float(difference) * 0.025, 0.55, 0.95)


static func perfect_fraction_for_streak(streak: int) -> float:
	return 0.30 + float(mini(maxi(streak, 0), 4)) * 0.05


static func compute_victory_grade(
	target_score: int,
	winner_score: int,
	loser_score: int,
) -> GameTypes.VictoryGrade:
	var score_diff: int = winner_score - loser_score
	if target_score <= 3:
		if score_diff == 1:
			return GameTypes.VictoryGrade.CLOSE
		return GameTypes.VictoryGrade.CRUSHING
	if score_diff <= 2:
		return GameTypes.VictoryGrade.CLOSE
	return GameTypes.VictoryGrade.CRUSHING
