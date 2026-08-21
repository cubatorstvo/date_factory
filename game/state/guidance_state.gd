class_name GuidanceState
extends RefCounted

var shown_tutorial_ids: Array[StringName] = []
var shown_milestone_ids: Array[StringName] = []


func has_seen_tutorial(id: StringName) -> bool:
	return shown_tutorial_ids.has(id)


func mark_tutorial_seen(id: StringName) -> void:
	if id == &"" or has_seen_tutorial(id):
		return
	shown_tutorial_ids.append(id)


func has_seen_milestone(id: StringName) -> bool:
	return shown_milestone_ids.has(id)


func mark_milestone_seen(id: StringName) -> void:
	if id == &"" or has_seen_milestone(id):
		return
	shown_milestone_ids.append(id)


func to_dict() -> Dictionary:
	return {
		"shown_tutorial_ids": _ids_to_strings(shown_tutorial_ids),
		"shown_milestone_ids": _ids_to_strings(shown_milestone_ids),
	}


func from_dict(data: Dictionary) -> void:
	shown_tutorial_ids = _strings_to_ids(data.get("shown_tutorial_ids", []))
	shown_milestone_ids = _strings_to_ids(data.get("shown_milestone_ids", []))


func _ids_to_strings(ids: Array[StringName]) -> Array:
	var values: Array = []
	for id in ids:
		values.append(String(id))
	return values


func _strings_to_ids(raw: Variant) -> Array[StringName]:
	var ids: Array[StringName] = []
	if not (raw is Array):
		return ids
	for item in raw:
		var id: StringName = StringName(str(item))
		if id != &"" and not ids.has(id):
			ids.append(id)
	return ids
