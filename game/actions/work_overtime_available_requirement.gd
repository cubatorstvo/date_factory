class_name WorkOvertimeAvailableRequirement
extends ActionRequirement


func is_met() -> bool:
	return WorkService.is_overtime_available_today()


func get_failure_reason() -> String:
	if not WorkService.has_olya_overtime():
		return "Подработка ещё не открыта."
	if WorkService.is_work_available_today():
		return "Сначала нужно отработать обычную смену."
	return "Подработка на сегодня выполнена"
