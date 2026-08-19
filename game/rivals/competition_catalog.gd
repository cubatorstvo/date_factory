class_name CompetitionCatalog
extends Resource

const ID_BASIC: StringName = &"competition_basic"

@export var competitions: Array[CompetitionDefinition] = []


func get_competition(competition_id: StringName) -> CompetitionDefinition:
	if competition_id == &"":
		return null
	for competition in competitions:
		if competition != null and competition.id == competition_id:
			return competition
	return null


func get_competitions_for_rival(rival_id: StringName) -> Array[CompetitionDefinition]:
	var result: Array[CompetitionDefinition] = []
	if rival_id == &"":
		return result
	for competition in competitions:
		if competition != null and competition.rival_id == rival_id:
			result.append(competition)
	return result


static func create_seed() -> CompetitionCatalog:
	var catalog := CompetitionCatalog.new()
	catalog.competitions.append(_make(ID_BASIC, "Базовый вызов", RivalCatalog.ID_BORIS, 60, 0.5))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	rival_id: StringName,
	time_cost_minutes: int,
	base_win_chance: float
) -> CompetitionDefinition:
	var competition: CompetitionDefinition = CompetitionDefinition.new()
	competition.id = id
	competition.display_name = display_name
	competition.rival_id = rival_id
	competition.time_cost_minutes = time_cost_minutes
	competition.base_win_chance = clampf(base_win_chance, 0.0, 1.0)
	return competition
