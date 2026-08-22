class_name GirlCatalog
extends Resource

const ID_ALINA: StringName = &"alina"
const ID_VIKA: StringName = &"vika"
const ID_MARINA: StringName = &"marina"
const ID_DASHA: StringName = &"dasha"
const ID_ACTRESS: StringName = &"girl_actress"
const ID_MINE_BOSS: StringName = &"girl_mine_boss"
const ID_MAGAZINE_EDITOR: StringName = &"girl_magazine_editor"
const ID_SCIENTIST: StringName = &"girl_scientist"
const ID_PRESIDENT: StringName = &"girl_president"
const ID_KATYA: StringName = &"katya"
const ID_LERA: StringName = &"lera"
const ID_OLYA: StringName = &"olya"
const ID_SONYA: StringName = &"sonya"
const ID_NIKA: StringName = &"nika"
const ID_RITA: StringName = &"rita"
const ID_KIRA: StringName = &"kira"
const ID_EVA: StringName = &"eva"
const RELATIONSHIP_MAX_ORDINARY: int = 10
const RELATIONSHIP_MAX_STORY_EARLY: int = 10
const RELATIONSHIP_MAX_STORY_LATE: int = 15
const RELATIONSHIP_MAX_STORY: int = RELATIONSHIP_MAX_STORY_LATE

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


static func is_story_girl_id(girl_id: StringName) -> bool:
	return girl_id == ID_ACTRESS or girl_id == ID_MINE_BOSS or girl_id == ID_MAGAZINE_EDITOR or girl_id == ID_SCIENTIST or girl_id == ID_PRESIDENT


static func seed_relationship_max(girl_id: StringName) -> int:
	if girl_id == ID_SCIENTIST or girl_id == ID_PRESIDENT:
		return RELATIONSHIP_MAX_STORY_LATE
	if girl_id == ID_ACTRESS or girl_id == ID_MINE_BOSS or girl_id == ID_MAGAZINE_EDITOR:
		return RELATIONSHIP_MAX_STORY_EARLY
	return RELATIONSHIP_MAX_ORDINARY


static func create_seed() -> GirlCatalog:
	var catalog: GirlCatalog = GirlCatalog.new()
	catalog.girls.append(_make(ID_ALINA, "Алина", LocationCatalog.ID_CITY_CENTER, 0, 0, seed_relationship_max(ID_ALINA), _min_stage_meet_requirements(1)))
	catalog.girls.append(_make(ID_MARINA, "Марина", LocationCatalog.ID_CLOTHING_STORE, 0, 0, seed_relationship_max(ID_MARINA), _min_stage_meet_requirements(2)))
	catalog.girls.append(_make(ID_VIKA, "Вика", LocationCatalog.ID_CAFE, 0, 0, seed_relationship_max(ID_VIKA), _min_stage_meet_requirements(1)))
	catalog.girls.append(_make(ID_DASHA, "Даша", LocationCatalog.ID_CAFE, 0, 0, seed_relationship_max(ID_DASHA), _min_stage_meet_requirements(1)))
	catalog.girls.append(_make(ID_ACTRESS, "Актриса", LocationCatalog.ID_CITY_CENTER, 0, 0, seed_relationship_max(ID_ACTRESS), _story_girl_meet_requirements(1, 2), _rival_defeated_date_requirements(RivalCatalog.ID_BORIS)))
	catalog.girls.append(_make(ID_KATYA, "Катя", LocationCatalog.ID_FURNITURE_STORE, 0, 0, seed_relationship_max(ID_KATYA), _min_stage_meet_requirements(2), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_LERA, "Лера", LocationCatalog.ID_CAFE, 0, 0, seed_relationship_max(ID_LERA), _min_stage_meet_requirements(2), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_KIRA, "Кира", LocationCatalog.ID_CAFE, 0, 0, seed_relationship_max(ID_KIRA), _min_stage_meet_requirements(3), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_OLYA, "Оля", LocationCatalog.ID_RESTAURANT, 0, 0, seed_relationship_max(ID_OLYA), _min_stage_meet_requirements(3), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_MINE_BOSS, "Начальница шахты", LocationCatalog.ID_RESTAURANT, 0, 0, seed_relationship_max(ID_MINE_BOSS), _story_girl_meet_requirements(2, 5), _outfit_above_casual_date_requirements(_rival_defeated_date_requirements(RivalCatalog.ID_FOREMAN))))
	catalog.girls.append(_make(ID_MAGAZINE_EDITOR, "Редактор журнала", LocationCatalog.ID_CAFE, 0, 0, seed_relationship_max(ID_MAGAZINE_EDITOR), _story_girl_meet_requirements(3, 8), _outfit_above_casual_date_requirements(_rival_defeated_date_requirements(RivalCatalog.ID_COLUMNIST))))
	catalog.girls.append(_make(ID_SONYA, "Соня", LocationCatalog.ID_CITY_CENTER, 0, 0, seed_relationship_max(ID_SONYA), _min_stage_meet_requirements(3), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_NIKA, "Ника", LocationCatalog.ID_CAFE, 0, 0, seed_relationship_max(ID_NIKA), _min_stage_meet_requirements(4), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_RITA, "Рита", LocationCatalog.ID_RESTAURANT, 0, 0, seed_relationship_max(ID_RITA), _min_stage_meet_requirements(4), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_EVA, "Ева", LocationCatalog.ID_RESTAURANT, 0, 0, seed_relationship_max(ID_EVA), _min_stage_meet_requirements(4), _outfit_above_casual_date_requirements()))
	catalog.girls.append(_make(ID_SCIENTIST, "Учёная", LocationCatalog.ID_CITY_CENTER, 0, 0, seed_relationship_max(ID_SCIENTIST), _story_girl_meet_requirements(4, 11), _outfit_above_casual_date_requirements(_rival_defeated_date_requirements(RivalCatalog.ID_ACADEMIC))))
	catalog.girls.append(_make(ID_PRESIDENT, "Президент", LocationCatalog.ID_RESTAURANT, 0, 0, seed_relationship_max(ID_PRESIDENT), _stage_and_rating_meet_requirements(5, 12), _outfit_above_casual_date_requirements(_rival_defeated_date_requirements(RivalCatalog.ID_MINISTER))))
	return catalog


