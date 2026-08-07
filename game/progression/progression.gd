extends Node
## Progression service — perk purchase, tree rules, cost (MODULE 05).
## Autoload name: Progression. Persistent ownership lives in GameState.
## No effect engine, no EventBus, no _process, no price cache.


enum PerkAvailability {
	AVAILABLE,
	OWNED,
	LOCKED_PREREQUISITE,
	NOT_ENOUGH_POINTS,
	UNKNOWN_PERK,
}


enum PerkPurchaseResult {
	SUCCESS,
	ALREADY_OWNED,
	PREREQUISITE_NOT_MET,
	NOT_ENOUGH_POINTS,
	UNKNOWN_PERK,
	INVALID_CONTENT,
}


signal perk_purchased(perk_id: StringName, characteristic: GameTypes.PlayerCharacteristic, cost: int)


func _ready() -> void:
	DfLog.info("MODULE_05", "Progression ready")


func has_perk(perk_id: StringName) -> bool:
	return GameState.has_perk(perk_id)


func get_next_perk_cost() -> int:
	return _pow3_int(GameState.get_purchased_perk_count())


func get_perk_purchase_cost(_perk_id: StringName) -> int:
	return get_next_perk_cost()


func get_perk_availability(perk_id: StringName) -> PerkAvailability:
	var def: PerkDefinition = ContentDB.get_perk(perk_id)
	if def == null:
		return PerkAvailability.UNKNOWN_PERK
	if GameState.has_perk(perk_id):
		return PerkAvailability.OWNED
	if not _prerequisites_met(def):
		return PerkAvailability.LOCKED_PREREQUISITE
	var cost: int = get_next_perk_cost()
	if not GameState.can_spend_upgrade_points(cost):
		return PerkAvailability.NOT_ENOUGH_POINTS
	return PerkAvailability.AVAILABLE


func purchase_perk(perk_id: StringName) -> PerkPurchaseResult:
	var def: PerkDefinition = ContentDB.get_perk(perk_id)
	if def == null:
		push_error("[Progression] purchase_perk unknown perk: %s" % String(perk_id))
		return PerkPurchaseResult.UNKNOWN_PERK
	if not _is_valid_tree_slot(def):
		push_error("[Progression] purchase_perk invalid content slot: %s" % String(perk_id))
		return PerkPurchaseResult.INVALID_CONTENT
	if GameState.has_perk(perk_id):
		return PerkPurchaseResult.ALREADY_OWNED
	if not _prerequisites_met(def):
		return PerkPurchaseResult.PREREQUISITE_NOT_MET
	var cost: int = get_next_perk_cost()
	if not GameState.can_spend_upgrade_points(cost):
		return PerkPurchaseResult.NOT_ENOUGH_POINTS
	var committed: bool = GameState._commit_perk_purchase(perk_id, def.characteristic, cost)
	if not committed:
		push_error("[Progression] purchase_perk commit failed: %s" % String(perk_id))
		return PerkPurchaseResult.INVALID_CONTENT
	perk_purchased.emit(perk_id, def.characteristic, cost)
	return PerkPurchaseResult.SUCCESS


func get_perks_for_characteristic(characteristic: GameTypes.PlayerCharacteristic) -> Array[PerkDefinition]:
	var filtered: Array[PerkDefinition] = []
	var all_perks: Array[PerkDefinition] = ContentDB.list_perks()
	for def in all_perks:
		if def == null:
			continue
		if int(def.characteristic) == int(characteristic):
			filtered.append(def)
	filtered.sort_custom(_sort_perk_tree_order)
	return filtered


func validate_characteristic_invariant() -> bool:
	for c in [
		GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.PlayerCharacteristic.AURA,
	]:
		var owned_count: int = 0
		for pid in GameState.get_purchased_perk_ids():
			var def: PerkDefinition = ContentDB.get_perk(pid)
			if def == null:
				return false
			if int(def.characteristic) == int(c):
				owned_count += 1
		if GameState.get_characteristic(c) != owned_count:
			return false
	return true


func _pow3_int(n: int) -> int:
	if n < 0:
		push_error("[Progression] negative purchased count")
		return 1
	var result: int = 1
	for _i in range(n):
		result *= 3
	return result


func _is_valid_tree_slot(def: PerkDefinition) -> bool:
	if def.order_in_section != 1 and def.order_in_section != 2:
		return false
	match def.section:
		GameTypes.PerkSection.EARLY_COMMON, GameTypes.PerkSection.BRANCH_A, GameTypes.PerkSection.BRANCH_B, GameTypes.PerkSection.LATE_COMMON:
			return true
	return false


func _prerequisites_met(def: PerkDefinition) -> bool:
	var c: GameTypes.PlayerCharacteristic = def.characteristic
	match def.section:
		GameTypes.PerkSection.EARLY_COMMON:
			if def.order_in_section == 1:
				return true
			if def.order_in_section == 2:
				return _owns_slot(c, GameTypes.PerkSection.EARLY_COMMON, 1)
			return false
		GameTypes.PerkSection.BRANCH_A:
			if def.order_in_section == 1:
				return _owns_slot(c, GameTypes.PerkSection.EARLY_COMMON, 2)
			if def.order_in_section == 2:
				return _owns_slot(c, GameTypes.PerkSection.BRANCH_A, 1)
			return false
		GameTypes.PerkSection.BRANCH_B:
			if def.order_in_section == 1:
				return _owns_slot(c, GameTypes.PerkSection.EARLY_COMMON, 2)
			if def.order_in_section == 2:
				return _owns_slot(c, GameTypes.PerkSection.BRANCH_B, 1)
			return false
		GameTypes.PerkSection.LATE_COMMON:
			if def.order_in_section == 1:
				return (
					_owns_slot(c, GameTypes.PerkSection.BRANCH_A, 2)
					or _owns_slot(c, GameTypes.PerkSection.BRANCH_B, 2)
				)
			if def.order_in_section == 2:
				return _owns_slot(c, GameTypes.PerkSection.LATE_COMMON, 1)
			return false
	return false


func _owns_slot(
	characteristic: GameTypes.PlayerCharacteristic,
	section: GameTypes.PerkSection,
	order_in_section: int,
) -> bool:
	var all_perks: Array[PerkDefinition] = ContentDB.list_perks()
	for def in all_perks:
		if def == null:
			continue
		if int(def.characteristic) != int(characteristic):
			continue
		if int(def.section) != int(section):
			continue
		if def.order_in_section != order_in_section:
			continue
		return GameState.has_perk(def.id)
	return false


func _sort_perk_tree_order(a: PerkDefinition, b: PerkDefinition) -> bool:
	if int(a.section) != int(b.section):
		return int(a.section) < int(b.section)
	if a.order_in_section != b.order_in_section:
		return a.order_in_section < b.order_in_section
	return String(a.id) < String(b.id)
