class_name ApartmentCatalog
extends Resource

const ID_UPGRADE_1: StringName = &"apartment_upgrade_1"

@export var upgrades: Array[ApartmentUpgradeDefinition] = []


func get_upgrade(upgrade_id: StringName) -> ApartmentUpgradeDefinition:
	if upgrade_id == &"":
		return null
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null


func get_all_upgrades() -> Array[ApartmentUpgradeDefinition]:
	var result: Array[ApartmentUpgradeDefinition] = []
	for upgrade in upgrades:
		if upgrade != null:
			result.append(upgrade)
	return result


static func create_seed() -> ApartmentCatalog:
	var catalog := ApartmentCatalog.new()
	var tv_ids: Array[StringName] = [&"tv"]
	catalog.upgrades.append(_make(ID_UPGRADE_1, "Купить телевизор", 500, 2, tv_ids))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	price: int,
	level_granted: int,
	granted_local_object_ids: Array[StringName] = []
) -> ApartmentUpgradeDefinition:
	var upgrade := ApartmentUpgradeDefinition.new()
	upgrade.id = id
	upgrade.display_name = display_name
	upgrade.description = display_name
	upgrade.price = price
	upgrade.level_granted = level_granted
	upgrade.granted_local_object_ids = granted_local_object_ids
	return upgrade
