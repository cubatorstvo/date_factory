class_name ApartmentState
extends RefCounted

var level: int = 1
var prepared: bool = true
var purchased_upgrade_ids: Array[StringName] = []
var accent_local_object_id: StringName = &""


func has(upgrade_id: StringName) -> bool:
	return purchased_upgrade_ids.has(upgrade_id)


func add(upgrade_id: StringName) -> void:
	if upgrade_id == &"" or has(upgrade_id):
		return
	purchased_upgrade_ids.append(upgrade_id)


func to_dict() -> Dictionary:
	var ids: Array = []
	for upgrade_id in purchased_upgrade_ids:
		ids.append(String(upgrade_id))
	return {
		"level": level,
		"prepared": prepared,
		"purchased_upgrade_ids": ids,
		"accent_local_object_id": String(accent_local_object_id),
	}


func from_dict(data: Dictionary) -> void:
	level = maxi(1, int(data.get("level", 1)))
	prepared = bool(data.get("prepared", true))
	purchased_upgrade_ids.clear()
	accent_local_object_id = StringName(str(data.get("accent_local_object_id", "")))
	var raw: Variant = data.get("purchased_upgrade_ids", [])
	if not (raw is Array):
		return
	for item in raw:
		add(StringName(str(item)))
