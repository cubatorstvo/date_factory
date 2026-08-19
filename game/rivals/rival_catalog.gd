class_name RivalCatalog
extends Resource

const ID_BORIS: StringName = &"rival_boris"
const ID_FOREMAN: StringName = &"rival_foreman"
const ID_COLUMNIST: StringName = &"rival_columnist"
const ID_ACADEMIC: StringName = &"rival_academic"
const ID_MINISTER: StringName = &"rival_minister"

@export var rivals: Array[RivalDefinition] = []


func get_rival(rival_id: StringName) -> RivalDefinition:
	if rival_id == &"":
		return null
	for rival in rivals:
		if rival != null and rival.id == rival_id:
			return rival
	return null


func get_all_rivals() -> Array[RivalDefinition]:
	var result: Array[RivalDefinition] = []
	for rival in rivals:
		if rival != null:
			result.append(rival)
	return result


func get_rivals_for_location(location_id: StringName) -> Array[RivalDefinition]:
	var result: Array[RivalDefinition] = []
	if location_id == &"":
		return result
	for rival in rivals:
		if rival != null and rival.location_id == location_id:
			result.append(rival)
	return result


static func create_seed() -> RivalCatalog:
	var catalog := RivalCatalog.new()
	catalog.rivals.append(_make(ID_BORIS, "Борис — каскадёр", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_CASTING], GirlCatalog.ID_ACTRESS))
	catalog.rivals.append(_make(ID_FOREMAN, "Аркадий — главный прораб", LocationCatalog.ID_RESTAURANT, [CompetitionCatalog.ID_ARMWRESTLING], GirlCatalog.ID_MINE_BOSS))
	catalog.rivals.append(_make(ID_COLUMNIST, "Герман — звёздный колумнист", LocationCatalog.ID_CAFE, [CompetitionCatalog.ID_TASTE_DEBATE], GirlCatalog.ID_MAGAZINE_EDITOR))
	catalog.rivals.append(_make(ID_ACADEMIC, "Академик Павел", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_GRANT], GirlCatalog.ID_SCIENTIST))
	catalog.rivals.append(_make(ID_MINISTER, "Министр Виктор", LocationCatalog.ID_RESTAURANT, [CompetitionCatalog.ID_PROTOCOL_DUEL], GirlCatalog.ID_PRESIDENT))
	return catalog

static func _make(
	id: StringName,
	display_name: String,
	location_id: StringName,
	competition_ids: Array[StringName],
	linked_girl_id: StringName = &""
) -> RivalDefinition:
	var rival: RivalDefinition = RivalDefinition.new()
	rival.id = id
	rival.display_name = display_name
	rival.location_id = location_id
	rival.competition_ids = competition_ids.duplicate()
	rival.linked_girl_id = linked_girl_id
	return rival