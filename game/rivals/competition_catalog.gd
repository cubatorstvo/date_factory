class_name CompetitionCatalog
extends Resource

const ID_CASTING: StringName = &"competition_casting"
const ID_ARMWRESTLING: StringName = &"competition_armwrestling"
const ID_TASTE_DEBATE: StringName = &"competition_taste_debate"
const ID_GRANT: StringName = &"competition_grant"
const ID_PROTOCOL_DUEL: StringName = &"competition_protocol_duel"
const ID_HORIZONTAL_BAR: StringName = &"competition_horizontal_bar"
const ID_PHOTO: StringName = &"competition_photo"
const ID_CRYPTO: StringName = &"competition_crypto"
const ID_TOAST: StringName = &"competition_toast"
const ID_STREET_ATHLETE: StringName = &"competition_street_athlete"
const ID_MAGNATE: StringName = &"competition_magnate"
const SEED_ENTRY_FEE: int = 100

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
	catalog.competitions.append(_make(ID_HORIZONTAL_BAR, "Кто дольше провисит на турнике", RivalCatalog.ID_GLEB, 60, 0.5, CharacteristicIds.MUSCLE))
	catalog.competitions.append(_make(ID_PHOTO, "Спонтанный конкурс на лучшее фото", RivalCatalog.ID_MAX, 60, 0.5, CharacteristicIds.APPEARANCE))
	catalog.competitions.append(_make(ID_CASTING, "Кастинг на главную мужскую роль", RivalCatalog.ID_BORIS, 60, 0.5, CharacteristicIds.APPEARANCE))
	catalog.competitions.append(_make(ID_CRYPTO, "Кто убедительнее распорядится чужими деньгами", RivalCatalog.ID_DENIS, 60, 0.5, CharacteristicIds.CAPITAL))
	catalog.competitions.append(_make(ID_TOAST, "Импровизированный тост перед всем рестораном", RivalCatalog.ID_ROMAN, 60, 0.5, CharacteristicIds.AURA))
	catalog.competitions.append(_make(ID_ARMWRESTLING, "Армрестлинг за обедом", RivalCatalog.ID_FOREMAN, 60, 0.5, CharacteristicIds.MUSCLE))
	catalog.competitions.append(_make(ID_TASTE_DEBATE, "Публичный спор о вкусе", RivalCatalog.ID_COLUMNIST, 60, 0.5, CharacteristicIds.AURA))
	catalog.competitions.append(_make(ID_STREET_ATHLETE, "Абсурдный силовой челлендж на площади", RivalCatalog.ID_LEV, 60, 0.5, CharacteristicIds.MUSCLE))
	catalog.competitions.append(_make(ID_MAGNATE, "Кто произведёт более дорогой жест", RivalCatalog.ID_TIMUR, 60, 0.5, CharacteristicIds.CAPITAL))
	catalog.competitions.append(_make(ID_GRANT, "Битва за грант", RivalCatalog.ID_ACADEMIC, 60, 0.5, CharacteristicIds.CAPITAL))
	catalog.competitions.append(_make(ID_PROTOCOL_DUEL, "Протокольная дуэль", RivalCatalog.ID_MINISTER, 60, 0.5, CharacteristicIds.AURA))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	rival_id: StringName,
	time_cost_minutes: int,
	base_win_chance: float,
	primary_characteristic_id: StringName
) -> CompetitionDefinition:
	var competition: CompetitionDefinition = CompetitionDefinition.new()
	competition.id = id
	competition.display_name = display_name
	competition.rival_id = rival_id
	competition.time_cost_minutes = time_cost_minutes
	competition.base_win_chance = clampf(base_win_chance, 0.0, 1.0)
	competition.primary_characteristic_id = primary_characteristic_id
	competition.entry_fee = SEED_ENTRY_FEE
	return competition
