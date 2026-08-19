class_name RivalCatalog
extends Resource

const ID_BORIS: StringName = &"rival_boris"

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
	var boris: RivalDefinition = _make(ID_BORIS, "Борис", LocationCatalog.ID_CITY_CENTER, [CompetitionCatalog.ID_BASIC])
	catalog.rivals.append(boris)
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	location_id: StringName,
	competition_ids: Array[StringName]
) -> RivalDefinition:
	var rival: RivalDefinition = RivalDefinition.new()
	rival.id = id
	rival.display_name = display_name
	rival.location_id = location_id
	rival.competition_ids = competition_ids.duplicate()
	return rival
