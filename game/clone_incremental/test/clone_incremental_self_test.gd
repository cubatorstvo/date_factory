extends Node
## MODULE 18 Clone Incremental core self-test (spec §§63–79).
## Run: res://game/clone_incremental/test/clone_incremental_test.tscn --quit-after 60000


var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _gs: Node = null
var _ci: Node = null
var _day: Node = null
var _overload: Node = null
var _fc: Node = null
var _media: Node = null
var _story: Node = null
var _world: Node = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_ci = get_node("/root/CloneIncremental")
	_day = get_node("/root/GameDay")
	_overload = get_node("/root/DatingOverload")
	_fc = get_node("/root/FirstClone")
	_media = get_node("/root/Media")
	_story = get_node("/root/Story")
	_world = get_node("/root/World")
	await get_tree().process_frame
	if _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_18_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_18_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_18_TEST PASS: %s" % label)
	else:
		DfLog.error("MODULE_18_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_18_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_18_TEST] FAIL: %s" % label)
		print("MODULE_18_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")


func _set_clones(total: int, working: int, dating: int) -> void:
	_gs.call("set_clone_counts", total, working, dating)
	_ci.call("recalculate_rates")


func _seed_overload_backlog(count: int = 2) -> void:
	# Manual backlog only — do not raise Media attention (avoids auto first-wave).
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	if not bool(_gs.call("is_dating_overload_started")):
		var day: int = int(_day.call("get_current_day"))
		_gs.call("mark_dating_overload_started", day)
	for i in range(count):
		var entry: DatingDemandEntry = DatingDemandEntry.new()
		entry.request_id = int(_gs.call("allocate_dating_demand_request_id"))
		if i % 2 == 0:
			entry.girl_id = &"girl_appearance_flash"
		else:
			entry.girl_id = &"girl_public_sculpture"
		entry.created_day = int(_day.call("get_current_day"))
		entry.appointment_day = int(_day.call("get_current_day"))
		entry.slot = DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING
		entry.status = DatingOverloadTypes.DatingDemandStatus.WAITING
		entry.fulfilled_day = -1
		_gs.call("append_dating_demand", entry)


func _run_all() -> void:
	_test_zero_clones()
	_test_initial_rates()
	_test_production()
	_test_production_levels()
	_test_work_formula()
	_test_dating_formula()
	_test_backlog_first()
	_test_fulfill_no_hero_capacity()
	_test_late_xp()
	_test_costs()
	_test_assignment()
	_test_rate_update_immediate()
	_test_representative_refresh()
	_test_gameday_no_output()
	_test_stage_unchanged()
	_test_terminal_prompts()
	_test_reset_runtime()
	_reset()


func _test_zero_clones() -> void:
	_reset()
	var money0: int = int(_gs.call("get_money"))
	var xp0: int = int(_gs.call("get_experience"))
	_ci.call("advance_simulation_for_test", 300.0)
	_ok(int(_gs.call("get_total_clones")) == 0, "63 total0")
	_ok(int(_gs.call("get_money")) == money0, "63 no money")
	_ok(int(_gs.call("get_experience")) == xp0, "63 no xp")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "63 mpm0")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.0), "63 dpm0")
	var st: CloneIncrementalStatus = _ci.call("get_status") as CloneIncrementalStatus
	_ok(st != null and not st.active and is_equal_approx(st.production_elapsed, 0.0), "63 inactive elapsed0")


func _test_initial_rates() -> void:
	_reset()
	_set_clones(1, 1, 0)
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 20.0), "64 WORK mpm20")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.0), "64 WORK dpm0")
	_set_clones(1, 0, 1)
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "64 DATING mpm0")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.50), "64 DATING dpm0.5")
	var st: CloneIncrementalStatus = _ci.call("get_status") as CloneIncrementalStatus
	_ok(st != null and is_equal_approx(st.production_interval, 30.0), "64 interval30")


