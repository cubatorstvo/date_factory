class_name DailyActivityState
extends RefCounted

var usages: Dictionary = {}


func to_dict() -> Dictionary:
	var packed: Dictionary = {}
	for key in usages.keys():
		var entry: Variant = usages[key]
		if not (entry is Dictionary):
			continue
		packed[str(key)] = {
			"last_used_day_index": int(entry.get("last_used_day_index", -1)),
			"usage_count_on_that_day": int(entry.get("usage_count_on_that_day", 0)),
		}
	return {"usages": packed}


func from_dict(data: Dictionary) -> void:
	usages.clear()
	var packed: Variant = data.get("usages", {})
	if not (packed is Dictionary):
		return
	for key in packed.keys():
		var entry: Variant = packed[key]
		if not (entry is Dictionary):
			continue
		usages[str(key)] = {
			"last_used_day_index": int(entry.get("last_used_day_index", -1)),
			"usage_count_on_that_day": int(entry.get("usage_count_on_that_day", 0)),
		}
