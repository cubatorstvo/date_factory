extends Node
## MODULE 26 Wave B/E — balance projection self-test (spec §§62–86 + Wave E media/story).
## Run: res://game/balance/test/balance_test.tscn --headless --quit-after 300000

const _BalanceProjectionScript = preload("res://game/balance/test/balance_projection.gd")
const _BalanceWaveEChecksScript = preload("res://game/balance/test/balance_wave_e_checks.gd")


var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _gs: Node = null
var _ci: Node = null
var _day: Node = null
var _overload: Node = null
var _db: Node = null
var _prog: Node = null
var _salary: Node = null
var _lge: Node = null
var _proj: RefCounted = null
var _wave_e: RefCounted = null
var _rivals: Node = null

var _president_a_sec: float = -1.0
var _president_b_sec: float = -1.0
var _president_c_sec: float = -1.0
var _stage6_no_up_sec: float = -1.0
var _stage6_events_sec: float = -1.0
var _combined_sec: float = -1.0
var _local_upgrade_sec: float = -1.0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_ci = get_node("/root/CloneIncremental")
	_day = get_node("/root/GameDay")
	_overload = get_node("/root/DatingOverload")
	_db = get_node("/root/ContentDB")
	_prog = get_node("/root/Progression")
	_salary = get_node("/root/SalaryMine")
	_lge = get_node("/root/LateGameExpansion")
	_rivals = get_node_or_null("/root/RivalEncounters")
	_proj = _BalanceProjectionScript.new()
	_wave_e = _BalanceWaveEChecksScript.new()
	await get_tree().process_frame
	if _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	await _run_all()
	_print_summary()
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
		print("MODULE_26_BALANCE PASS: %s" % label)
	else:
		_failed += 1
		push_error("[MODULE_26_BALANCE] FAIL: %s" % label)
		print("MODULE_26_BALANCE FAIL: %s" % label)


