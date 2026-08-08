class_name BalanceProjection
extends RefCounted
## MODULE 26 test-only balance projection helper.
## Reads PRODUCTION constants/APIs — does not duplicate formula literals.


enum AssignStrategy {
	DATING_HEAVY = 0,
	BALANCED = 1,
	THREE_WORKERS = 2,
}


## Target budgets (test-only; production formulas stay in Types/services).
const PRESIDENT_BRIDGE_BUDGET_SEC: float = 390.0
const STAGE6_NO_UPGRADE_BUDGET_SEC: float = 480.0
const STAGE6_EVENTS_BUDGET_SEC: float = 390.0
const COMBINED_INCREMENTAL_BUDGET_SEC: float = 900.0
const LOCAL_UPGRADE_AFFORD_BUDGET_SEC: float = 90.0

const EARTH_STORY_RIVAL_IDS: Array[StringName] = [
	StoryIds.RIVAL_ACTRESS,
	StoryIds.RIVAL_MINE_BOSS,
	StoryIds.RIVAL_MAGAZINE_EDITOR,
	StoryIds.RIVAL_SCIENTIST,
	StoryIds.RIVAL_PRESIDENT,
]

const EARTH_STORY_GIRL_IDS: Array[StringName] = [
	StoryIds.GIRL_NEIGHBOR,
	StoryIds.GIRL_ACTRESS,
	StoryIds.GIRL_MINE_BOSS,
	StoryIds.GIRL_MAGAZINE_EDITOR,
	StoryIds.GIRL_SCIENTIST,
	StoryIds.GIRL_PRESIDENT,
]

const STORY_THROUGH_SCIENTIST_GIRL_IDS: Array[StringName] = [
	StoryIds.GIRL_NEIGHBOR,
	StoryIds.GIRL_ACTRESS,
	StoryIds.GIRL_MINE_BOSS,
	StoryIds.GIRL_MAGAZINE_EDITOR,
	StoryIds.GIRL_SCIENTIST,
]

var _assign_strategy: int = AssignStrategy.DATING_HEAVY
var _assign_toggle_work: bool = true
var _ci_ref: Node = null
var _gs_ref: Node = null
var _clone_produced_cb: Callable = Callable()


func story_authority_ladder(db: Node) -> Dictionary:
	var rewards: Array[int] = []
	var auth: int = 0
	var ladder: Array[int] = [0]
	var details: Array[Dictionary] = []
	for rid in EARTH_STORY_RIVAL_IDS:
		var def: RivalDefinition = db.call("get_rival", rid) as RivalDefinition
		if def == null:
			return {"ok": false, "error": "missing rival %s" % String(rid)}
		rewards.append(def.authority_reward)
		auth += def.authority_reward
		ladder.append(auth)
		details.append({
			"id": rid,
			"required_authority": def.required_authority,
			"authority_reward": def.authority_reward,
			"after": auth,
		})
	return {
		"ok": true,
		"ladder": ladder,
		"rewards": rewards,
		"details": details,
		"final_authority": auth,
	}


func story_xp_gates(db: Node) -> Dictionary:
	var gates: Dictionary = {}
	for gid in EARTH_STORY_GIRL_IDS:
		var girl: GirlDefinition = db.call("get_girl", gid) as GirlDefinition
		if girl == null:
			return {"ok": false, "error": "missing girl %s" % String(gid)}
		gates[gid] = girl.required_experience
	var clean_through_scientist: int = STORY_THROUGH_SCIENTIST_GIRL_IDS.size()
	return {
		"ok": true,
		"gates": gates,
		"clean_story_xp_through_scientist": clean_through_scientist,
	}


func perk_cost_sequence(prog: Node, count: int = 5) -> Array[int]:
	var out: Array[int] = []
	var gs: Node = prog.get_node_or_null("/root/GameState")
	if gs == null:
		return out
	gs.call("reset_for_new_game")
	for _i in range(count):
		out.append(int(prog.call("get_next_perk_cost")))
		# Advance purchase count without needing a specific purchasable perk tree walk:
		# mark a unique synthetic owned perk via GameState if available; else buy root.
		var owned: int = int(gs.call("get_purchased_perk_count"))
		var perk_id: StringName = &"balance_probe_perk_%d" % owned
		if gs.has_method("mark_perk_owned"):
			gs.call("mark_perk_owned", perk_id)
		elif gs.has_method("add_purchased_perk"):
			gs.call("add_purchased_perk", perk_id)
		else:
			# Fallback: grant UP and buy a real root perk when probing costs via Progression.
			break
	return out


