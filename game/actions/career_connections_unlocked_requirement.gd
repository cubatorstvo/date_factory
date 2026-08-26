class_name CareerConnectionsUnlockedRequirement
extends ActionRequirement


func is_met() -> bool:
	return WorkService.has_career_connections()


func get_failure_reason() -> String:
	return "Нужны карьерные связи."