class_name ProgressionState
extends RefCounted

var purchased_ids: Array[StringName] = []
var owned_outfit_ids: Array[StringName] = []
var current_outfit_id: StringName = OutfitCatalog.START_OUTFIT_ID
var apartment: ApartmentState = ApartmentState.new()
var unlocked_filler_reward_ids: Array[StringName] = []
var marina_free_outfit_pending: bool = false


func _init() -> void:
	apply_start_equipment()


func apply_start_equipment() -> void:
	owned_outfit_ids.clear()
	owned_outfit_ids.append(OutfitCatalog.START_OUTFIT_ID)
	current_outfit_id = OutfitCatalog.START_OUTFIT_ID
	if apartment == null:
		apartment = ApartmentState.new()


var equipped_outfit_id: StringName:
	get:
		return current_outfit_id
	set(value):
		current_outfit_id = value


func has(id: StringName) -> bool:
	return purchased_ids.has(id)


func add(id: StringName) -> void:
	if id == &"" or has(id):
		return
	purchased_ids.append(id)


func owns_outfit(outfit_id: StringName) -> bool:
	return owned_outfit_ids.has(outfit_id)


func add_owned_outfit(outfit_id: StringName) -> void:
	if outfit_id == &"":
		return
	if not owned_outfit_ids.has(outfit_id):
		owned_outfit_ids.append(outfit_id)
	current_outfit_id = outfit_id


func has_filler_reward(reward_id: StringName) -> bool:
	return unlocked_filler_reward_ids.has(reward_id)


func add_filler_reward(reward_id: StringName) -> bool:
	if reward_id == &"" or has_filler_reward(reward_id):
		return false
	unlocked_filler_reward_ids.append(reward_id)
	return true


func remove_filler_reward(reward_id: StringName) -> void:
	unlocked_filler_reward_ids.erase(reward_id)


func to_dict() -> Dictionary:
	var ids: Array = []
	for purchase_id in purchased_ids:
		ids.append(String(purchase_id))
	var owned: Array = []
	for outfit_id in owned_outfit_ids:
		owned.append(String(outfit_id))
	return {
		"purchased_ids": ids,
		"owned_outfit_ids": owned,
		"current_outfit_id": String(current_outfit_id),
		"apartment": apartment.to_dict() if apartment != null else ApartmentState.new().to_dict(),
		"unlocked_filler_reward_ids": _ids_to_strings(unlocked_filler_reward_ids),
		"marina_free_outfit_pending": marina_free_outfit_pending,
	}


func from_dict(data: Dictionary) -> void:
	purchased_ids.clear()
	var raw: Variant = data.get("purchased_ids", [])
	if raw is Array:
		for item in raw:
			add(StringName(str(item)))
	apply_start_equipment()
	var owned_raw: Variant = data.get("owned_outfit_ids", [])
	if owned_raw is Array and not owned_raw.is_empty():
		owned_outfit_ids.clear()
		for item in owned_raw:
			var outfit_id: StringName = StringName(str(item))
			if outfit_id != &"" and not owned_outfit_ids.has(outfit_id):
				owned_outfit_ids.append(outfit_id)
	else:
		_migrate_owned_from_chain(StringName(str(data.get("current_outfit_id", ""))))
	if not owned_outfit_ids.has(OutfitCatalog.START_OUTFIT_ID):
		owned_outfit_ids.insert(0, OutfitCatalog.START_OUTFIT_ID)
	var current_text: String = str(data.get("current_outfit_id", ""))
	if current_text.is_empty():
		current_text = str(data.get("equipped_outfit_id", ""))
	if current_text.is_empty():
		current_outfit_id = OutfitCatalog.START_OUTFIT_ID
	else:
		current_outfit_id = StringName(current_text)
	if not owns_outfit(current_outfit_id):
		current_outfit_id = OutfitCatalog.START_OUTFIT_ID
	if apartment == null:
		apartment = ApartmentState.new()
	var apartment_raw: Variant = data.get("apartment", {})
	if apartment_raw is Dictionary:
		apartment.from_dict(apartment_raw)
	unlocked_filler_reward_ids = _strings_to_ids(data.get("unlocked_filler_reward_ids", []))
	marina_free_outfit_pending = bool(data.get("marina_free_outfit_pending", false))



func _ids_to_strings(ids: Array[StringName]) -> Array:
	var result: Array = []
	for item_id in ids:
		result.append(String(item_id))
	return result


func _strings_to_ids(value: Variant) -> Array[StringName]:
	var ids: Array[StringName] = []
	if not (value is Array):
		return ids
	for item in value:
		var item_id: StringName = StringName(str(item))
		if item_id != &"" and not ids.has(item_id):
			ids.append(item_id)
	return ids


func _migrate_owned_from_chain(outfit_id: StringName) -> void:
	owned_outfit_ids.clear()
	owned_outfit_ids.append(OutfitCatalog.START_OUTFIT_ID)
	match outfit_id:
		OutfitCatalog.ID_LUXURY:
			owned_outfit_ids.append(OutfitCatalog.ID_BUSINESS)
			owned_outfit_ids.append(OutfitCatalog.ID_LUXURY)
		OutfitCatalog.ID_BUSINESS:
			owned_outfit_ids.append(OutfitCatalog.ID_BUSINESS)
