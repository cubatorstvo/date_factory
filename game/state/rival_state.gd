class_name RivalState
extends RefCounted

var discovered: bool = false
var defeated: bool = false
var last_challenge_completed_at: int = 0


func to_dict() -> Dictionary:
	return {
		"discovered": discovered,
		"defeated": defeated,
		"last_challenge_completed_at": last_challenge_completed_at,
	}


func from_dict(data: Dictionary) -> void:
	discovered = bool(data.get("discovered", false))
	defeated = bool(data.get("defeated", false))
	last_challenge_completed_at = int(data.get("last_challenge_completed_at", 0))
