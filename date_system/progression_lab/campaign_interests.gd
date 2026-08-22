class_name CampaignInterests
extends RefCounted

var girl_interest: Dictionary = {}
var rival_interest: Dictionary = {}
var tag_interest: Dictionary = {}
var venue_interest: Dictionary = {}
var characteristic_interest: Dictionary = {}


static func generate(rng: RandomNumberGenerator) -> CampaignInterests:
	var interests := CampaignInterests.new()
	var girls: Variant = _girls_service()
	if girls != null:
		var catalog: GirlCatalog = girls.get_catalog()
		if catalog != null:
			for definition in catalog.get_all_girls():
				if definition != null:
					interests.girl_interest[String(definition.id)] = rng.randf()
	var rivals: Variant = _rivals_service()
	if rivals != null:
		var rival_catalog: RivalCatalog = rivals.get_catalog()
		if rival_catalog != null:
			for rival in rival_catalog.get_all_rivals():
				if rival != null:
					interests.rival_interest[String(rival.id)] = rng.randf()
	var dating: Variant = _dating_service()
	if dating != null:
		var catalog_service: DateCatalogService = dating.get_catalog_service()
		if catalog_service != null and catalog_service.catalog != null:
			var content: DateContentCatalog = catalog_service.catalog
			for tag in content.tags:
				if tag != null:
					interests.tag_interest[String(tag.id)] = rng.randf()
			for venue in content.date_venues:
				if venue != null:
					interests.venue_interest[String(venue.id)] = rng.randf()
	for characteristic_id in CharacteristicIds.all_ids():
		interests.characteristic_interest[String(characteristic_id)] = rng.randf()
	return interests


func value_for(table: Dictionary, id: StringName) -> float:
	var key: String = String(id)
	if table.has(key):
		return float(table[key])
	return 0.5


func to_dict() -> Dictionary:
	return {
		"girl_interest": girl_interest.duplicate(true),
		"rival_interest": rival_interest.duplicate(true),
		"tag_interest": tag_interest.duplicate(true),
		"venue_interest": venue_interest.duplicate(true),
		"characteristic_interest": characteristic_interest.duplicate(true),
	}


static func from_dict(data: Dictionary) -> CampaignInterests:
	var interests := CampaignInterests.new()
	interests.girl_interest = _copy_float_map(data.get("girl_interest", {}))
	interests.rival_interest = _copy_float_map(data.get("rival_interest", {}))
	interests.tag_interest = _copy_float_map(data.get("tag_interest", {}))
	interests.venue_interest = _copy_float_map(data.get("venue_interest", {}))
	interests.characteristic_interest = _copy_float_map(data.get("characteristic_interest", {}))
	return interests


static func _copy_float_map(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (raw is Dictionary):
		return result
	var source: Dictionary = raw
	for key in source.keys():
		result[str(key)] = float(source[key])
	return result


static func _girls_service() -> Variant:
	return _root_node("GirlsService")


static func _rivals_service() -> Variant:
	return _root_node("RivalsService")


static func _dating_service() -> Variant:
	return _root_node("DatingService")


static func _root_node(node_name: String) -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(node_name)
