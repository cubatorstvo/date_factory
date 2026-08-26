class_name CareerRankBelowMaxRequirement
extends ActionRequirement


func is_met() -> bool:
	return WorkService.get_career_rank() < WorkService.MAX_CAREER_RANK


func get_failure_reason() -> String:
	return "Карьера уже максимальная."
