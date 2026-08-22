class_name WorldState
extends RefCounted

const START_UNLOCKED_DATE_VENUE_IDS: Array[StringName] = [
	&"apartment",
]

var current_location_id: StringName = LocationCatalog.START_LOCATION_ID
var unlocked_location_ids: Array[StringName] = []
var unlocked_date_venue_ids: Array[StringName] = []
var city_stage: int = 1


func _init() -> void:
	apply_start()


func apply_start() -> void:
	current_location_id = LocationCatalog.START_LOCATION_ID
	unlocked_location_ids.clear()
	unlocked_date_venue_ids.clear()
	city_stage = 1
	for location_id in LocationCatalog.START_UNLOCKED_LOCATION_IDS:
		add_unlocked(location_id)
	for date_venue_id in START_UNLOCKED_DATE_VENUE_IDS:
		unlock_date_venue(date_venue_id)


func has_unlocked(location_id: StringName) -> bool:
	return unlocked_location_ids.has(location_id)


func add_unlocked(location_id: StringName) -> bool:
	if location_id == &"" or has_unlocked(location_id):
		return false
	unlocked_location_ids.append(location_id)
	return true


func has_unlocked_date_venue(date_venue_id: StringName) -> bool:
	return unlocked_date_venue_ids.has(date_venue_id)


func unlock_date_venue(date_venue_id: StringName) -> bool:
	if date_venue_id == &"" or has_unlocked_date_venue(date_venue_id):
		return false
	unlocked_date_venue_ids.append(date_venue_id)
	return true


func to_dict() -> Dictionary:
	var ids: Array = []
	for location_id in unlocked_location_ids:
		ids.append(String(location_id))
	var date_venue_ids: Array = []
	for date_venue_id in unlocked_date_venue_ids:
		date_venue_ids.append(String(date_venue_id))
	return {
		"current_location_id": String(current_location_id),
		"unlocked_location_ids": ids,
		"unlocked_date_venue_ids": date_venue_ids,
		"city_stage": city_stage,
	}


func from_dict(data: Dictionary) -> void:
	apply_start()
	var current_raw: Variant = data.get("current_location_id", "")
	var current_text: String = str(current_raw)
	if not current_text.is_empty():
		current_location_id = StringName(current_text)
	var raw: Variant = data.get("unlocked_location_ids", null)
	if raw is Array:
		unlocked_location_ids.clear()
		for item in raw:
			add_unlocked(StringName(str(item)))
	var venues_raw: Variant = data.get("unlocked_date_venue_ids", null)
	if venues_raw is Array:
		unlocked_date_venue_ids.clear()
		for item in venues_raw:
			unlock_date_venue(StringName(str(item)))
	if unlocked_date_venue_ids.is_empty():
		for date_venue_id in START_UNLOCKED_DATE_VENUE_IDS:
			unlock_date_venue(date_venue_id)
	city_stage = clampi(int(data.get("city_stage", 1)), 1, CityProgressionService.MAX_CITY_STAGE)