func _test_production() -> void:
	_reset()
	_set_clones(1, 1, 0)
	_ci.call("advance_simulation_for_test", 29.9)
	_ok(int(_gs.call("get_total_clones")) == 1, "65 no clone at 29.9")
	_ok(int(_gs.call("get_free_clones")) == 0, "65 free0 at 29.9")
	_ci.call("advance_simulation_for_test", 0.1)
	_ok(int(_gs.call("get_total_clones")) == 2, "65 +1 at 30s")
	_ok(int(_gs.call("get_clones_working")) == 1, "65 working preserved")
	_ok(int(_gs.call("get_clones_dating")) == 0, "65 dating preserved")
	_ok(int(_gs.call("get_free_clones")) == 1, "65 new free")
	_reset()
	_set_clones(1, 1, 0)
	_ci.call("advance_simulation_for_test", 90.0)
	_ok(int(_gs.call("get_total_clones")) == 4, "65 90s => +3 total4")
	_ok(int(_gs.call("get_free_clones")) == 3, "65 free3")


func _test_production_levels() -> void:
	_reset()
	_set_clones(1, 1, 0)
	_gs.call("add_money", 10000)
	var expected: Array[float] = [30.0, 25.0, 20.0, 15.0, 10.0, 5.0]
	for lvl in range(0, 6):
		var st: CloneIncrementalStatus = _ci.call("get_status") as CloneIncrementalStatus
		_ok(st != null and is_equal_approx(st.production_interval, expected[lvl]), "66 interval L%s" % lvl)
		if lvl < 5:
			var buy: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED) as CloneUpgradePurchaseResult
			_ok(buy != null and buy.ok, "66 buy production L%s" % (lvl + 1))
	# Elapsed carry: 27s at L0, buy L1 => spawn + remainder 2.
	_reset()
	_set_clones(1, 0, 0)
	_gs.call("add_money", 100)
	_ci.call("advance_simulation_for_test", 27.0)
	_ok(int(_gs.call("get_total_clones")) == 1, "66 still1 before buy")
	var buy2: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED) as CloneUpgradePurchaseResult
	_ok(buy2 != null and buy2.ok, "66 buy with elapsed")
	_ok(int(_gs.call("get_total_clones")) == 2, "66 immediate spawn")
	_ok(is_equal_approx(float(_ci.call("get_production_elapsed")), 2.0), "66 remainder2")


func _test_work_formula() -> void:
	_reset()
	_set_clones(1, 1, 0)
	var expected: Array[float] = [20.0, 30.0, 40.0, 50.0, 60.0, 70.0]
	_gs.call("add_money", 50000)
	for lvl in range(0, 6):
		_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), expected[lvl]), "67 work rate L%s" % lvl)
		if lvl < 5:
			var buy: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY) as CloneUpgradePurchaseResult
			_ok(buy != null and buy.ok, "67 buy work L%s" % (lvl + 1))
	_reset()
	_set_clones(3, 3, 0)
	_gs.call("set_clone_work_upgrade_level", 2)
	_ci.call("recalculate_rates")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 120.0), "67 3workers L2 =>120")
	# Fractional money payout.
	_reset()
	_set_clones(1, 1, 0)
	var money0: int = int(_gs.call("get_money"))
	_ci.call("advance_simulation_for_test", 60.0)
	_ok(int(_gs.call("get_money")) == money0 + 20, "67 60s => +20 money")


func _test_dating_formula() -> void:
	_reset()
	_set_clones(1, 0, 1)
	var expected: Array[float] = [0.50, 0.75, 1.00, 1.25, 1.50, 1.75]
	_gs.call("add_money", 50000)
	for lvl in range(0, 6):
		_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), expected[lvl]), "68 dating rate L%s" % lvl)
		if lvl < 5:
			var buy: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY) as CloneUpgradePurchaseResult
			_ok(buy != null and buy.ok, "68 buy dating L%s" % (lvl + 1))


