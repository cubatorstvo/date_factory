class_name GirlState
extends RefCounted

var discovered: bool = false
var has_contact: bool = false
var relationship: int = 0
var revealed_positive_tag_ids: Array[StringName] = []
var revealed_negative_tag_ids: Array[StringName] = []
var completed_dates: int = 0
var last_date_situation_ids: Array[StringName] = []


func to_dict() -> Dictionary:
	return {
		"discovered": discovered,
		"has_contact": has_contact,
		"relationship": relationship,
		"revealed_positive_tag_ids": _ids_to_strings(revealed_positive_tag_ids),
		"revealed_negative_tag_ids": _ids_to_strings(revealed_negative_tag_ids),
		"completed_dates": completed_dates,
		"last_date_situation_ids": _ids_to_strings(last_date_situation_ids),
	}


func from_dict(data: Dictionary) -> void:
	discovered = bool(data.get("discovered", false))
	has_contact = bool(data.get("has_contact", false))
	relationship = maxi(0, int(data.get("relationship", 0)))
	revealed_positive_tag_ids = _strings_to_ids(data.get("revealed_positive_tag_ids", []))
	revealed_negative_tag_ids = _strings_to_ids(data.get("revealed_negative_tag_ids", []))
	completed_dates = int(data.get("completed_dates", 0))
	last_date_situation_ids = _strings_to_ids(data.get("last_date_situation_ids", []))


func _ids_to_strings(ids: Array[StringName]) -> Array:
	var result: Array = []
	for tag_id in ids:
		result.append(String(tag_id))
	return result


func _strings_to_ids(value: Variant) -> Array[StringName]:
	var ids: Array[StringName] = []
	if not (value is Array):
		return ids
	for item in value:
		var tag_id: StringName = StringName(str(item))
		if tag_id != &"" and not ids.has(tag_id):
			ids.append(tag_id)
	return ids
