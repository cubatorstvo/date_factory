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
			"location_id": String(active_date.get("location_id", "")),
			"outfit_id": String(active_date.get("outfit_id", "")),
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
	var outfit_text: String = str(entry.get("outfit_id", ""))
	if outfit_text.is_empty():
		outfit_text = String(OutfitCatalog.START_OUTFIT_ID)
	active_date = {
		"girl_id": StringName(girl_text),
		"location_id": StringName(str(entry.get("location_id", ""))),
		"outfit_id": StringName(outfit_text),
		"started_at_game_time": int(entry.get("started_at_game_time", 0)),
	}
