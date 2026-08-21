class_name DateScoreBreakdown
extends Resource

@export var opening_scores: Array[int] = []
@export var core_scores: Array[int] = []
@export var closing_scores: Array[int] = []
@export var combo_score: int = 0
@export var girl_trait_score: int = 0
@export var girl_trait_display_name: String = ""
@export var apartment_preparation_score: int = 0
@export var total: int = 0
@export var relationship_gain: int = 0


func recompute() -> void:
	total = 0
	for value in opening_scores:
		total += value
	for value in core_scores:
		total += value
	for value in closing_scores:
		total += value
	total += combo_score
	total += girl_trait_score
	total += apartment_preparation_score
	relationship_gain = maxi(total, 0)


func to_dictionary() -> Dictionary:
	return {
		"opening_scores": opening_scores.duplicate(),
		"core_scores": core_scores.duplicate(),
		"closing_scores": closing_scores.duplicate(),
		"combo_score": combo_score,
		"girl_trait_score": girl_trait_score,
		"girl_trait_display_name": girl_trait_display_name,
		"apartment_preparation_score": apartment_preparation_score,
		"total": total,
		"relationship_gain": relationship_gain,
	}
