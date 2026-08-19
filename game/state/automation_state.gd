class_name AutomationState
extends RefCounted

var unlocked: bool = false
var initial_clones_granted: bool = false
var total_clones: int = 0
var work_allocation_percent: int = 50
var work_income_fraction: float = 0.0
var dating_progress_fraction: float = 0.0
var completed_auto_dates: int = 0
var purchased_upgrade_ids: Array[StringName] = []


func has(upgrade_id: StringName) -> bool:
	return purchased_upgrade_ids.has(upgrade_id)


func add(upgrade_id: StringName) -> void:
	if upgrade_id == &"" or has(upgrade_id):
		return
	purchased_upgrade_ids.append(upgrade_id)


func dating_allocation_percent() -> int:
	return 100 - work_allocation_percent


func to_dict() -> Dictionary:
	var ids: Array = []
	for upgrade_id in purchased_upgrade_ids:
		ids.append(String(upgrade_id))
	return {
		"unlocked": unlocked,
		"initial_clones_granted": initial_clones_granted,
		"total_clones": total_clones,
		"work_allocation_percent": work_allocation_percent,
		"work_income_fraction": work_income_fraction,
		"dating_progress_fraction": dating_progress_fraction,
		"completed_auto_dates": completed_auto_dates,
		"purchased_upgrade_ids": ids,
	}


func from_dict(data: Dictionary) -> void:
	unlocked = bool(data.get("unlocked", false))
	initial_clones_granted = bool(data.get("initial_clones_granted", false))
	total_clones = maxi(0, int(data.get("total_clones", 0)))
	work_allocation_percent = clampi(int(data.get("work_allocation_percent", 50)), 0, 100)
	work_income_fraction = maxf(0.0, float(data.get("work_income_fraction", 0.0)))
	dating_progress_fraction = maxf(0.0, float(data.get("dating_progress_fraction", 0.0)))
	completed_auto_dates = maxi(0, int(data.get("completed_auto_dates", 0)))
	purchased_upgrade_ids.clear()
	var raw: Variant = data.get("purchased_upgrade_ids", [])
	if not (raw is Array):
		return
	for item in raw:
		add(StringName(str(item)))
