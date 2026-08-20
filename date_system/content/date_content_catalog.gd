class_name DateContentCatalog
extends Resource

@export var tags: Array[DateTag] = []
@export var moves: Array[DateMove] = []
@export var situations: Array[DateSituation] = []
@export var girls: Array[GirlProfile] = []
@export var girl_difficulty_presets: Array[GirlDifficultyPreset] = []
@export var secondary_rules: Array[SecondaryRule] = []
@export var local_objects: Array[DateLocalObject] = []
@export var locations: Array[DateLocation] = []
@export var outfits: Array[Outfit] = []
@export var progression_stats: Array[ProgressionStat] = []
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


func find_secondary(rule_id: StringName) -> SecondaryRule:
	for item in secondary_rules:
		if item != null and item.id == rule_id:
			return item
	return null


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


func find_location(location_id: StringName) -> DateLocation:
	for item in locations:
		if item != null and item.id == location_id:
			return item
	return null


func find_outfit(outfit_id: StringName) -> Outfit:
	for item in outfits:
		if item != null and item.id == outfit_id:
			return item
	return null


func find_stat(stat_id: StringName) -> ProgressionStat:
	for item in progression_stats:
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
		if move.mapping_for(situation_id) != null:
			result.append(move)
	return result


func snapshot() -> DateContentCatalog:
	return duplicate(true) as DateContentCatalog
