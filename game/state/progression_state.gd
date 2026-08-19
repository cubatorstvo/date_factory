class_name ProgressionState
extends RefCounted

var purchased_ids: Array[StringName] = []
var owned_outfit_ids: Array[StringName] = []
var equipped_outfit_id: StringName = OutfitCatalog.START_OUTFIT_ID
var apartment: ApartmentState = ApartmentState.new()


func _init() -> void:
	apply_start_equipment()


func apply_start_equipment() -> void:
	owned_outfit_ids.clear()
	add_owned_outfit(OutfitCatalog.START_OUTFIT_ID)
	equipped_outfit_id = OutfitCatalog.START_OUTFIT_ID
	if apartment == null:
		apartment = ApartmentState.new()


func has(id: StringName) -> bool:
	return purchased_ids.has(id)


func add(id: StringName) -> void:
	if id == &"" or has(id):
		return
	purchased_ids.append(id)


func owns_outfit(outfit_id: StringName) -> bool:
	return owned_outfit_ids.has(outfit_id)


func add_owned_outfit(outfit_id: StringName) -> void:
	if outfit_id == &"" or owns_outfit(outfit_id):
		return
	owned_outfit_ids.append(outfit_id)


func to_dict() -> Dictionary:
	var ids: Array = []
	for purchase_id in purchased_ids:
		ids.append(String(purchase_id))
	var outfits: Array = []
	for outfit_id in owned_outfit_ids:
		outfits.append(String(outfit_id))
	return {
		"purchased_ids": ids,
		"owned_outfit_ids": outfits,
		"equipped_outfit_id": String(equipped_outfit_id),
		"apartment": apartment.to_dict() if apartment != null else ApartmentState.new().to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	purchased_ids.clear()
	var raw: Variant = data.get("purchased_ids", [])
	if raw is Array:
		for item in raw:
			add(StringName(str(item)))
	apply_start_equipment()
	var owned_raw: Variant = data.get("owned_outfit_ids", null)
	if owned_raw is Array:
		owned_outfit_ids.clear()
		for item in owned_raw:
			add_owned_outfit(StringName(str(item)))
		if owned_outfit_ids.is_empty():
			add_owned_outfit(OutfitCatalog.START_OUTFIT_ID)
	var equipped_text: String = str(data.get("equipped_outfit_id", ""))
	if equipped_text.is_empty():
		equipped_outfit_id = OutfitCatalog.START_OUTFIT_ID
	else:
		equipped_outfit_id = StringName(equipped_text)
	if not owns_outfit(equipped_outfit_id):
		equipped_outfit_id = OutfitCatalog.START_OUTFIT_ID
	if apartment == null:
		apartment = ApartmentState.new()
	var apartment_raw: Variant = data.get("apartment", {})
	if apartment_raw is Dictionary:
		apartment.from_dict(apartment_raw)
