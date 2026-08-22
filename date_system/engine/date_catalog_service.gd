class_name DateCatalogService
extends RefCounted

const CATALOG_PATH := "res://date_system/content/catalog/date_content_catalog.tres"

var catalog: DateContentCatalog
var _paths: Dictionary = {}


func load_catalog(path: String = CATALOG_PATH) -> DateContentCatalog:
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	catalog = loaded as DateContentCatalog
	if catalog != null:
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
		"DateLocalObject": "res://date_system/content/local_objects",
		"DateVenue": "res://date_system/content/venues",
		"Outfit": "res://date_system/content/outfits",
		"GirlTrait": "res://date_system/content/traits",
		"CharacteristicDefinition": "res://date_system/content/characteristics",
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
	elif resource is DateLocalObject:
		catalog.local_objects.append(resource)
	elif resource is DateVenue:
		catalog.date_venues.append(resource)
	elif resource is Outfit:
		catalog.outfits.append(resource)
	elif resource is GirlTrait:
		catalog.traits.append(resource)
	elif resource is CharacteristicDefinition:
		catalog.characteristics.append(resource)
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
	elif resource is DateLocalObject:
		catalog.local_objects.erase(resource)
	elif resource is DateVenue:
		catalog.date_venues.erase(resource)
	elif resource is Outfit:
		catalog.outfits.erase(resource)
	elif resource is GirlTrait:
		catalog.traits.erase(resource)
	elif resource is CharacteristicDefinition:
		catalog.characteristics.erase(resource)
	elif resource is GirlDifficultyPreset:
		catalog.girl_difficulty_presets.erase(resource)


func find_dependents(resource_id: StringName, kind: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null:
		return result
	if kind == "DateTag":
		for move in catalog.moves:
			if move.fixed_tag_id == resource_id:
				result.append({"type": "DateMove", "id": String(move.id), "field": "fixed_tag_id"})
		for girl in catalog.girls:
			if girl.positive_tag_ids.has(resource_id):
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "tags"})
	elif kind == "DateSituation":
		for situation in catalog.situations:
			if situation == null or situation.id != resource_id:
				continue
			for move_id in situation.base_move_ids:
				result.append({"type": "DateMove", "id": String(move_id), "field": "base_move_ids"})
	elif kind == "DateMove":
		for situation in catalog.situations:
			if situation != null and situation.base_move_ids.has(resource_id):
				result.append({"type": "DateSituation", "id": String(situation.id), "field": "base_move_ids"})
		for local_object in catalog.local_objects:
			if local_object != null and local_object.move_ids.has(resource_id):
				result.append({"type": "DateLocalObject", "id": String(local_object.id), "field": "move_ids"})
	elif kind == "DateLocalObject":
		for location in catalog.date_venues:
			if location.local_object_ids.has(resource_id):
				result.append({"type": "DateVenue", "id": String(location.id), "field": "local_object_ids"})
	elif kind == "CharacteristicDefinition":
		for move in catalog.moves:
			if move.unlock_requirement != null and move.unlock_requirement.stat_id == resource_id:
				result.append({"type": "DateMove", "id": String(move.id), "field": "unlock_requirement.stat_id"})
	elif kind == "GirlDifficultyPreset":
		for girl in catalog.girls:
			if girl.difficulty_preset_id == resource_id:
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "difficulty_preset_id"})
	elif kind == "GirlTrait":
		for girl in catalog.girls:
			if girl.trait_id == resource_id:
				result.append({"type": "GirlProfile", "id": String(girl.id), "field": "trait_id"})
	return result


func _rebuild_paths() -> void:
	_paths.clear()
	if catalog == null:
		return
	_capture_array(catalog.tags, "DateTag")
	_capture_array(catalog.moves, "DateMove")
	_capture_array(catalog.situations, "DateSituation")
	_capture_array(catalog.girls, "GirlProfile")
	_capture_array(catalog.local_objects, "DateLocalObject")
	_capture_array(catalog.date_venues, "DateVenue")
	_capture_array(catalog.outfits, "Outfit")
	_capture_array(catalog.traits, "GirlTrait")
	_capture_array(catalog.characteristics, "CharacteristicDefinition")
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