func perk_costs_via_purchases(prog: Node, gs: Node) -> Array[int]:
	var costs: Array[int] = []
	gs.call("reset_for_new_game")
	var roots: Array[StringName] = [
		PerkIds.MUSCLE_NO_WARMUP,
		PerkIds.APPEARANCE_GOOD_PROFILE,
		PerkIds.CAPITAL_PAYABLE_INTENT,
		PerkIds.AURA_PRESENCE_REGISTERED,
	]
	# Need enough UP for first four costs 1+3+9+27=40, then observe 81.
	gs.call("add_experience", 200)
	for i in range(4):
		var cost: int = int(prog.call("get_next_perk_cost"))
		costs.append(cost)
		var result: int = int(prog.call("purchase_perk", roots[i]))
		if result != 0:
			# Progression.PerkPurchaseResult.SUCCESS == 0
			break
	costs.append(int(prog.call("get_next_perk_cost")))
	return costs


func early_perk_budget(prog: Node, gs: Node) -> Dictionary:
	gs.call("reset_for_new_game")
	gs.call("add_experience", 5)
	var up0: int = int(gs.call("get_upgrade_points"))
	var cost1: int = int(prog.call("get_next_perk_cost"))
	var buy1: int = int(prog.call("purchase_perk", PerkIds.MUSCLE_NO_WARMUP))
	var cost2: int = int(prog.call("get_next_perk_cost"))
	var buy2: int = int(prog.call("purchase_perk", PerkIds.APPEARANCE_GOOD_PROFILE))
	var remain: int = int(gs.call("get_upgrade_points"))
	var cost3: int = int(prog.call("get_next_perk_cost"))
	var can_third: bool = bool(gs.call("can_spend_upgrade_points", cost3))
	return {
		"ok": up0 == 5 and buy1 == 0 and buy2 == 0 and cost1 == 1 and cost2 == 3 and remain == 1 and cost3 == 9 and not can_third,
		"up_start": up0,
		"cost1": cost1,
		"cost2": cost2,
		"cost3": cost3,
		"remain": remain,
		"can_third": can_third,
	}


func salary_at_authority(salary: Node, authority: int) -> Dictionary:
	var level: int = int(salary.call("get_salary_level", authority))
	var gross: int = int(salary.call("get_gross_salary", authority))
	return {"authority": authority, "level": level, "gross": gross}


func story_requires_zero_money(db: Node) -> Dictionary:
	var problems: Array[String] = []
	# Discovery: no money field — require a free SUCCESS approach (level 0 / no req).
	for gid in EARTH_STORY_GIRL_IDS:
		var girl: GirlDefinition = db.call("get_girl", gid) as GirlDefinition
		if girl == null:
			problems.append("missing girl %s" % String(gid))
			continue
		var sit: DiscoverySituationDefinition = db.call(
			"get_discovery_situation", girl.discovery_situation_id
		) as DiscoverySituationDefinition
		if sit == null:
			problems.append("missing discovery %s" % String(girl.discovery_situation_id))
			continue
		var has_free_success: bool = false
		for approach in sit.approaches:
			if approach == null:
				continue
			if approach.outcome != DiscoveryApproachDefinition.DiscoveryApproachOutcome.SUCCESS:
				continue
			if approach.has_requirement and approach.required_level > 0:
				continue
			has_free_success = true
			break
		if not has_free_success:
			problems.append("discovery no free SUCCESS: %s" % String(gid))
		# Farewell: at least one money_cost==0 action.
		var farewell: DatingFarewellDefinition = db.call(
			"get_dating_farewell", girl.dating_farewell_id
		) as DatingFarewellDefinition
		if farewell == null:
			problems.append("missing farewell %s" % String(girl.dating_farewell_id))
		else:
			var free_farewell: bool = false
			for action in farewell.actions:
				if action != null and action.money_cost <= 0:
					free_farewell = true
					break
			if not free_farewell:
				problems.append("farewell requires money: %s" % String(girl.dating_farewell_id))
		# Story-specific dating pools: each event needs a free action option.
		for pool_id in girl.dating_pool_ids:
			var pool: DatingEventPoolDefinition = db.call("get_dating_pool", pool_id) as DatingEventPoolDefinition
			if pool == null:
				continue
			for eid in pool.event_ids:
				var event: DatingEventDefinition = db.call("get_dating_event", eid) as DatingEventDefinition
				if event == null:
					continue
				var free_action: bool = false
				for action in event.actions:
					if action != null and action.money_cost <= 0:
						free_action = true
						break
				if not free_action:
					problems.append("event all paid: %s" % String(eid))
	for rid in EARTH_STORY_RIVAL_IDS:
		var rival: RivalDefinition = db.call("get_rival", rid) as RivalDefinition
		if rival == null:
			problems.append("missing rival %s" % String(rid))
			continue
		var has_non_money: bool = false
		for ct in rival.allowed_competitions:
			if int(ct) != int(GameTypes.CompetitionType.MONEY):
				has_non_money = true
				break
		if not has_non_money:
			problems.append("rival MONEY-only: %s" % String(rid))
	return {"ok": problems.is_empty(), "problems": problems}