func _test_backlog_first() -> void:
	_reset()
	_seed_overload_backlog(2)
	_set_clones(1, 0, 1)
	var xp0: int = int(_gs.call("get_experience"))
	var up0: int = int(_gs.call("get_upgrade_points"))
	_ok(int(_overload.call("get_backlog_count")) == 2, "69 backlog2")
	# 0.5 dates/min => 5 dates in 600s.
	_ci.call("advance_simulation_for_test", 600.0)
	_ok(int(_overload.call("get_backlog_count")) == 0, "69 backlog cleared")
	_ok(int(_gs.call("get_experience")) == xp0 + 3, "69 XP +3")
	_ok(int(_gs.call("get_upgrade_points")) == up0 + 3, "69 UP +3")


func _test_fulfill_no_hero_capacity() -> void:
	_reset()
	_seed_overload_backlog(2)
	var last0: int = int(_gs.call("get_dating_overload_last_personal_date_day"))
	var personal0: int = int(_gs.call("get_dating_overload_personal_dates_completed"))
	_ok(bool(_overload.call("can_start_personal_date")), "70 can personal before")
	_ok(bool(_overload.call("fulfill_oldest_demand_by_clone")), "70 fulfill ok")
	_ok(int(_overload.call("get_backlog_count")) == 1, "70 backlog1")
	_ok(bool(_overload.call("can_start_personal_date")), "70 can personal after")
	_ok(int(_gs.call("get_dating_overload_last_personal_date_day")) == last0, "70 last day untouched")
	_ok(int(_gs.call("get_dating_overload_personal_dates_completed")) == personal0, "70 personal count untouched")
	_ok(int(_gs.call("get_girl_relationship", &"girl_appearance_flash")) == 0, "70 no relationship")


func _test_late_xp() -> void:
	_reset()
	_set_clones(1, 0, 1)
	var xp0: int = int(_gs.call("get_experience"))
	# No backlog: 0.5/min => 1 date in 120s.
	_ci.call("advance_simulation_for_test", 120.0)
	_ok(int(_gs.call("get_experience")) == xp0 + 1, "71 late XP +1")
	_ok(int(_gs.call("get_upgrade_points")) == xp0 + 1, "71 late UP +1")


func _test_costs() -> void:
	_reset()
	_set_clones(1, 1, 0)
	var costs: Array[int] = [30, 90, 270, 810, 2430]
	for i in range(costs.size()):
		_ok(int(_ci.call("get_upgrade_cost", CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED)) == costs[i], "72 cost L%s" % i)
		_gs.call("add_money", costs[i])
		var buy: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED) as CloneUpgradePurchaseResult
		_ok(buy != null and buy.ok and buy.money_spent == costs[i], "72 buy L%s" % (i + 1))
	var maxed: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED) as CloneUpgradePurchaseResult
	_ok(maxed != null and not maxed.ok and maxed.error == CloneIncrementalTypes.UpgradePurchaseError.MAX_LEVEL, "72 MAX")
	_reset()
	_set_clones(1, 1, 0)
	var poor: CloneUpgradePurchaseResult = _ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY) as CloneUpgradePurchaseResult
	_ok(poor != null and poor.error == CloneIncrementalTypes.UpgradePurchaseError.NOT_ENOUGH_MONEY, "72 NOT_ENOUGH_MONEY")


func _test_assignment() -> void:
	_reset()
	_set_clones(3, 0, 0)
	_ok(bool(_ci.call("assign_one_to_work")), "73 +1 work")
	_ok(int(_gs.call("get_clones_working")) == 1 and int(_gs.call("get_free_clones")) == 2, "73 work1 free2")
	_ok(bool(_ci.call("assign_all_free_to_dating")), "73 all free dating")
	_ok(int(_gs.call("get_clones_dating")) == 2 and int(_gs.call("get_free_clones")) == 0, "73 dating2 free0")
	_ok(not bool(_ci.call("assign_one_to_work")), "73 cannot over-assign")
	_ok(bool(_ci.call("unassign_one_from_dating")), "73 -1 dating")
	_ok(int(_gs.call("get_free_clones")) == 1, "73 free1")
	_ok(bool(_ci.call("unassign_one_from_work")), "73 -1 work")
	_ok(int(_gs.call("get_clones_working")) == 0, "73 work0")
	_ok(not bool(_ci.call("unassign_one_from_work")), "73 cannot below0")


