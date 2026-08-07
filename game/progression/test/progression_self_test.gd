extends Node
## Reproducible MODULE 05 Progression & Perks tests (spec §§91–111).
## Run via game/progression/test/progression_test.tscn
## Headless: --path . --headless --quit-after 5000 res://game/progression/test/progression_test.tscn

const _ProgressionScript = preload("res://game/progression/progression.gd")


var _failed: int = 0
var _passed: int = 0
var _perk_signal_count: int = 0
var _last_perk_signal_id: StringName = &""
var _last_perk_signal_cost: int = -1
var _char_signal_count: int = 0
var _up_signal_count: int = 0
var _prog: Node = null
var _gs: Node = null
var _db: Node = null


func _ready() -> void:
	_prog = get_node("/root/Progression")
	_gs = get_node("/root/GameState")
	_db = get_node("/root/ContentDB")
	await get_tree().process_frame
	_run_all()
	if _failed == 0:
		DfLog.info("MODULE_05_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_05_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_05_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_05_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_05_TEST] FAIL: %s" % label)
		print("MODULE_05_TEST FAIL: %s" % label)


func _run_all() -> void:
	_connect_signals()
	_test_perk_ids_in_contentdb()
	_test_starting()
	_test_first_purchase()
	_test_global_price()
	_test_prerequisite()
	_test_branch_opening()
	_test_branch_chain()
	_test_late_via_a()
	_test_late_via_b()
	_test_branch_still_buyable()
	_test_late_order()
	_test_invariant()
	_test_insufficient_points()
	_test_duplicate()
	_test_unknown()
	_test_cost_sequence()
	_test_reset_after_purchases()
	_test_signals()
	_test_full_trees()
	_test_all_32()
	_gs.call("reset_for_new_game")


func _connect_signals() -> void:
	_prog.connect("perk_purchased", _on_perk_purchased)
	_gs.connect("characteristic_changed", _on_char_changed)
	_gs.connect("upgrade_points_changed", _on_up_changed)


func _on_perk_purchased(perk_id: StringName, _characteristic: GameTypes.PlayerCharacteristic, cost: int) -> void:
	_perk_signal_count += 1
	_last_perk_signal_id = perk_id
	_last_perk_signal_cost = cost


func _on_char_changed(
	_characteristic: GameTypes.PlayerCharacteristic,
	_new_value: int,
	_previous_value: int,
) -> void:
	_char_signal_count += 1


func _on_up_changed(_new_value: int, _delta: int) -> void:
	_up_signal_count += 1


func _avail(perk_id: StringName) -> int:
	return int(_prog.call("get_perk_availability", perk_id))


func _buy(perk_id: StringName) -> int:
	return int(_prog.call("purchase_perk", perk_id))


func _grant(amount: int) -> void:
	_gs.call("add_experience", amount)


func _reset() -> void:
	_gs.call("reset_for_new_game")


func _test_perk_ids_in_contentdb() -> void:
	var ids: Array[StringName] = PerkIds.all_ids()
	_ok(ids.size() == 32, "PerkIds has 32 constants")
	for pid in ids:
		var def: PerkDefinition = _db.call("get_perk", pid) as PerkDefinition
		_ok(def != null and def.id == pid, "PerkIds constant in ContentDB %s" % String(pid))


func _test_starting() -> void:
	_reset()
	_ok(int(_gs.call("get_experience")) == 0, "start xp 0")
	_ok(int(_gs.call("get_upgrade_points")) == 0, "start up 0")
	_ok(int(_gs.call("get_purchased_perk_count")) == 0, "start perks empty")
	_ok(int(_gs.call("get_muscle")) == 0, "start muscle 0")
	_ok(int(_gs.call("get_appearance")) == 0, "start appearance 0")
	_ok(int(_gs.call("get_capital")) == 0, "start capital 0")
	_ok(int(_gs.call("get_aura")) == 0, "start aura 0")
	_ok(int(_prog.call("get_next_perk_cost")) == 1, "start next cost 1")


