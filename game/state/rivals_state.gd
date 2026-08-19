class_name RivalsState
extends RefCounted

var rivals_by_id: Dictionary = {}


func get_or_create(rival_id: StringName) -> RivalState:
	if rival_id == &"":
		return null
	var existing: Variant = rivals_by_id.get(rival_id, null)
	if existing is RivalState:
		return existing
	var state := RivalState.new()
	rivals_by_id[rival_id] = state
	return state


func to_dict() -> Dictionary:
	var serialized: Dictionary = {}
	for rival_id in rivals_by_id.keys():
		var state: Variant = rivals_by_id[rival_id]
		if state is RivalState:
			serialized[String(rival_id)] = (state as RivalState).to_dict()
	return {
		"rivals_by_id": serialized,
	}


func from_dict(data: Dictionary) -> void:
	rivals_by_id.clear()
	var raw: Variant = data.get("rivals_by_id", {})
	if not (raw is Dictionary):
		return
	var entries: Dictionary = raw
	for key in entries.keys():
		var rival_id: StringName = StringName(str(key))
		var state := RivalState.new()
		var entry: Variant = entries[key]
		if entry is Dictionary:
			state.from_dict(entry)
		rivals_by_id[rival_id] = state