func cooldown_ranges_from_source() -> Dictionary:
	var gd_src: String = FileAccess.get_file_as_string("res://game/girls/girl_discovery.gd")
	var rel_src: String = FileAccess.get_file_as_string("res://game/relationships/relationships.gd")
	var discovery_ok: bool = gd_src.contains("randi_range(1, 3)")
	var date_ok: bool = rel_src.contains("randi_range(1, 3)")
	return {
		"ok": discovery_ok and date_ok,
		"discovery_retry_1_to_3": discovery_ok,
		"date_cooldown_1_to_3": date_ok,
	}


func seed_overload_backlog(gs: Node, day: Node, count: int) -> void:
	gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	if not bool(gs.call("is_dating_overload_started")):
		var d: int = int(day.call("get_current_day"))
		gs.call("mark_dating_overload_started", d)
	for i in range(count):
		var entry: DatingDemandEntry = DatingDemandEntry.new()
		entry.request_id = int(gs.call("allocate_dating_demand_request_id"))
		if i % 2 == 0:
			entry.girl_id = &"girl_appearance_flash"
		else:
			entry.girl_id = &"girl_public_sculpture"
		entry.created_day = int(day.call("get_current_day"))
		entry.appointment_day = int(day.call("get_current_day"))
		entry.slot = DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING
		entry.status = DatingOverloadTypes.DatingDemandStatus.WAITING
		entry.fulfilled_day = -1
		gs.call("append_dating_demand", entry)


func _bind_assign(ci: Node, gs: Node, strategy: int) -> void:
	_unbind_assign()
	_ci_ref = ci
	_gs_ref = gs
	_assign_strategy = strategy
	_assign_toggle_work = true
	_clone_produced_cb = Callable(self, "_handle_clone_produced")
	if ci.has_signal("clone_produced") and not ci.is_connected("clone_produced", _clone_produced_cb):
		ci.connect("clone_produced", _clone_produced_cb)


func _unbind_assign() -> void:
	if _ci_ref != null and _clone_produced_cb.is_valid():
		if _ci_ref.has_signal("clone_produced") and _ci_ref.is_connected("clone_produced", _clone_produced_cb):
			_ci_ref.disconnect("clone_produced", _clone_produced_cb)
	_ci_ref = null
	_gs_ref = null
	_clone_produced_cb = Callable()


func _handle_clone_produced(_new_total: int) -> void:
	_assign_one_free_by_strategy()


func _assign_one_free_by_strategy() -> void:
	if _ci_ref == null or _gs_ref == null:
		return
	if int(_gs_ref.call("get_free_clones")) <= 0:
		return
	match _assign_strategy:
		AssignStrategy.DATING_HEAVY:
			_ci_ref.call("assign_one_to_dating")
		AssignStrategy.BALANCED:
			if _assign_toggle_work:
				_ci_ref.call("assign_one_to_work")
			else:
				_ci_ref.call("assign_one_to_dating")
			_assign_toggle_work = not _assign_toggle_work
		AssignStrategy.THREE_WORKERS:
			var working: int = int(_gs_ref.call("get_clones_working"))
			if working < 3:
				_ci_ref.call("assign_one_to_work")
			else:
				_ci_ref.call("assign_one_to_dating")
		_:
			_ci_ref.call("assign_one_to_dating")


