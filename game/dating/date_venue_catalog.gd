extends RefCounted
class_name DateVenueCatalog
## Static invite venue helpers for date bonuses (D-DATE-BONUS-02/03).
## Not an autoload — call static methods from Relationships / DatingCore.

const APARTMENT_PREP_COST: int = 20
const PREPARED_FLAG: StringName = &"apartment_prepared_for_date"

const INVITE_VENUES: Array[Dictionary] = [
	{"location_id": &"apartment", "label": "Дома", "cost": 0},
	{"location_id": &"cafe", "label": "Кафе", "cost": 30},
	{"location_id": &"restaurant", "label": "Ресторан", "cost": 100},
	{"location_id": &"park", "label": "Парк", "cost": 40},
	{"location_id": &"cinema", "label": "Кинотеатр", "cost": 40},
	{"location_id": &"arcade", "label": "Аркада", "cost": 40},
	{"location_id": &"museum", "label": "Музей", "cost": 40},
	{"location_id": &"planetarium", "label": "Планетарий", "cost": 40},
]

const _LEISURE_BY_LOCATION: Dictionary = {
	&"park": &"calm",
	&"cinema": &"entertainment",
	&"arcade": &"play",
	&"museum": &"culture",
	&"planetarium": &"unusual",
}

const _OUTFIT_BONUS: Dictionary = {
	&"casual": 0,
	&"business": 1,
	&"luxury": 2,
}

const CAFE_COMPAT_LOCATIONS: Array[StringName] = [
	&"apartment",
	&"restaurant",
	&"park",
	&"cinema",
	&"arcade",
	&"museum",
	&"planetarium",
]


static func list_invite_venues() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Dictionary in INVITE_VENUES:
		out.append(row.duplicate(true))
	return out


static func is_invite_venue(location_id: StringName) -> bool:
	for row: Dictionary in INVITE_VENUES:
		if StringName(row.get("location_id", &"")) == location_id:
			return true
	return false


static func quality_bonus(location_id: StringName) -> int:
	match location_id:
		&"cafe":
			return 1
		&"restaurant":
			return 2
		&"apartment":
			return 0
		_:
			if is_thematic(location_id):
				return 1
			return 0


static func leisure_format_for(location_id: StringName) -> StringName:
	if _LEISURE_BY_LOCATION.has(location_id):
		return _LEISURE_BY_LOCATION[location_id] as StringName
	return &""


static func invite_cost(location_id: StringName) -> int:
	for row: Dictionary in INVITE_VENUES:
		if StringName(row.get("location_id", &"")) == location_id:
			return int(row.get("cost", 0))
	return 0


static func is_thematic(location_id: StringName) -> bool:
	return _LEISURE_BY_LOCATION.has(location_id)


static func outfit_bonus(outfit_id: StringName) -> int:
	if _OUTFIT_BONUS.has(outfit_id):
		return int(_OUTFIT_BONUS[outfit_id])
	return 0


static func leisure_preference_bonus(location_id: StringName, leisure_format_ids: Array) -> int:
	var format_id: StringName = leisure_format_for(location_id)
	if format_id == &"":
		return 0
	if leisure_format_ids.has(format_id):
		return 1
	return -1
