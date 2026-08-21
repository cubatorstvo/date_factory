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
			"venue_id": String(active_date.get("venue_id", "")),
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
	var venue_text: String = str(entry.get("venue_id", entry.get("location_id", "")))
	active_date = {
		"girl_id": StringName(girl_text),
		"venue_id": StringName(venue_text),
		"outfit_id": StringName(outfit_text),
		"started_at_game_time": int(entry.get("started_at_game_time", 0)),
	}