func _print_summary() -> void:
	print("MODULE_26_BALANCE MEASURED: PresidentA=%.1fs B=%.1fs C=%.1fs" % [
		_president_a_sec, _president_b_sec, _president_c_sec
	])
	print("MODULE_26_BALANCE MEASURED: Stage6NoUpgrade=%.1fs Stage6Events=%.1fs Combined=%.1fs LocalUpgrade30=%.1fs" % [
		_stage6_no_up_sec, _stage6_events_sec, _combined_sec, _local_upgrade_sec
	])
	if _failed == 0:
		DfLog.info("MODULE_26_BALANCE", "ALL PASS (%s)" % _passed)
		print("MODULE_26_BALANCE: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_26_BALANCE", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_26_BALANCE: FAIL passed=%s failed=%s" % [_passed, _failed])


func _run_all() -> void:
	_test_story_authority_ladder()
	_test_story_xp_gates()
	_test_perk_costs()
	_test_early_perk_budget()
	_test_salary_clean_values()
	_test_story_zero_money()
	_test_cooldown_ranges()
	_test_story_perfect_plus5_level0()
	_test_media_overload_ready_path()
	_test_story_no_perk_competitions()
	_test_president_bridge_strategies()
	_test_stage6_and_combined()
	_test_local_upgrade_afford()
	_test_rate_monotonicity()
	_test_save_schema()
	_gs.call("reset_for_new_game")


func _test_story_authority_ladder() -> void:
	var result: Dictionary = _proj.call("story_authority_ladder", _db) as Dictionary
	_ok(bool(result.get("ok", false)), "66 authority ladder loads")
	var ladder: Array = result.get("ladder", []) as Array
	var expected: Array[int] = [0, 2, 4, 7, 10, 15]
	_ok(ladder.size() == expected.size(), "66 ladder size %s" % ladder.size())
	var match_all: bool = true
	for i in range(mini(ladder.size(), expected.size())):
		if int(ladder[i]) != expected[i]:
			match_all = false
			print("MODULE_26_BALANCE DETAIL: ladder[%s]=%s expected=%s" % [i, ladder[i], expected[i]])
	_ok(match_all, "66 clean Authority 0→2→4→7→10→15")
	var details: Array = result.get("details", []) as Array
	var req_ok: bool = true
	var before: int = 0
	for d_v in details:
		var d: Dictionary = d_v as Dictionary
		if int(d.get("required_authority", -1)) != before:
			req_ok = false
			print("MODULE_26_BALANCE DETAIL: %s required=%s before=%s" % [
				String(d.get("id", &"")), d.get("required_authority", -1), before
			])
		before = int(d.get("after", before))
	_ok(req_ok, "66 story required_authority matches clean ladder")


func _test_story_xp_gates() -> void:
	var result: Dictionary = _proj.call("story_xp_gates", _db) as Dictionary
	_ok(bool(result.get("ok", false)), "70 xp gates load")
	var gates: Dictionary = result.get("gates", {}) as Dictionary
	var expected: Dictionary = {
		StoryIds.GIRL_NEIGHBOR: 0,
		StoryIds.GIRL_ACTRESS: 1,
		StoryIds.GIRL_MINE_BOSS: 2,
		StoryIds.GIRL_MAGAZINE_EDITOR: 3,
		StoryIds.GIRL_SCIENTIST: 4,
		StoryIds.GIRL_PRESIDENT: 10,
	}
	var gates_ok: bool = true
	for gid in expected.keys():
		var got: int = int(gates.get(gid, -999))
		var want: int = int(expected[gid])
		if got != want:
			gates_ok = false
			print("MODULE_26_BALANCE DETAIL: %s req_xp=%s expected=%s" % [String(gid), got, want])
	_ok(gates_ok, "70 Neighbor0…Scientist4 President10")
	_ok(int(result.get("clean_story_xp_through_scientist", -1)) == 5, "70 clean story XP through Scientist = 5")
	_ok(int(gates.get(StoryIds.GIRL_PRESIDENT, 0)) > 5, "70 President XP gap intentional (10 > 5)")


func _test_perk_costs() -> void:
	var costs_v: Variant = _proj.call("perk_costs_via_purchases", _prog, _gs)
	var costs: Array = costs_v as Array
	var expected: Array[int] = [1, 3, 9, 27, 81]
	_ok(costs.size() == expected.size(), "71 perk cost count %s" % costs.size())
	var match_all: bool = true
	for i in range(mini(costs.size(), expected.size())):
		if int(costs[i]) != expected[i]:
			match_all = false
	if not match_all:
		print("MODULE_26_BALANCE DETAIL: perk costs=%s expected=%s" % [str(costs), str(expected)])
	_ok(match_all, "71 perk costs 1/3/9/27/81 via Progression")


func _test_early_perk_budget() -> void:
	var result: Dictionary = _proj.call("early_perk_budget", _prog, _gs) as Dictionary
	if not bool(result.get("ok", false)):
		print("MODULE_26_BALANCE DETAIL: early perk %s" % str(result))
	_ok(bool(result.get("ok", false)), "72 early perk budget 5 UP → 1+3 remain1")


func _test_salary_clean_values() -> void:
	var cases: Array[Dictionary] = [
		{"auth": 0, "level": 1, "gross": 10},
		{"auth": 2, "level": 1, "gross": 10},
		{"auth": 3, "level": 2, "gross": 20},
		{"auth": 4, "level": 2, "gross": 20},
		{"auth": 7, "level": 3, "gross": 30},
		{"auth": 10, "level": 4, "gross": 40},
		{"auth": 15, "level": 6, "gross": 60},
	]
	var all_ok: bool = true
	for c in cases:
		var got: Dictionary = _proj.call("salary_at_authority", _salary, int(c["auth"])) as Dictionary
		if int(got["level"]) != int(c["level"]) or int(got["gross"]) != int(c["gross"]):
			all_ok = false
			print("MODULE_26_BALANCE DETAIL: salary auth=%s got=%s expected level=%s gross=%s" % [
				c["auth"], str(got), c["level"], c["gross"]
			])
	_ok(all_ok, "73 salary clean level=1+auth/3 gross=10*level")


func _test_story_zero_money() -> void:
	var result: Dictionary = _proj.call("story_requires_zero_money", _db) as Dictionary
	if not bool(result.get("ok", false)):
		var problems: Array = result.get("problems", []) as Array
		for p in problems:
			print("MODULE_26_BALANCE DETAIL: money gate: %s" % str(p))
	_ok(bool(result.get("ok", false)), "74 story requires zero Money (static)")


func _test_cooldown_ranges() -> void:
	var result: Dictionary = _proj.call("cooldown_ranges_from_source") as Dictionary
	_ok(bool(result.get("discovery_retry_1_to_3", false)), "75 discovery retry randi_range(1,3)")
	_ok(bool(result.get("date_cooldown_1_to_3", false)), "76 date cooldown randi_range(1,3)")


func _test_story_perfect_plus5_level0() -> void:
	var result: Dictionary = _wave_e.call("story_perfect_plus5_level0", _db) as Dictionary
	if not bool(result.get("ok", false)):
		for p in result.get("problems", []) as Array:
			print("MODULE_26_BALANCE DETAIL: story+5: %s" % str(p))
	for d_v in result.get("details", []) as Array:
		var d: Dictionary = d_v as Dictionary
		print(
			"MODULE_26_BALANCE DETAIL: story+5 %s best=%s plus5=%s trap=%s"
			% [String(d.get("id", &"")), d.get("best", -999), d.get("plus5", false), d.get("scandal_trap", false)]
		)
	_ok(bool(result.get("ok", false)), "77 Earth story girls level-0 +5 feasibility")


func _test_media_overload_ready_path() -> void:
	var result: Dictionary = _wave_e.call("media_overload_ready_path") as Dictionary
	if not bool(result.get("ok", false)):
		print("MODULE_26_BALANCE DETAIL: media path %s" % str(result))
	else:
		print(
			"MODULE_26_BALANCE DETAIL: media min path=%s attention=%s offers_at_45=%s"
			% [
				str(result.get("min_path", "")),
				int(result.get("min_path_attention", -1)),
				int(result.get("offers_at_gate", -1)),
			]
		)
	_ok(int(result.get("attention_gate", -1)) == 45, "Media OVERLOAD_READY_ATTENTION == 45")
	_ok(int(result.get("offers_gate", -1)) == 3, "Media OVERLOAD_READY_OFFERS == 3")
	_ok(bool(result.get("ok", false)), "Media min path Attention45 + offers>=3")


func _test_story_no_perk_competitions() -> void:
	var result: Dictionary = _wave_e.call(
		"story_no_perk_competitions", _db, _rivals, _gs
	) as Dictionary
	if not bool(result.get("ok", false)):
		for p in result.get("problems", []) as Array:
			print("MODULE_26_BALANCE DETAIL: no-perk: %s" % str(p))
	_ok(bool(result.get("ok", false)), "69 story rivals have base-unlocked competition")


func _test_president_bridge_strategies() -> void:
	var a: Dictionary = _proj.call(
		"simulate_president_bridge",
		_gs, _ci, _day, _overload, int(_BalanceProjectionScript.AssignStrategy.DATING_HEAVY)
	) as Dictionary
	_president_a_sec = float(a.get("seconds", -1.0))
	_report_budget("78 President A dating-heavy", a, float(_BalanceProjectionScript.PRESIDENT_BRIDGE_BUDGET_SEC))
	var b: Dictionary = _proj.call(
		"simulate_president_bridge",
		_gs, _ci, _day, _overload, int(_BalanceProjectionScript.AssignStrategy.BALANCED)
	) as Dictionary
	_president_b_sec = float(b.get("seconds", -1.0))
	_report_budget("78 President B balanced", b, float(_BalanceProjectionScript.PRESIDENT_BRIDGE_BUDGET_SEC))
	var c: Dictionary = _proj.call(
		"simulate_president_bridge",
		_gs, _ci, _day, _overload, int(_BalanceProjectionScript.AssignStrategy.THREE_WORKERS)
	) as Dictionary
	_president_c_sec = float(c.get("seconds", -1.0))
	_report_budget("78 President C 3-workers", c, float(_BalanceProjectionScript.PRESIDENT_BRIDGE_BUDGET_SEC))


func _test_stage6_and_combined() -> void:
	var conservative_strategy: int = int(_BalanceProjectionScript.AssignStrategy.DATING_HEAVY)
	var conservative_sec: float = _president_a_sec
	if _president_b_sec > conservative_sec:
		conservative_sec = _president_b_sec
		conservative_strategy = int(_BalanceProjectionScript.AssignStrategy.BALANCED)
	if _president_c_sec > conservative_sec:
		conservative_sec = _president_c_sec
		conservative_strategy = int(_BalanceProjectionScript.AssignStrategy.THREE_WORKERS)
	var bridge: Dictionary = _proj.call(
		"simulate_president_bridge", _gs, _ci, _day, _overload, conservative_strategy
	) as Dictionary
	var stage6: Dictionary = _proj.call("simulate_stage6_reach", _gs, _ci, _lge, false) as Dictionary
	_stage6_no_up_sec = float(stage6.get("seconds", -1.0))
	_report_budget(
		"80 Stage6 no-upgrade Reach100",
		stage6,
		float(_BalanceProjectionScript.STAGE6_NO_UPGRADE_BUDGET_SEC)
	)
	_combined_sec = float(bridge.get("seconds", 0.0)) + _stage6_no_up_sec
	var combined_ok: bool = (
		bool(bridge.get("reached", false))
		and bool(stage6.get("reached", false))
		and _combined_sec <= float(_BalanceProjectionScript.COMBINED_INCREMENTAL_BUDGET_SEC) + 0.001
	)
	if not combined_ok:
		print(
			"MODULE_26_BALANCE DETAIL: combined=%.1fs (bridge=%.1fs + stage6=%.1fs) budget=%.1fs strategy=%s"
			% [
				_combined_sec,
				float(bridge.get("seconds", -1.0)),
				_stage6_no_up_sec,
				float(_BalanceProjectionScript.COMBINED_INCREMENTAL_BUDGET_SEC),
				conservative_strategy,
			]
		)
	_ok(combined_ok, "83 combined required incremental <=900s (%.1fs)" % _combined_sec)
	_proj.call("simulate_president_bridge", _gs, _ci, _day, _overload, conservative_strategy)
	var stage6e: Dictionary = _proj.call("simulate_stage6_reach", _gs, _ci, _lge, true) as Dictionary
	_stage6_events_sec = float(stage6e.get("seconds", -1.0))
	_report_budget(
		"81 Stage6 optional events Reach100",
		stage6e,
		float(_BalanceProjectionScript.STAGE6_EVENTS_BUDGET_SEC)
	)


func _test_local_upgrade_afford() -> void:
	var result: Dictionary = _proj.call("simulate_local_first_upgrade_afford", _gs, _ci) as Dictionary
	_local_upgrade_sec = float(result.get("seconds", -1.0))
	_report_budget(
		"79 local upgrade first cost affordable",
		result,
		float(_BalanceProjectionScript.LOCAL_UPGRADE_AFFORD_BUDGET_SEC)
	)
	_ok(
		int(result.get("cost", -1)) == CloneIncrementalTypes.upgrade_cost(0),
		"79 first cost via Types"
	)


func _test_rate_monotonicity() -> void:
	var result: Dictionary = _proj.call("rate_monotonicity") as Dictionary
	if not bool(result.get("ok", false)):
		for p in result.get("problems", []) as Array:
			print("MODULE_26_BALANCE DETAIL: mono: %s" % str(p))
	_ok(bool(result.get("ok", false)), "84 upgrade rate monotonicity")


func _test_save_schema() -> void:
	_ok(int(_proj.call("save_schema_version")) == 1, "SAVE_SCHEMA_VERSION == 1")


func _report_budget(label: String, result: Dictionary, budget: float) -> void:
	var seconds: float = float(result.get("seconds", -1.0))
	var reached: bool = bool(result.get("reached", false))
	var within: bool = reached and seconds <= budget + 0.001
	if not within:
		print(
			"MODULE_26_BALANCE DETAIL: %s seconds=%.1f reached=%s budget=%.1f full=%s"
			% [label, seconds, reached, budget, str(result)]
		)
	_ok(within, "%s <=%.0fs (%.1fs)" % [label, budget, seconds])
