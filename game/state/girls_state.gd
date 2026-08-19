class_name GirlsState
extends RefCounted

var girls_by_id: Dictionary = {}


func get_or_create(girl_id: StringName) -> GirlState:
	if girl_id == &"":
		return null
	var existing: Variant = girls_by_id.get(girl_id, null)
	if existing is GirlState:
		return existing
	var state := GirlState.new()
	girls_by_id[girl_id] = state
	return state


func to_dict() -> Dictionary:
	var serialized: Dictionary = {}
	for girl_id in girls_by_id.keys():
		var state: Variant = girls_by_id[girl_id]
		if state is GirlState:
			serialized[String(girl_id)] = (state as GirlState).to_dict()
	return {
		"girls_by_id": serialized,
	}


func from_dict(data: Dictionary) -> void:
	girls_by_id.clear()
	var raw: Variant = data.get("girls_by_id", {})
	if not (raw is Dictionary):
		return
	var entries: Dictionary = raw
	for key in entries.keys():
		var girl_id: StringName = StringName(str(key))
		var state := GirlState.new()
		var entry: Variant = entries[key]
		if entry is Dictionary:
			state.from_dict(entry)
		girls_by_id[girl_id] = state