static func _min_stage_meet_requirements(minimum_stage: int) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	var requirement: MinStageGirlRequirement = MinStageGirlRequirement.new()
	requirement.minimum_stage = minimum_stage
	requirements.append(requirement)
	return requirements


static func _city_stage_meet_requirements(minimum_city_stage: int) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	var requirement: MinCityStageGirlRequirement = MinCityStageGirlRequirement.new()
	requirement.minimum_city_stage = minimum_city_stage
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


static func _story_girl_meet_requirements(minimum_stage: int, required_rating: int) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	requirements.append_array(_min_stage_meet_requirements(minimum_stage))
	var filler_requirement: GirlAccessRequirement = (preload("res://game/girls/current_stage_filler_max_girl_requirement.gd") as GDScript).new()
	filler_requirement.set("story_stage", minimum_stage)
	filler_requirement.set("required_count", 2)
	requirements.append(filler_requirement)
	requirements.append_array(_rating_meet_requirements(required_rating))
	return requirements


static func _rival_defeated_date_requirements(rival_id: StringName) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	var requirement: RivalDefeatedGirlRequirement = RivalDefeatedGirlRequirement.new()
	requirement.rival_id = rival_id
	requirements.append(requirement)
	return requirements


static func _outfit_above_casual_date_requirements(base: Array[GirlAccessRequirement] = []) -> Array[GirlAccessRequirement]:
	var requirements: Array[GirlAccessRequirement] = []
	for requirement in base:
		if requirement != null:
			requirements.append(requirement)
	var outfit_requirement: GirlAccessRequirement = (preload("res://game/girls/outfit_above_casual_girl_requirement.gd") as GDScript).new()
	requirements.append(outfit_requirement)
	return requirements


static func _make(
	id: StringName,
	display_name: String,
	location_id: StringName,
	relationship_min: int,
	relationship_start: int,
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
	if "relationship_start" in girl:
		girl.set("relationship_start", relationship_start)
	for requirement in meet_requirements:
		if requirement != null:
			girl.meet_requirements.append(requirement)
	for requirement in date_requirements:
		if requirement != null:
			girl.date_requirements.append(requirement)
	return girl
