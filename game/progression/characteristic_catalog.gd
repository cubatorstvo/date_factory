class_name CharacteristicCatalog
extends Resource

const ID_MUSCLE_1: StringName = &"upgrade_muscle_1"
const ID_APPEARANCE_1: StringName = &"upgrade_appearance_1"
const ID_CAPITAL_1: StringName = &"upgrade_capital_1"
const ID_AURA_1: StringName = &"upgrade_aura_1"
const SEED_PRICE: int = 300
const SEED_AMOUNT: int = 1
const MAX_LEVEL: int = 5

@export var upgrades: Array[CharacteristicUpgradeDefinition] = []


func get_upgrade(upgrade_id: StringName) -> CharacteristicUpgradeDefinition:
	if upgrade_id == &"":
		return null
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null


func get_upgrade_for_characteristic(characteristic_id: StringName) -> CharacteristicUpgradeDefinition:
	if characteristic_id == &"":
		return null
	for upgrade in upgrades:
		if upgrade != null and upgrade.characteristic_id == characteristic_id:
			return upgrade
	return null


func get_all_upgrades() -> Array[CharacteristicUpgradeDefinition]:
	var result: Array[CharacteristicUpgradeDefinition] = []
	for upgrade in upgrades:
		if upgrade != null:
			result.append(upgrade)
	return result


func get_max_level(_characteristic_id: StringName = &"") -> int:
	return MAX_LEVEL


func get_cost_per_level(_characteristic_id: StringName = &"") -> int:
	return SEED_PRICE


static func create_seed() -> CharacteristicCatalog:
	var catalog := CharacteristicCatalog.new()
	catalog.upgrades.append(_make(ID_MUSCLE_1, "Тренировка", CharacteristicIds.MUSCLE))
	catalog.upgrades.append(_make(ID_APPEARANCE_1, "Уход за внешностью", CharacteristicIds.APPEARANCE))
	catalog.upgrades.append(_make(ID_CAPITAL_1, "Развитие капитала", CharacteristicIds.CAPITAL))
	catalog.upgrades.append(_make(ID_AURA_1, "Развитие ауры", CharacteristicIds.AURA))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	characteristic_id: StringName
) -> CharacteristicUpgradeDefinition:
	var upgrade := CharacteristicUpgradeDefinition.new()
	upgrade.id = id
	upgrade.display_name = display_name
	upgrade.description = display_name
	upgrade.price = SEED_PRICE
	upgrade.characteristic_id = characteristic_id
	upgrade.amount = SEED_AMOUNT
	return upgrade
