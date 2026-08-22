class_name ApartmentState
extends RefCounted

var level: int = 1
var prepared: bool = true
var owned_local_object_ids: Array[StringName] = []
var accent_object_id: StringName = &""


func has(object_id: StringName) -> bool:
	return owned_local_object_ids.has(object_id)


func add(object_id: StringName) -> void:
	if object_id == &"" or has(object_id):
		return
	owned_local_object_ids.append(object_id)


func to_dict() -> Dictionary:
	var ids: Array = []
	for object_id in owned_local_object_ids:
		ids.append(String(object_id))
	return {
		"level": level,
		"prepared": prepared,
		"owned_local_object_ids": ids,
		"accent_object_id": String(accent_object_id),
	}


func from_dict(data: Dictionary) -> void:
	level = maxi(1, int(data.get("level", 1)))
	prepared = bool(data.get("prepared", true))
	owned_local_object_ids.clear()
	accent_object_id = StringName(str(data.get("accent_object_id", "")))
	var raw: Variant = data.get("owned_local_object_ids", [])
	if not (raw is Array):
		return
	for item in raw:
		add(StringName(str(item)))