func _assign_initial_first_clone(ci: Node, gs: Node, strategy: int) -> void:
	if int(gs.call("get_free_clones")) <= 0:
		return
	match strategy:
		AssignStrategy.DATING_HEAVY:
			# Spec A: first clone Work; later clones Dating (via signal).
			ci.call("assign_one_to_work")
		AssignStrategy.BALANCED:
			_assign_toggle_work = true
			ci.call("assign_one_to_work")
			_assign_toggle_work = false
		AssignStrategy.THREE_WORKERS:
			ci.call("assign_one_to_work")
		_:
			ci.call("assign_one_to_work")


func setup_president_bridge_start(gs: Node, ci: Node, day: Node, overload: Node) -> void:
	gs.call("reset_for_new_game")
	ci.call("set_realtime_simulation", false)
	gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	gs.call("add_experience", 5)
	# Ensure backlog exactly 4 waiting demands.
	while int(overload.call("get_backlog_count")) > 0:
		overload.call("fulfill_oldest_demand_by_clone")
	seed_overload_backlog(gs, day, 4)
	gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	gs.call("set_clone_counts", 1, 0, 0)
	# Local upgrades stay 0 after reset.
	ci.call("recalculate_rates")


func simulate_president_bridge(
	gs: Node,
	ci: Node,
	day: Node,
	overload: Node,
	strategy: int,
	hard_cap_sec: float = -1.0
) -> Dictionary:
	var cap: float = hard_cap_sec
	if cap < 0.0:
		cap = PRESIDENT_BRIDGE_BUDGET_SEC * 2.0
	setup_president_bridge_start(gs, ci, day, overload)
	_bind_assign(ci, gs, strategy)
	_assign_initial_first_clone(ci, gs, strategy)
	var elapsed: float = 0.0
	var step: float = 1.0
	while elapsed < cap and int(gs.call("get_experience")) < 10:
		ci.call("advance_simulation_for_test", step)
		elapsed += step
	_unbind_assign()
	var xp: int = int(gs.call("get_experience"))
	var reached: bool = xp >= 10
	return {
		"ok": reached and elapsed <= PRESIDENT_BRIDGE_BUDGET_SEC + 0.001,
		"reached": reached,
		"seconds": elapsed,
		"experience": xp,
		"budget": PRESIDENT_BRIDGE_BUDGET_SEC,
		"strategy": strategy,
		"clones": int(gs.call("get_total_clones")),
		"working": int(gs.call("get_clones_working")),
		"dating": int(gs.call("get_clones_dating")),
		"backlog": int(overload.call("get_backlog_count")),
	}


func enter_stage6_from_bridge_snapshot(gs: Node, ci: Node) -> void:
	gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	gs.call("set_world_reach", 0)
	# Keep clone counts / local levels from bridge; clear free into dating.
	ci.call("assign_all_free_to_dating")
	ci.call("recalculate_rates")


func simulate_stage6_reach(
	gs: Node,
	ci: Node,
	lge: Node,
	use_events: bool,
	hard_cap_sec: float = -1.0
) -> Dictionary:
	var budget: float = STAGE6_EVENTS_BUDGET_SEC if use_events else STAGE6_NO_UPGRADE_BUDGET_SEC
	var cap: float = hard_cap_sec
	if cap < 0.0:
		cap = budget * 2.0
	enter_stage6_from_bridge_snapshot(gs, ci)
	_bind_assign(ci, gs, AssignStrategy.DATING_HEAVY)
	# All new free → Dating (strategy DATING_HEAVY without first-work exception).
	var elapsed: float = 0.0
	var step: float = 1.0
	while elapsed < cap and int(gs.call("get_world_reach")) < LateGameTypes.WORLD_REACH_MAX:
		ci.call("advance_simulation_for_test", step)
		elapsed += step
		if use_events:
			_try_complete_all_available_events(lge)
	_unbind_assign()
	var reach: int = int(gs.call("get_world_reach"))
	var reached: bool = reach >= LateGameTypes.WORLD_REACH_MAX
	return {
		"ok": reached and elapsed <= budget + 0.001,
		"reached": reached,
		"seconds": elapsed,
		"reach": reach,
		"budget": budget,
		"use_events": use_events,
		"clones": int(gs.call("get_total_clones")),
	}


