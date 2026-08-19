class_name DateCatalogService
extends RefCounted

const CATALOG_PATH := "res://date_system/content/catalog/date_content_catalog.tres"

var catalog: DateContentCatalog
var _paths: Dictionary = {}


func load_catalog(path: String = CATALOG_PATH) -> DateContentCatalog:
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	catalog = loaded as DateContentCatalog
	if catalog != null:
		for girl in catalog.girls:
			if girl != null:
				girl.sync_negative_tags(catalog.enabled_tags())
	_rebuild_paths()
	return catalog


func reload() -> DateContentCatalog:
	return load_catalog(CATALOG_PATH)


func save_resource(resource: Resource, path: String) -> Error:
	var flags: int = ResourceSaver.FLAG_CHANGE_PATH
	var err: Error = ResourceSaver.save(resource, path, flags)
	if err == OK:
		_paths[_resource_key(resource)] = path
	return err


func save_catalog() -> Error:
	if catalog == null:
		return ERR_INVALID_DATA
	return save_resource(catalog, CATALOG_PATH)


func path_for(resource: Resource) -> String:
	return str(_paths.get(_resource_key(resource), ""))


func register_path(resource: Resource, path: String) -> void:
	_paths[_resource_key(resource)] = path


func default_path_for(kind: String, resource_id: String) -> String:
	var folders: Dictionary = {
		"DateTag": "res://date_system/content/tags",
		"DateMove": "res://date_system/content/moves",
		"DateSituation": "res://date_system/content/situations",
		"GirlProfile": "res://date_system/content/girls",
		"SecondaryRule": "res://date_system/content/secondary",
		"LocationFormat": "res://date_system/content/location_formats",
		"DateLocation": "res://date_system/content/locations",
		"Outfit": "res://date_system/content/outfits",
		"ProgressionStat": "res://date_system/content/progression",
		"GirlDifficultyPreset": "res://date_system/content/girl_difficulty",
		"DateRules": "res://date_system/content/rules",
	}
	var folder: String = str(folders.get(kind, "res://date_system/content"))
	return "%s/%s.tres" % [folder, resource_id]


func add_to_catalog(resource: Resource) -> void:
	if catalog == null:
		return
	if resource is DateTag:
		catalog.tags.append(resource)
	elif resource is DateMove:
		catalog.moves.append(resource)
	elif resource is DateSituation:
		catalog.situations.append(resource)
	elif resource is GirlProfile:
		catalog.girls.append(resource)
	elif resource is SecondaryRule:
		catalog.secondary_rules.append(resource)
	elif resource is LocationFormat:
		catalog.location_formats.append(resource)
	elif resource is DateLocation:
		catalog.locations.append(resource)
	elif resource is Outfit:
		catalog.outfits.append(resource)
	elif resource is ProgressionStat:
		catalog.progression_stats.append(resource)
	elif resource is GirlDifficultyPreset:
		catalog.girl_difficulty_presets.append(resource)
	elif resource is DateRules:
		catalog.date_rules = resource


func remove_from_catalog(resource: Resource) -> void:
	if catalog == null:
		return
	if resource is DateTag:
		catalog.tags.erase(resource)
	elif resource is DateMove:
		catalog.moves.erase(resource)
	elif resource is DateSituation:
		catalog.situations.erase(resource)
	elif resource is GirlProfile:
		catalog.girls.erase(resource)
	elif resource is SecondaryRule:
		catalog.secondary_rules.erase(resource)
	elif resource is LocationFormat:
		catalog.location_formats.erase(resource)
	elif resource is DateLocation:
		catalog.locations.erase(resource)
	elif resource is Outfit:
		catalog.outfits.erase(resource)
	elif resource is ProgressionStat:
		catalog.progression_stats.erase(resource)
	elif resource is GirlDifficultyPreset:
		catalog.girl_difficulty_presets.erase(resource)


func find_dependents(resource_id: StringName, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null:
		return result
	if kind == "DateTag":
		for move in catalog.moves:
			for mapping in move.situation_mappings:
				if mapping.tag_id == resource_id:
					result.append({"type": "DateMove", "id": String(move.id), "field": "situation_mappings.tag_id"})
		for girl in catalog.girls:
			if girl.positive_tag_ids.has(resource_id) or girl.negative_tag_ids.has(resource_id):
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "tags"})
	elif kind == "DateSituation":
		for move in catalog.moves:
			for mapping in move.situation_mappings:
				if mapping.situation_id == resource_id:
					result.append({"type": "DateMove", "id": String(move.id), "field": "situation_mappings.situation_id"})
	elif kind == "SecondaryRule":
		for girl in catalog.girls:
			if girl.secondary_rule_id == resource_id:
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "secondary_rule_id"})
	elif kind == "LocationFormat":
		for location in catalog.locations:
			if location.location_format_id == resource_id:
				result.append({"type": "DateLocation", "id": String(location.id), "field": "location_format_id"})
		for girl in catalog.girls:
			if girl.favorite_location_format_ids.has(resource_id):
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "favorite_location_format_ids"})
	elif kind == "ProgressionStat":
		for move in catalog.moves:
			if move.unlock_requirement != null and move.unlock_requirement.stat_id == resource_id:
				result.append({"type": "DateMove", "id": String(move.id), "field": "unlock_requirement.stat_id"})
	elif kind == "GirlDifficultyPreset":
		for girl in catalog.girls:
			if girl.difficulty_preset_id == resource_id:
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "difficulty_preset_id"})
	return result


func _rebuild_paths() -> void:
	_paths.clear()
	if catalog == null:
		return
	_capture_array(catalog.tags, "DateTag")
	_capture_array(catalog.moves, "DateMove")
	_capture_array(catalog.situations, "DateSituation")
	_capture_array(catalog.girls, "GirlProfile")
	_capture_array(catalog.secondary_rules, "SecondaryRule")
	_capture_array(catalog.location_formats, "LocationFormat")
	_capture_array(catalog.locations, "DateLocation")
	_capture_array(catalog.outfits, "Outfit")
	_capture_array(catalog.progression_stats, "ProgressionStat")
	_capture_array(catalog.girl_difficulty_presets, "GirlDifficultyPreset")
	if catalog.date_rules != null:
		var rules_path: String = catalog.date_rules.resource_path
		if rules_path.is_empty():
			rules_path = default_path_for("DateRules", "date_rules")
		register_path(catalog.date_rules, rules_path)


func _capture_array(items: Array, kind: String) -> void:
	for item in items:
		if item == null:
			continue
		var path: String = item.resource_path
		if path.is_empty():
			path = default_path_for(kind, String(item.id))
		register_path(item, path)


func _resource_key(resource: Resource) -> String:
	if resource == null:
		return ""
	if "id" in resource:
		return "%s:%s" % [resource.get_class(), String(resource.id)]
	return str(resource.get_instance_id())
