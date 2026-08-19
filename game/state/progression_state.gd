class_name ProgressionState
extends RefCounted

var purchased_ids: Array[StringName] = []


func has(id: StringName) -> bool:
	return purchased_ids.has(id)


func add(id: StringName) -> void:
	if id == &"" or has(id):
		return
	purchased_ids.append(id)


func to_dict() -> Dictionary:
	var ids: Array = []
	for purchase_id in purchased_ids:
		ids.append(String(purchase_id))
	return {
		"purchased_ids": ids,
	}


func from_dict(data: Dictionary) -> void:
	purchased_ids.clear()
	var raw: Variant = data.get("purchased_ids", [])
	if not (raw is Array):
		return
	for item in raw:
		add(StringName(str(item)))
