class_name DateScoreBreakdown
extends Resource

@export var opening_scores: Array[int] = []
@export var core_scores: Array[int] = []
@export var closing_scores: Array[int] = []
@export var secondary_score: int = 0
@export var secondary_success: bool = false
@export var outfit_score: int = 0
@export var apartment_preparation_score: int = 0
@export var total: int = 0


func recompute() -> void:
	total = 0
	for value in opening_scores:
		total += value
	for value in core_scores:
		total += value
	for value in closing_scores:
		total += value
	total += secondary_score
	total += outfit_score
	total += apartment_preparation_score


func to_dictionary() -> Dictionary:
	return {
		"opening_scores": opening_scores.duplicate(),
		"core_scores": core_scores.duplicate(),
		"closing_scores": closing_scores.duplicate(),
		"secondary_score": secondary_score,
		"secondary_success": secondary_success,
		"outfit_score": outfit_score,
		"apartment_preparation_score": apartment_preparation_score,
		"total": total,
	}
