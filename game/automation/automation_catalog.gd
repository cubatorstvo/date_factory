class_name AutomationCatalog
extends Resource

const ID_EXTRA_CLONES: StringName = &"automation_extra_clones"
const ID_WORK_OPTIMIZATION: StringName = &"automation_work_optimization"
const ID_DATING_OPTIMIZATION: StringName = &"automation_dating_optimization"

@export var upgrades: Array[AutomationUpgradeDefinition] = []


func get_upgrade(upgrade_id: StringName) -> AutomationUpgradeDefinition:
	if upgrade_id == &"":
		return null
	for upgrade in upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null


func get_all_upgrades() -> Array[AutomationUpgradeDefinition]:
	var result: Array[AutomationUpgradeDefinition] = []
	for upgrade in upgrades:
		if upgrade != null:
			result.append(upgrade)
	return result


static func create_seed() -> AutomationCatalog:
	var catalog := AutomationCatalog.new()
	catalog.upgrades.append(_make(
		ID_EXTRA_CLONES,
		"Дополнительные клоны",
		"+10 клонов",
		1000,
		10,
		1.0,
		1.0
	))
	catalog.upgrades.append(_make(
		ID_WORK_OPTIMIZATION,
		"Оптимизация труда",
		"Эффективность рабочих клонов ×1.5",
		1500,
		0,
		1.5,
		1.0
	))
	catalog.upgrades.append(_make(
		ID_DATING_OPTIMIZATION,
		"Оптимизация свиданий",
		"Dating production ×1.5",
		1500,
		0,
		1.0,
		1.5
	))
	return catalog


static func _make(
	id: StringName,
	display_name: String,
	description: String,
	price: int,
	extra_clones: int,
	work_multiplier: float,
	dating_multiplier: float
) -> AutomationUpgradeDefinition:
	var upgrade := AutomationUpgradeDefinition.new()
	upgrade.id = id
	upgrade.display_name = display_name
	upgrade.description = description
	upgrade.price = price
	upgrade.extra_clones = extra_clones
	upgrade.work_multiplier = work_multiplier
	upgrade.dating_multiplier = dating_multiplier
	return upgrade
