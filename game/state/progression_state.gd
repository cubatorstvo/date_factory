class_name ProgressionState
extends RefCounted

var purchased_ids: Array[StringName] = []
var current_outfit_id: StringName = OutfitCatalog.START_OUTFIT_ID
var apartment: ApartmentState = ApartmentState.new()


func _init() -> void:
	apply_start_equipment()


func apply_start_equipment() -> void:
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
	return OutfitCatalog.owns_in_chain(current_outfit_id, outfit_id)


func add_owned_outfit(outfit_id: StringName) -> void:
	if outfit_id == &"":
		return
	var target_index: int = OutfitCatalog.chain_index(outfit_id)
	if target_index < 0:
		return
	var current_index: int = OutfitCatalog.chain_index(current_outfit_id)
	if current_index < 0 or target_index > current_index:
		current_outfit_id = outfit_id


func to_dict() -> Dictionary:
	var ids: Array = []
	for purchase_id in purchased_ids:
		ids.append(String(purchase_id))
	return {
		"purchased_ids": ids,
		"current_outfit_id": String(current_outfit_id),
		"apartment": apartment.to_dict() if apartment != null else ApartmentState.new().to_dict(),
	}


func from_dict(data: Dictionary) -> void:
	purchased_ids.clear()
	var raw: Variant = data.get("purchased_ids", [])
	if raw is Array:
		for item in raw:
			add(StringName(str(item)))
	apply_start_equipment()
	var current_text: String = str(data.get("current_outfit_id", ""))
	if current_text.is_empty():
		var owned_raw: Variant = data.get("owned_outfit_ids", [])
		var owned_ids: Array = owned_raw if owned_raw is Array else []
		current_outfit_id = OutfitCatalog.current_from_owned(owned_ids)
	else:
		current_outfit_id = StringName(current_text)
	if OutfitCatalog.chain_index(current_outfit_id) < 0:
		current_outfit_id = OutfitCatalog.START_OUTFIT_ID
	if apartment == null:
		apartment = ApartmentState.new()
	var apartment_raw: Variant = data.get("apartment", {})
	if apartment_raw is Dictionary:
		apartment.from_dict(apartment_raw)
