class_name WorldState
extends RefCounted

var current_location_id: StringName = LocationCatalog.START_LOCATION_ID
var unlocked_location_ids: Array[StringName] = []


func _init() -> void:
	apply_start()


func apply_start() -> void:
	current_location_id = LocationCatalog.START_LOCATION_ID
	unlocked_location_ids.clear()
	for location_id in LocationCatalog.START_UNLOCKED_LOCATION_IDS:
		add_unlocked(location_id)


func has_unlocked(location_id: StringName) -> bool:
	return unlocked_location_ids.has(location_id)


func add_unlocked(location_id: StringName) -> bool:
	if location_id == &"" or has_unlocked(location_id):
		return false
	unlocked_location_ids.append(location_id)
	return true


func to_dict() -> Dictionary:
	var ids: Array = []
	for location_id in unlocked_location_ids:
		ids.append(String(location_id))
	return {
		"current_location_id": String(current_location_id),
		"unlocked_location_ids": ids,
	}


func from_dict(data: Dictionary) -> void:
	apply_start()
	var current_raw: Variant = data.get("current_location_id", "")
	var current_text: String = str(current_raw)
	if not current_text.is_empty():
		current_location_id = StringName(current_text)
	var raw: Variant = data.get("unlocked_location_ids", null)
	if raw is Array:
		unlocked_location_ids.clear()
		for item in raw:
			add_unlocked(StringName(str(item)))