func _test_first_purchase() -> void:
	_reset()
	_grant(1)
	_ok(int(_gs.call("get_experience")) == 1, "first grant xp 1")
	_ok(int(_gs.call("get_upgrade_points")) == 1, "first grant up 1")
	var result: int = _buy(PerkIds.MUSCLE_NO_WARMUP)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "first purchase SUCCESS")
	_ok(bool(_gs.call("has_perk", PerkIds.MUSCLE_NO_WARMUP)), "owned M1")
	_ok(bool(_prog.call("has_perk", PerkIds.MUSCLE_NO_WARMUP)), "Progression.has_perk alias")
	_ok(int(_gs.call("get_muscle")) == 1, "muscle 1 after M1")
	_ok(int(_gs.call("get_upgrade_points")) == 0, "up 0 after first buy")
	_ok(int(_prog.call("get_next_perk_cost")) == 3, "next cost 3")


func _test_global_price() -> void:
	_reset()
	_grant(100000)
	_ok(_buy(PerkIds.MUSCLE_NO_WARMUP) == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "global M1")
	_ok(int(_prog.call("get_next_perk_cost")) == 3, "cost after 1 is 3")
	_ok(_buy(PerkIds.APPEARANCE_GOOD_PROFILE) == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "global A1")
	_ok(int(_prog.call("get_next_perk_cost")) == 9, "cost after 2 is 9")
	_ok(_buy(PerkIds.CAPITAL_PAYABLE_INTENT) == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "global C1")
	_ok(int(_prog.call("get_next_perk_cost")) == 27, "cost after 3 is 27")
	_ok(_buy(PerkIds.AURA_PRESENCE_REGISTERED) == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "global Aura1")
	_ok(int(_prog.call("get_next_perk_cost")) == 81, "cost after 4 is 81")


func _test_prerequisite() -> void:
	_reset()
	_grant(100)
	var before_up: int = int(_gs.call("get_upgrade_points"))
	var before_muscle: int = int(_gs.call("get_muscle"))
	var result: int = _buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.PREREQUISITE_NOT_MET), "M2 without M1")
	_ok(int(_gs.call("get_upgrade_points")) == before_up, "prereq fail up unchanged")
	_ok(int(_gs.call("get_muscle")) == before_muscle, "prereq fail muscle unchanged")
	_ok(not bool(_gs.call("has_perk", PerkIds.MUSCLE_TOUGH_CHEEK)), "prereq fail not owned")


