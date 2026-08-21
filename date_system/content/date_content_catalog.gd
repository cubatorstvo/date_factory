class_name DateContentCatalog
extends Resource

@export var tags: Array[DateTag] = []
@export var moves: Array[DateMove] = []
@export var situations: Array[DateSituation] = []
@export var girls: Array[GirlProfile] = []
@export var girl_difficulty_presets: Array[GirlDifficultyPreset] = []
@export var local_objects: Array[DateLocalObject] = []
@export var date_venues: Array[DateVenue] = []
@export var outfits: Array[Outfit] = []
@export var traits: Array[GirlTrait] = []
@export var characteristics: Array[CharacteristicDefinition] = []
@export var date_rules: DateRules


func find_tag(tag_id: StringName) -> DateTag:
	for item in tags:
		if item != null and item.id == tag_id:
			return item
	return null


func find_move(move_id: StringName) -> DateMove:
	for item in moves:
		if item != null and item.id == move_id:
			return item
	return null


func find_situation(situation_id: StringName) -> DateSituation:
	for item in situations:
		if item != null and item.id == situation_id:
			return item
	return null


func find_girl(girl_id: StringName) -> GirlProfile:
	for item in girls:
		if item != null and item.id == girl_id:
			return item
	return null


func find_girl_difficulty(preset_id: StringName) -> GirlDifficultyPreset:
	for item in girl_difficulty_presets:
		if item != null and item.id == preset_id:
			return item
	return null


func enabled_girl_difficulty_presets() -> Array[GirlDifficultyPreset]:
	var result: Array[GirlDifficultyPreset] = []
	for item in girl_difficulty_presets:
		if item != null and item.enabled:
			result.append(item)
	result.sort_custom(func(a: GirlDifficultyPreset, b: GirlDifficultyPreset) -> bool:
		return a.sort_order < b.sort_order
	)
	return result


func find_local_object(object_id: StringName) -> DateLocalObject:
	for item in local_objects:
		if item != null and item.id == object_id:
			return item
	return null


func find_local_object_for_move(move_id: StringName) -> DateLocalObject:
	for item in local_objects:
		if item == null:
			continue
		if item.move_ids.has(move_id):
			return item
	return null


func enabled_local_objects() -> Array[DateLocalObject]:
	var result: Array[DateLocalObject] = []
	for item in local_objects:
		if item != null and item.enabled:
			result.append(item)
	return result


func find_venue(venue_id: StringName) -> DateVenue:
	for item in date_venues:
		if item != null and item.id == venue_id:
			return item
	return null


func find_outfit(outfit_id: StringName) -> Outfit:
	for item in outfits:
		if item != null and item.id == outfit_id:
			return item
	return null


func find_trait(trait_id: StringName) -> GirlTrait:
	for item in traits:
		if item != null and item.id == trait_id:
			return item
	return null


func find_characteristic(stat_id: StringName) -> CharacteristicDefinition:
	for item in characteristics:
		if item != null and item.id == stat_id:
			return item
	return null


func enabled_tags() -> Array[DateTag]:
	var result: Array[DateTag] = []
	for item in tags:
		if item != null and item.enabled:
			result.append(item)
	return result


func enabled_moves() -> Array[DateMove]:
	var result: Array[DateMove] = []
	for item in moves:
		if item != null and item.enabled:
			result.append(item)
	return result


func enabled_situations() -> Array[DateSituation]:
	var result: Array[DateSituation] = []
	for item in situations:
		if item != null and item.enabled:
			result.append(item)
	return result


func applicable_moves(situation_id: StringName, kind: DateTypes.DateMoveKind) -> Array[DateMove]:
	var result: Array[DateMove] = []
	for move in enabled_moves():
		if move.kind != kind:
			continue
		if kind == DateTypes.DateMoveKind.LOCAL:
			continue
		if kind == DateTypes.DateMoveKind.CHARACTERISTIC or kind == DateTypes.DateMoveKind.OUTFIT:
			result.append(move)
			continue
		if move.mapping_for(situation_id) != null:
			result.append(move)
	return result


func enabled_moves_of_kind(kind: DateTypes.DateMoveKind) -> Array[DateMove]:
	var result: Array[DateMove] = []
	for move in enabled_moves():
		if move.kind == kind:
			result.append(move)
	return result


func characteristic_moves() -> Array[DateMove]:
	return enabled_moves_of_kind(DateTypes.DateMoveKind.CHARACTERISTIC)



func snapshot() -> DateContentCatalog:
	# Resource.duplicate() on DateContentCatalog strips scripted methods (find_girl).
	# Deep-duplicating nested resources also strips methods (DateSituation.allows_phase).
	var copy := DateContentCatalog.new()
	copy.tags = tags.duplicate()
	copy.moves = moves.duplicate()
	copy.situations = situations.duplicate()
	copy.girls = girls.duplicate()
	copy.girl_difficulty_presets = girl_difficulty_presets.duplicate()
	copy.local_objects = local_objects.duplicate()
	copy.date_venues = date_venues.duplicate()
	copy.outfits = outfits.duplicate()
	copy.traits = traits.duplicate()
	copy.characteristics = characteristics.duplicate()
	copy.date_rules = date_rules
	return copy
