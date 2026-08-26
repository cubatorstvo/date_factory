class_name IncrementCareerRankEffect
extends ActionEffect


func apply() -> void:
	WorkService._apply_career_rank_increment()


func get_description() -> String:
	return "Карьерный ранг повышен"