func _test_branch_opening() -> void:
	_reset()
	_grant(100000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	var avail_a: int = _avail(PerkIds.MUSCLE_DOUBLE_SLAP)
	var avail_b: int = _avail(PerkIds.MUSCLE_HOLD_DOORWAY)
	_ok(
		avail_a == int(_ProgressionScript.PerkAvailability.AVAILABLE)
		or avail_a == int(_ProgressionScript.PerkAvailability.NOT_ENOUGH_POINTS),
		"branch A open after early",
	)
	_ok(
		avail_b == int(_ProgressionScript.PerkAvailability.AVAILABLE)
		or avail_b == int(_ProgressionScript.PerkAvailability.NOT_ENOUGH_POINTS),
		"branch B open after early",
	)
	_ok(_avail(PerkIds.MUSCLE_DOUBLE_SLAP) != int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "A not locked")
	_ok(_avail(PerkIds.MUSCLE_HOLD_DOORWAY) != int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "B not locked")


func _test_branch_chain() -> void:
	_reset()
	_grant(100000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_buy(PerkIds.MUSCLE_DOUBLE_SLAP)
	_ok(_avail(PerkIds.MUSCLE_COUNTER_ARGUMENT) != int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "A2 open after A1")
	_ok(_avail(PerkIds.MUSCLE_HEROIC_DEFEAT) == int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "B2 locked without B1")


func _test_late_via_a() -> void:
	_reset()
	_grant(100000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_buy(PerkIds.MUSCLE_DOUBLE_SLAP)
	_buy(PerkIds.MUSCLE_COUNTER_ARGUMENT)
	_ok(_avail(PerkIds.MUSCLE_MASS_RESERVE) != int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "late open via A")
	_ok(_avail(PerkIds.MUSCLE_HOLD_DOORWAY) != int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "B1 still open after late via A")


func _test_late_via_b() -> void:
	_reset()
	_grant(100000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_buy(PerkIds.MUSCLE_HOLD_DOORWAY)
	_buy(PerkIds.MUSCLE_HEROIC_DEFEAT)
	_ok(_avail(PerkIds.MUSCLE_MASS_RESERVE) != int(_ProgressionScript.PerkAvailability.LOCKED_PREREQUISITE), "late open via B")


func _test_branch_still_buyable() -> void:
	_reset()
	_grant(1000000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_buy(PerkIds.MUSCLE_DOUBLE_SLAP)
	_buy(PerkIds.MUSCLE_COUNTER_ARGUMENT)
	_buy(PerkIds.MUSCLE_MASS_RESERVE)
	var result: int = _buy(PerkIds.MUSCLE_HOLD_DOORWAY)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "B1 buyable after late via A")


func _test_late_order() -> void:
	_reset()
	_grant(100000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_buy(PerkIds.MUSCLE_DOUBLE_SLAP)
	_buy(PerkIds.MUSCLE_COUNTER_ARGUMENT)
	var result: int = _buy(PerkIds.MUSCLE_TWO_HANDED_ARGUMENT)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.PREREQUISITE_NOT_MET), "late2 without late1")


func _test_invariant() -> void:
	_reset()
	_grant(1000000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.MUSCLE_TOUGH_CHEEK)
	_buy(PerkIds.MUSCLE_DOUBLE_SLAP)
	_buy(PerkIds.APPEARANCE_GOOD_PROFILE)
	_buy(PerkIds.CAPITAL_PAYABLE_INTENT)
	_ok(bool(_prog.call("validate_characteristic_invariant")), "invariant holds after mixed buys")
	_ok(int(_gs.call("get_muscle")) == 3, "muscle count 3")
	_ok(int(_gs.call("get_appearance")) == 1, "appearance count 1")
	_ok(int(_gs.call("get_capital")) == 1, "capital count 1")


func _test_insufficient_points() -> void:
	_reset()
	_ok(_avail(PerkIds.MUSCLE_NO_WARMUP) == int(_ProgressionScript.PerkAvailability.NOT_ENOUGH_POINTS), "avail NOT_ENOUGH_POINTS")
	var result: int = _buy(PerkIds.MUSCLE_NO_WARMUP)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.NOT_ENOUGH_POINTS), "buy NOT_ENOUGH_POINTS")
	_ok(int(_gs.call("get_muscle")) == 0, "insufficient leaves muscle 0")
	_ok(not bool(_gs.call("has_perk", PerkIds.MUSCLE_NO_WARMUP)), "insufficient not owned")


func _test_duplicate() -> void:
	_reset()
	_grant(100)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	var before_up: int = int(_gs.call("get_upgrade_points"))
	var before_cost: int = int(_prog.call("get_next_perk_cost"))
	var before_muscle: int = int(_gs.call("get_muscle"))
	var result: int = _buy(PerkIds.MUSCLE_NO_WARMUP)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.ALREADY_OWNED), "duplicate ALREADY_OWNED")
	_ok(int(_gs.call("get_upgrade_points")) == before_up, "duplicate up unchanged")
	_ok(int(_gs.call("get_muscle")) == before_muscle, "duplicate muscle unchanged")
	_ok(int(_prog.call("get_next_perk_cost")) == before_cost, "duplicate cost unchanged")


func _test_unknown() -> void:
	_reset()
	_grant(10)
	var result: int = _buy(&"perk_missing")
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.UNKNOWN_PERK), "unknown UNKNOWN_PERK")
	_ok(_avail(&"perk_missing") == int(_ProgressionScript.PerkAvailability.UNKNOWN_PERK), "unknown avail")


func _test_cost_sequence() -> void:
	_reset()
	var expected: Array[int] = [1, 3, 9, 27, 81, 243, 729, 2187, 6561, 19683]
	var purchase_order: Array[StringName] = [
		PerkIds.MUSCLE_NO_WARMUP,
		PerkIds.MUSCLE_TOUGH_CHEEK,
		PerkIds.MUSCLE_DOUBLE_SLAP,
		PerkIds.MUSCLE_COUNTER_ARGUMENT,
		PerkIds.MUSCLE_HOLD_DOORWAY,
		PerkIds.MUSCLE_HEROIC_DEFEAT,
		PerkIds.MUSCLE_MASS_RESERVE,
		PerkIds.MUSCLE_TWO_HANDED_ARGUMENT,
		PerkIds.APPEARANCE_GOOD_PROFILE,
		PerkIds.APPEARANCE_STAGED_WALK,
	]
	_grant(100000000)
	for i in range(expected.size()):
		var cost: int = int(_prog.call("get_next_perk_cost"))
		_ok(cost == expected[i], "cost[%s] == %s (got %s)" % [i, expected[i], cost])
		var buy_cost: int = int(_prog.call("get_perk_purchase_cost", purchase_order[i]))
		_ok(buy_cost == expected[i], "purchase_cost[%s] matches" % i)
		var result: int = _buy(purchase_order[i])
		_ok(result == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "cost seq buy %s" % i)


