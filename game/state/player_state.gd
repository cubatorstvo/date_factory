class_name PlayerState
extends RefCounted

var money: int = 0
var rating: int = 0
var muscle: int = 0
var appearance: int = 0
var capital: int = 0
var aura: int = 0
var last_work_day_index: int = -1
var last_overtime_day_index: int = -1
var career_progression_unlocked: bool = false
var career_rank: int = 0


func to_dict() -> Dictionary:
	return {
		"money": money,
		"rating": rating,
		"muscle": muscle,
		"appearance": appearance,
		"capital": capital,
		"aura": aura,
		"last_work_day_index": last_work_day_index,
		"last_overtime_day_index": last_overtime_day_index,
		"career_progression_unlocked": career_progression_unlocked,
		"career_rank": career_rank,
	}


func from_dict(data: Dictionary) -> void:
	money = int(data.get("money", 0))
	rating = int(data.get("rating", 0))
	muscle = int(data.get("muscle", 0))
	appearance = int(data.get("appearance", 0))
	capital = int(data.get("capital", 0))
	aura = int(data.get("aura", 0))
	last_work_day_index = int(data.get("last_work_day_index", -1))
	last_overtime_day_index = int(data.get("last_overtime_day_index", -1))
	career_progression_unlocked = bool(data.get("career_progression_unlocked", false))
	career_rank = clampi(int(data.get("career_rank", 0)), 0, 3)
