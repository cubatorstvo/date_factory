class_name OutfitCatalog
extends RefCounted

const START_OUTFIT_ID: StringName = &"casual"
const ID_BUSINESS: StringName = &"business"
const ID_LUXURY: StringName = &"luxury"


func get_outfit(outfit_id: StringName) -> Outfit:
	var catalog: DateContentCatalog = _date_catalog()
	if catalog == null:
		return null
	return catalog.find_outfit(outfit_id)


func get_all_outfits() -> Array[Outfit]:
	var result: Array[Outfit] = []
	var catalog: DateContentCatalog = _date_catalog()
	if catalog == null:
		return result
	for outfit in catalog.outfits:
		if outfit != null and outfit.enabled:
			result.append(outfit)
	return result


func get_purchasable_outfits() -> Array[Outfit]:
	var result: Array[Outfit] = []
	for outfit in get_all_outfits():
		if outfit.price > 0:
			result.append(outfit)
	return result


func get_shop_outfits(story_stage: int) -> Array[Outfit]:
	var result: Array[Outfit] = []
	for outfit in get_purchasable_outfits():
		if outfit.min_story_stage <= story_stage:
			result.append(outfit)
	return result


func _date_catalog() -> DateContentCatalog:
	var dating: Variant = _dating_service()
	if dating == null:
		return null
	var catalog_service: DateCatalogService = dating.get_catalog_service()
	if catalog_service == null:
		return null
	return catalog_service.catalog


func _dating_service() -> Variant:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	var node: Node = tree.root.get_node_or_null("DatingService")
	if not is_instance_valid(node):
		return null
	return node