func _try_complete_all_available_events(lge: Node) -> void:
	var events: Array[int] = [
		int(LateGameTypes.OptionalEvent.CUSTOMS),
		int(LateGameTypes.OptionalEvent.WORLD_ROUTE),
		int(LateGameTypes.OptionalEvent.LAST_CONTINENT),
	]
	for ev in events:
		if bool(lge.call("is_optional_event_available", ev)):
			lge.call("complete_optional_event", ev)


func simulate_local_first_upgrade_afford(gs: Node, ci: Node, hard_cap_sec: float = -1.0) -> Dictionary:
	var cap: float = hard_cap_sec
	if cap < 0.0:
		cap = LOCAL_UPGRADE_AFFORD_BUDGET_SEC * 2.0
	var cost: int = CloneIncrementalTypes.upgrade_cost(0)
	gs.call("reset_for_new_game")
	ci.call("set_realtime_simulation", false)
	gs.call("set_clone_counts", 1, 1, 0)
	ci.call("recalculate_rates")
	var elapsed: float = 0.0
	var step: float = 1.0
	while elapsed < cap and int(gs.call("get_money")) < cost:
		ci.call("advance_simulation_for_test", step)
		elapsed += step
	var money: int = int(gs.call("get_money"))
	var reached: bool = money >= cost
	return {
		"ok": reached and elapsed <= LOCAL_UPGRADE_AFFORD_BUDGET_SEC + 0.001,
		"reached": reached,
		"seconds": elapsed,
		"money": money,
		"cost": cost,
		"budget": LOCAL_UPGRADE_AFFORD_BUDGET_SEC,
	}


func rate_monotonicity() -> Dictionary:
	var problems: Array[String] = []
	var prev_interval: float = CloneIncrementalTypes.production_interval(0)
	var prev_money: float = CloneIncrementalTypes.money_per_minute_per_clone(0)
	var prev_dates: float = CloneIncrementalTypes.dates_per_minute_per_clone(0)
	for lvl in range(1, CloneIncrementalTypes.MAX_LEVEL + 1):
		var interval: float = CloneIncrementalTypes.production_interval(lvl)
		var money: float = CloneIncrementalTypes.money_per_minute_per_clone(lvl)
		var dates: float = CloneIncrementalTypes.dates_per_minute_per_clone(lvl)
		if not (interval < prev_interval):
			problems.append("local production L%s interval not better" % lvl)
		if not (money > prev_money):
			problems.append("local work L%s money not better" % lvl)
		if not (dates > prev_dates):
			problems.append("local dating L%s dates not better" % lvl)
		prev_interval = interval
		prev_money = money
		prev_dates = dates
	var prev_mult: float = LateGameTypes.multiplier_for_level(0)
	for lvl in range(1, LateGameTypes.MAX_LEVEL + 1):
		var mult: float = LateGameTypes.multiplier_for_level(lvl)
		if not (mult > prev_mult):
			problems.append("global mult L%s not better" % lvl)
		prev_mult = mult
	# Effective production interval decreases with global multiplier at fixed local level.
	var local_interval: float = CloneIncrementalTypes.production_interval(0)
	var prev_eff: float = local_interval / LateGameTypes.multiplier_for_level(0)
	for lvl in range(1, LateGameTypes.MAX_LEVEL + 1):
		var eff: float = local_interval / LateGameTypes.multiplier_for_level(lvl)
		eff = maxf(eff, LateGameTypes.MIN_EFFECTIVE_PRODUCTION_INTERVAL)
		var prev_clamped: float = maxf(prev_eff, LateGameTypes.MIN_EFFECTIVE_PRODUCTION_INTERVAL)
		if eff > prev_clamped + 0.0001 and not is_equal_approx(eff, prev_clamped):
			# Allow floor clamp equality at min interval; otherwise must improve.
			if not (eff < prev_eff):
				problems.append("global production effective L%s not better" % lvl)
		prev_eff = eff
	return {"ok": problems.is_empty(), "problems": problems}


func save_schema_version() -> int:
	return SaveTypes.SAVE_SCHEMA_VERSION