func _test_rate_update_immediate() -> void:
	_reset()
	_set_clones(2, 0, 0)
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "74 mpm0 free")
	_ci.call("assign_one_to_work")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 20.0), "74 mpm20 immediate")
	_ci.call("assign_one_to_dating")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.50), "74 dpm0.5 immediate")


func _test_representative_refresh() -> void:
	_reset()
	_world.set("current_location_id", &"laboratory")
	# Minimal markers under test scene.
	var work_m: Node3D = Node3D.new()
	work_m.name = FirstCloneTypes.MARKER_WORK
	var date_m: Node3D = Node3D.new()
	date_m.name = FirstCloneTypes.MARKER_DATE
	var out_m: Node3D = Node3D.new()
	out_m.name = FirstCloneTypes.MARKER_OUTPUT
	add_child(work_m)
	add_child(date_m)
	add_child(out_m)
	_set_clones(1, 1, 0)
	_fc.call("reconstruct_representative")
	var rep: FirstCloneActor = _fc.call("get_representative_actor") as FirstCloneActor
	_ok(rep != null and is_instance_valid(rep), "75 rep exists")
	_set_clones(2, 0, 1)
	# clone_counts_changed should reconstruct; force if markers under self.
	_fc.call("reconstruct_representative")
	var rep2: FirstCloneActor = _fc.call("get_representative_actor") as FirstCloneActor
	_ok(rep2 != null and is_instance_valid(rep2), "75 rep after dating")
	work_m.queue_free()
	date_m.queue_free()
	out_m.queue_free()


func _test_gameday_no_output() -> void:
	_reset()
	_set_clones(1, 1, 0)
	var total0: int = int(_gs.call("get_total_clones"))
	var money0: int = int(_gs.call("get_money"))
	var xp0: int = int(_gs.call("get_experience"))
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_gs.call("get_total_clones")) == total0, "77 GameDay no clones")
	_ok(int(_gs.call("get_money")) == money0, "77 GameDay no money")
	_ok(int(_gs.call("get_experience")) == xp0, "77 GameDay no xp")


func _test_stage_unchanged() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_set_clones(100, 50, 50)
	_gs.call("add_money", 100000)
	for _i in range(5):
		_ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED)
		_ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY)
		_ci.call("buy_upgrade", CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY)
	_ci.call("advance_simulation_for_test", 120.0)
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_5), "79 stage stays5")


func _test_terminal_prompts() -> void:
	_reset()
	var node: CloneTerminalInteractable = CloneTerminalInteractable.new()
	add_child(node)
	_ok(node.get_interaction_prompt(null) == CloneIncrementalTypes.TERMINAL_LOCKED_PROMPT, "terminal locked")
	_set_clones(1, 1, 0)
	_ok(node.get_interaction_prompt(null) == "[E] %s" % CloneIncrementalTypes.TERMINAL_PROMPT, "terminal open prompt")
	node.queue_free()


func _test_reset_runtime() -> void:
	_reset()
	_set_clones(1, 1, 0)
	_ci.call("advance_simulation_for_test", 10.0)
	_gs.call("set_clone_production_upgrade_level", 2)
	_gs.call("reset_for_new_game")
	var st: CloneIncrementalStatus = _ci.call("get_status") as CloneIncrementalStatus
	_ok(st != null and not st.active, "51 inactive after reset")
	_ok(is_equal_approx(st.production_elapsed, 0.0), "51 elapsed0")
	_ok(int(_gs.call("get_clone_production_upgrade_level")) == 0, "51 prod level0")
	_ok(int(_gs.call("get_clone_work_upgrade_level")) == 0, "51 work level0")
	_ok(int(_gs.call("get_clone_dating_upgrade_level")) == 0, "51 dating level0")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "51 mpm0")
