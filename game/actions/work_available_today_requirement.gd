class_name WorkAvailableTodayRequirement
extends ActionRequirement


func is_met() -> bool:
	return WorkService.is_work_available_today()


func get_failure_reason() -> String:
	return "Сегодня уже работали."
