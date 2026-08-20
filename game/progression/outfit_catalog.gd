class_name OutfitCatalog
extends RefCounted

const START_OUTFIT_ID: StringName = &"casual"
const ID_BUSINESS: StringName = &"business"
const ID_LUXURY: StringName = &"luxury"
const PRICE_CASUAL: int = 0
const PRICE_BUSINESS: int = 500
const PRICE_LUXURY: int = 800


static func chain_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	ids.append(START_OUTFIT_ID)
	ids.append(ID_BUSINESS)
	ids.append(ID_LUXURY)
	return ids


static func chain_index(outfit_id: StringName) -> int:
	return chain_ids().find(outfit_id)


static func next_outfit_id(current_outfit_id: StringName) -> StringName:
	var ids: Array[StringName] = chain_ids()
	var index: int = ids.find(current_outfit_id)
	if index < 0 or index >= ids.size() - 1:
		return &""
	return ids[index + 1]


static func owns_in_chain(current_outfit_id: StringName, outfit_id: StringName) -> bool:
	var current_index: int = chain_index(current_outfit_id)
	var target_index: int = chain_index(outfit_id)
	if current_index < 0 or target_index < 0:
		return false
	return current_index >= target_index


static func current_from_owned(owned_ids: Array) -> StringName:
	var owned: Dictionary = {}
	for item in owned_ids:
		owned[StringName(str(item))] = true
	if owned.has(ID_LUXURY):
		return ID_LUXURY
	if owned.has(ID_BUSINESS):
		return ID_BUSINESS
	return START_OUTFIT_ID


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
