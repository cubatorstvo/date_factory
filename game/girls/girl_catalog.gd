class_name GirlCatalog
extends Resource

const ID_ALINA: StringName = &"alina"
const ID_VIKA: StringName = &"vika"

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
	var catalog := GirlCatalog.new()
	catalog.girls.append(_make(ID_ALINA, "Алина", LocationCatalog.ID_CAFE, -5, 5))
	catalog.girls.append(_make(ID_VIKA, "Вика", LocationCatalog.ID_RESTAURANT, -10, 10))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	location_id: StringName,
	relationship_min: int,
	relationship_max: int
) -> GirlDefinition:
	var girl: GirlDefinition = GirlDefinition.new()
	girl.id = id
	girl.display_name = display_name
	girl.location_id = location_id
	girl.relationship_min = relationship_min
	girl.relationship_max = relationship_max
	return girl
