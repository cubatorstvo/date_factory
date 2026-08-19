class_name FlowState
extends RefCounted

const MINUTES_PER_DAY: int = 1440

var game_time_minutes: int = 0


func to_dict() -> Dictionary:
	return {
		"game_time_minutes": game_time_minutes,
	}


func from_dict(data: Dictionary) -> void:
	if data.has("game_time_minutes"):
		game_time_minutes = maxi(0, int(data.get("game_time_minutes", 0)))
		return
	if data.has("day"):
		var old_day: int = int(data.get("day", 1))
		game_time_minutes = maxi(0, old_day - 1) * MINUTES_PER_DAY
		return
	game_time_minutes = 0
