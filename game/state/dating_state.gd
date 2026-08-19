class_name DatingState
extends RefCounted

var active_date: Dictionary = {}


func to_dict() -> Dictionary:
	if active_date.is_empty():
		return {
			"active_date": {},
		}
	return {
		"active_date": {
			"girl_id": String(active_date.get("girl_id", "")),
			"started_at_game_time": int(active_date.get("started_at_game_time", 0)),
		},
	}


func from_dict(data: Dictionary) -> void:
	active_date = {}
	var raw: Variant = data.get("active_date", {})
	if not (raw is Dictionary):
		return
	var entry: Dictionary = raw
	var girl_text: String = str(entry.get("girl_id", ""))
	if girl_text.is_empty():
		return
	active_date = {
		"girl_id": StringName(girl_text),
		"started_at_game_time": int(entry.get("started_at_game_time", 0)),
	}
