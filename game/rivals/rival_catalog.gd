class_name RivalCatalog
extends Resource

const ID_BORIS: StringName = &"rival_boris"
const ID_FOREMAN: StringName = &"rival_foreman"
const ID_COLUMNIST: StringName = &"rival_columnist"
const ID_ACADEMIC: StringName = &"rival_academic"
const ID_MINISTER: StringName = &"rival_minister"
const ID_GLEB: StringName = &"rival_gleb"
const ID_MAX: StringName = &"rival_max"
const ID_DENIS: StringName = &"rival_denis"
const ID_ROMAN: StringName = &"rival_roman"
const ID_LEV: StringName = &"rival_lev"
const ID_TIMUR: StringName = &"rival_timur"

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
	catalog.rivals.append(_make(ID_GLEB, "Глеб — Турник", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_HORIZONTAL_BAR], &"", 1))
	catalog.rivals.append(_make(ID_MAX, "Макс — Фотомодель", LocationCatalog.ID_CAFE, [CompetitionCatalog.ID_PHOTO], &"", 1))
	catalog.rivals.append(_make(ID_BORIS, "Борис — каскадёр", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_CASTING], GirlCatalog.ID_ACTRESS, 1))
	catalog.rivals.append(_make(ID_DENIS, "Денис — Криптоэксперт", LocationCatalog.ID_CAFE, [CompetitionCatalog.ID_CRYPTO], &"", 2))
	catalog.rivals.append(_make(ID_ROMAN, "Роман — Ведущий", LocationCatalog.ID_RESTAURANT, [CompetitionCatalog.ID_TOAST], &"", 2))
	catalog.rivals.append(_make(ID_FOREMAN, "Аркадий — главный прораб", LocationCatalog.ID_RESTAURANT, [CompetitionCatalog.ID_ARMWRESTLING], GirlCatalog.ID_MINE_BOSS, 2))
	catalog.rivals.append(_make(ID_COLUMNIST, "Герман — звёздный колумнист", LocationCatalog.ID_CAFE, [CompetitionCatalog.ID_TASTE_DEBATE], GirlCatalog.ID_MAGAZINE_EDITOR, 3))
	catalog.rivals.append(_make(ID_LEV, "Лев — Уличный атлет", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_STREET_ATHLETE], &"", 3))
	catalog.rivals.append(_make(ID_TIMUR, "Тимур — Магнат", LocationCatalog.ID_RESTAURANT, [CompetitionCatalog.ID_MAGNATE], &"", 3))
	catalog.rivals.append(_make(ID_ACADEMIC, "Академик Павел", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_GRANT], GirlCatalog.ID_SCIENTIST, 4))
	catalog.rivals.append(_make(ID_MINISTER, "Министр Виктор", LocationCatalog.ID_RESTAURANT, [CompetitionCatalog.ID_PROTOCOL_DUEL], GirlCatalog.ID_PRESIDENT, 5))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	location_id: StringName,
	competition_ids: Array[StringName],
	linked_girl_id: StringName = &"",
	minimum_story_stage: int = 1
) -> RivalDefinition:
	var rival: RivalDefinition = RivalDefinition.new()
	rival.id = id
	rival.display_name = display_name
	rival.location_id = location_id
	rival.competition_ids = competition_ids.duplicate()
	rival.linked_girl_id = linked_girl_id
	rival.minimum_story_stage = minimum_story_stage
	return rival