func _test_reset_after_purchases() -> void:
	_reset()
	_grant(1000)
	_buy(PerkIds.MUSCLE_NO_WARMUP)
	_buy(PerkIds.APPEARANCE_GOOD_PROFILE)
	_reset()
	_ok(int(_gs.call("get_purchased_perk_count")) == 0, "reset clears perks")
	_ok(int(_gs.call("get_muscle")) == 0, "reset muscle 0")
	_ok(int(_gs.call("get_appearance")) == 0, "reset appearance 0")
	_ok(int(_prog.call("get_next_perk_cost")) == 1, "reset next cost 1")


func _test_signals() -> void:
	_reset()
	_grant(10)
	var perk_before: int = _perk_signal_count
	var char_before: int = _char_signal_count
	var up_before: int = _up_signal_count
	var result: int = _buy(PerkIds.MUSCLE_NO_WARMUP)
	_ok(result == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "signal buy success")
	_ok(_perk_signal_count == perk_before + 1, "perk_purchased emitted")
	_ok(_last_perk_signal_id == PerkIds.MUSCLE_NO_WARMUP, "perk_purchased id")
	_ok(_last_perk_signal_cost == 1, "perk_purchased cost 1")
	_ok(_char_signal_count == char_before + 1, "characteristic_changed on buy")
	_ok(_up_signal_count == up_before + 1, "upgrade_points_changed on buy")
	var perk_mid: int = _perk_signal_count
	var char_mid: int = _char_signal_count
	var fail: int = _buy(PerkIds.MUSCLE_TWO_HANDED_ARGUMENT)
	_ok(fail == int(_ProgressionScript.PerkPurchaseResult.PREREQUISITE_NOT_MET), "fail buy for signal")
	_ok(_perk_signal_count == perk_mid, "failed buy no perk_purchased")
	_ok(_char_signal_count == char_mid, "failed buy no characteristic_changed")


func _buy_full_tree(characteristic: GameTypes.PlayerCharacteristic) -> void:
	var tree: Array[PerkDefinition] = _prog.call("get_perks_for_characteristic", characteristic) as Array[PerkDefinition]
	_ok(tree.size() == 8, "tree size 8 for %s" % characteristic)
	# Deterministic purchase order: EARLY1, EARLY2, A1, A2, B1, B2, LATE1, LATE2
	for def in tree:
		var result: int = _buy(def.id)
		_ok(result == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "full tree buy %s" % String(def.id))
	_ok(int(_gs.call("get_characteristic", characteristic)) == 8, "char level 8 for %s" % characteristic)


func _test_full_trees() -> void:
	for c in [
		GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.PlayerCharacteristic.AURA,
	]:
		_reset()
		_grant(100000000)
		_buy_full_tree(c)
		_ok(bool(_prog.call("validate_characteristic_invariant")), "invariant after full %s" % c)


func _test_all_32() -> void:
	_reset()
	# Sum of costs 3^0..3^31 = (3^32 - 1) / 2 = 926510094425920
	_grant(1000000000000000)
	for c in [
		GameTypes.PlayerCharacteristic.MUSCLE,
		GameTypes.PlayerCharacteristic.APPEARANCE,
		GameTypes.PlayerCharacteristic.CAPITAL,
		GameTypes.PlayerCharacteristic.AURA,
	]:
		var tree: Array[PerkDefinition] = _prog.call("get_perks_for_characteristic", c) as Array[PerkDefinition]
		for def in tree:
			var result: int = _buy(def.id)
			_ok(result == int(_ProgressionScript.PerkPurchaseResult.SUCCESS), "all32 buy %s" % String(def.id))
	_ok(int(_gs.call("get_purchased_perk_count")) == 32, "all 32 owned")
	_ok(int(_gs.call("get_muscle")) == 8, "all32 muscle 8")
	_ok(int(_gs.call("get_appearance")) == 8, "all32 appearance 8")
	_ok(int(_gs.call("get_capital")) == 8, "all32 capital 8")
	_ok(int(_gs.call("get_aura")) == 8, "all32 aura 8")
	_ok(bool(_prog.call("validate_characteristic_invariant")), "all32 invariant")
	var next_cost: int = int(_prog.call("get_next_perk_cost"))
	_ok(next_cost == 1853020188851841, "next cost after 32 is 3^32")
