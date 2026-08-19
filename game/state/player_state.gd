class_name PlayerState
extends RefCounted

var money: int = 0
var rating: int = 0
var muscle: int = 0
var appearance: int = 0
var capital: int = 0
var aura: int = 0


func to_dict() -> Dictionary:
	return {
		"money": money,
		"rating": rating,
		"muscle": muscle,
		"appearance": appearance,
		"capital": capital,
		"aura": aura,
	}


func from_dict(data: Dictionary) -> void:
	money = int(data.get("money", 0))
	rating = int(data.get("rating", 0))
	muscle = int(data.get("muscle", 0))
	appearance = int(data.get("appearance", 0))
	capital = int(data.get("capital", 0))
	aura = int(data.get("aura", 0))
