class_name GirlCatalog
extends Resource

const ID_ALINA: StringName = &"alina"
const ID_VIKA: StringName = &"vika"
const ID_ACTRESS: StringName = &"girl_actress"
const ID_MINE_BOSS: StringName = &"girl_mine_boss"
const ID_MAGAZINE_EDITOR: StringName = &"girl_magazine_editor"
const ID_SCIENTIST: StringName = &"girl_scientist"
const ID_PRESIDENT: StringName = &"girl_president"
const ID_KATYA: StringName = &"katya"
const ID_LERA: StringName = &"lera"
const ID_SONYA: StringName = &"sonya"

@export var girls: Array[GirlDefinition] = []


func get_girl(girl_id: StringName) -> GirlDefinition:
	if girl_id == &"":
		return null
	for girl in girls:
		if girl != null and girl.id == girl_id:
			return girl
	return null


func get_all_girls() -> Array[GirlDefinition]:
	var result: Array[GirlDefinition] = []
	for girl in girls:
		if girl != null:
			result.append(girl)
	return result


func get_girls_for_location(location_id: StringName) -> Array[GirlDefinition]:
	var result: Array[GirlDefinition] = []
	if location_id == &"":
		return result
	for girl in girls:
		if girl != null and girl.location_id == location_id:
			result.append(girl)
	return result


static func create_seed() -> GirlCatalog:
	var catalog: GirlCatalog = GirlCatalog.new()
	catalog.girls.append(_make(ID_ALINA, "Алина", LocationCatalog.ID_CITY_CENTER, -5, 5, _rating_meet_requirements(0)))
	catalog.girls.append(_make(ID_ACTRESS, "Актриса", LocationCatalog.ID_CITY_CENTER, -5, 5, _stage_and_rating_meet_requirements(1, 1), _rival_defeated_date_requirements(RivalCatalog.ID_BORIS)))
	catalog.girls.append(_make(ID_VIKA, "Вика", LocationCatalog.ID_CAFE, -5, 5, _rating_meet_requirements(2)))
	catalog.girls.append(_make(ID_MINE_BOSS, "Начальница шахты", LocationCatalog.ID_RESTAURANT, -5, 5, _stage_and_rating_meet_requirements(2, 3), _rival_defeated_date_requirements(RivalCatalog.ID_FOREMAN)))
	catalog.girls.append(_make(ID_KATYA, "Катя", LocationCatalog.ID_CITY_CENTER, -5, 5, _rating_meet_requirements(4)))
	catalog.girls.append(_make(ID_MAGAZINE_EDITOR, "Редактор журнала", LocationCatalog.ID_CAFE, -5, 5, _stage_and_rating_meet_requirements(3, 5), _rival_defeated_date_requirements(RivalCatalog.ID_COLUMNIST)))
	catalog.girls.append(_make(ID_LERA, "Лера", LocationCatalog.ID_CITY_CENTER, -5, 5, _rating_meet_requirements(6)))
	catalog.girls.append(_make(ID_SCIENTIST, "Учёная", LocationCatalog.ID_CITY_CENTER, -5, 5, _stage_and_rating_meet_requirements(4, 7), _rival_defeated_date_requirements(RivalCatalog.ID_ACADEMIC)))
	catalog.girls.append(_make(ID_SONYA, "Соня", LocationCatalog.ID_CITY_CENTER, -5, 5, _rating_meet_requirements(8)))
	catalog.girls.append(_make(ID_PRESIDENT, "Президент", LocationCatalog.ID_RESTAURANT, -5, 5, _stage_and_rating_meet_requirements(5, 9), _rival_defeated_date_requirements(RivalCatalog.ID_MINISTER)))
	return catalog

static func _min_stage_meet_requirements(minimum_stage: int) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	var requirement: MinStageGirlRequirement = MinStageGirlRequirement.new()
	requirement.minimum_stage = minimum_stage
	requirements.append(requirement)
	return requirements

static func _rating_meet_requirements(required_rating: int) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	var requirement: RatingGirlRequirement = RatingGirlRequirement.new()
	requirement.required_rating = required_rating
	requirements.append(requirement)
	return requirements


static func _stage_and_rating_meet_requirements(minimum_stage: int, required_rating: int) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	requirements.append_array(_min_stage_meet_requirements(minimum_stage))
	requirements.append_array(_rating_meet_requirements(required_rating))
	return requirements


static func _rival_defeated_date_requirements(rival_id: StringName) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	var requirement: RivalDefeatedGirlRequirement = RivalDefeatedGirlRequirement.new()
	requirement.rival_id = rival_id
	requirements.append(requirement)
	return requirements


static func _make(
	id: StringName,
	display_name: String,
	location_id: StringName,
	relationship_min: int,
	relationship_max: int,
	meet_requirements: Array[GirlAccessRequirement] = [],
	date_requirements: Array[GirlAccessRequirement] = []
) -> GirlDefinition:
	var girl: GirlDefinition = GirlDefinition.new()
	girl.id = id
	girl.display_name = display_name
	girl.location_id = location_id
	girl.relationship_min = relationship_min
	girl.relationship_max = relationship_max
	for requirement in meet_requirements:
		if requirement != null:
			girl.meet_requirements.append(requirement)
	for requirement in date_requirements:
		if requirement != null:
			girl.date_requirements.append(requirement)
	return girl