class_name CareerProgressionUnlockedRequirement
extends ActionRequirement


func is_met() -> bool:
	return WorkService.is_career_progression_unlocked()


func get_failure_reason() -> String:
	return "Карьерный рост ещё не открыт."
