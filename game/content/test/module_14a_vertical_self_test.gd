extends Node
## MODULE 14A early vertical-slice integration self-test (§§41–47).
## Run: res://game/content/test/module_14a_vertical_test.tscn --quit-after 40000

var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _db: Node = null
var _dc: Node = null
var _rel: Node = null
var _story: Node = null
var _day: Node = null
var _salary: Node = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_db = get_node("/root/ContentDB")
	_dc = get_node("/root/DatingCore")
	_rel = get_node("/root/Relationships")
	_story = get_node("/root/Story")
	_day = get_node_or_null("/root/GameDay")
	_salary = get_node_or_null("/root/SalaryMine")
	await get_tree().process_frame
	_rel.call("set_auto_apply_enabled", false)
	_dc.call("set_external_resolver", Callable(self, "_external_success"))
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_14A_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_14A_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_14A_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_14A_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_14A_TEST] FAIL: %s" % label)
		print("MODULE_14A_TEST FAIL: %s" % label)


func _external_success(req: DatingActionExecutionRequest) -> DatingActionExecutionResult:
	var out := DatingActionExecutionResult.new()
	out.outcome = DatingTypes.ExecutionOutcome.SUCCESS
	out.has_tag_override = false
	out.tags = []
	out.was_public = false
	out.result_text = "ok"
	if req != null:
		out.was_public = req.is_public
	return out


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_dc.call("force_clear_session")
	_rel.call("set_auto_apply_enabled", false)
	_rel.call("clear_applied_date_ids")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	_dc.call("set_rng", rng)
	_rel.call("set_rng", rng)


func _run_all() -> void:
	_test_validate_all()
	_test_phone_status_and_story()
	_test_plus5_story_girls()
	_test_repeat_date_feasibility()
	_test_money_softlock()
	_test_stage_progression_skeleton()
	_test_reset_cleanliness()
	_reset()


func _test_validate_all() -> void:
	var result: Dictionary = _db.call("validate_all") as Dictionary
	_ok(bool(result.get("ok", false)), "ContentDB validate_all ok")
	if not bool(result.get("ok", false)):
		for e in result.get("errors", []):
			print("MODULE_14A_TEST validate error: %s" % str(e))
	var girls: Array = _db.call("list_girls") as Array
	var rivals: Array = _db.call("list_rivals") as Array
	var events: Array = _db.call("list_dating_events") as Array
	var pools: Array = _db.call("list_dating_pools") as Array
	var greetings: Array = _db.call("list_dating_greetings") as Array
	var farewells: Array = _db.call("list_dating_farewells") as Array
	var situations: Array = _db.call("list_discovery_situations") as Array
	_ok(girls.size() == 23, "23 girls")
	_ok(rivals.size() == 19, "19 rivals")
	_ok(events.size() >= 22, "dating events >= 22")
	_ok(pools.size() >= 6, "dating pools >= 6")
	_ok(greetings.size() >= 4, "greetings >= 4")
	_ok(farewells.size() >= 1, "farewells >= 1")
	_ok(situations.size() == 22, "22 discovery situations")
	for pool_id in [
		&"date_pool_apartment_common",
		&"date_pool_neighbor",
		&"date_pool_cafe_common",
		&"date_pool_actress",
		&"date_pool_mine_boss",
	]:
		var pool: DatingEventPoolDefinition = _db.call("get_dating_pool", pool_id) as DatingEventPoolDefinition
		_ok(pool != null, "pool %s exists" % String(pool_id))


func _test_phone_status_and_story() -> void:
	_reset()
	var journal_scene: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	var journal: PhoneJournal = journal_scene.instantiate() as PhoneJournal
	add_child(journal)
	await get_tree().process_frame
	journal.open()
	var status: String = journal.get_status_text()
	_ok(status.contains("День:"), "phone status day")
	_ok(status.contains("Деньги:"), "phone status money")
	_ok(status.contains("Авторитет:"), "phone status authority")
	_ok(status.contains("Покоренных сердец:"), "phone status experience")
	_ok(status.contains("Баллы прокачки:"), "phone status upgrade points")
	var story_text: String = journal.get_story_text()
	_ok(story_text.contains("Ухажёр:"), "phone story rival line")
	_ok(story_text.contains("Девушка:"), "phone story girl line")
	_ok(story_text.contains("Соседка") or story_text.contains("girl_neighbor"), "phone story neighbor")
	journal.close()
	journal.queue_free()


func _make_request(girl: GirlDefinition, seed: int) -> DatingStartRequest:
	var req := DatingStartRequest.new()
	req.girl_id = girl.id
	req.location_id = girl.default_date_location_id
	req.greeting_ids = girl.dating_greeting_ids.duplicate()
	req.farewell_id = girl.dating_farewell_id
	req.rng_seed = seed
	return req


func _boost_for_ideal_date() -> void:
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 5)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 5)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 5)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 5)
	_gs.call("add_money", 500)


func _pick_best_greeting(girl: GirlDefinition) -> StringName:
	var best_id: StringName = girl.dating_greeting_ids[0]
	var best_score: int = -999
	for gid in girl.dating_greeting_ids:
		var def: DatingGreetingDefinition = _db.call("get_dating_greeting", gid) as DatingGreetingDefinition
		if def == null:
			continue
		var score: int = PrimaryTraitEvaluator.evaluate(girl.primary_trait, def.direct_tags)
		if score > best_score:
			best_score = score
			best_id = gid
	return best_id


func _available_action_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	var choices: Array = _dc.call("list_action_choices") as Array
	for entry in choices:
		var d: Dictionary = entry as Dictionary
		if bool(d.get("available", false)):
			out.append(d.get("id", &"") as StringName)
	return out


func _select_action_resolved(action_id: StringName) -> bool:
	var res: Dictionary = _dc.call("select_action", action_id) as Dictionary
	if bool(res.get("encore", false)):
		var encore_res: Dictionary = _dc.call("resolve_encore", false) as Dictionary
		return bool(encore_res.get("ok", false)) or encore_res.has("result")
	if bool(res.get("waiting", false)):
		var ext := DatingActionExecutionResult.new()
		ext.outcome = DatingTypes.ExecutionOutcome.SUCCESS
		ext.has_tag_override = false
		ext.tags = []
		ext.was_public = false
		var sub: Dictionary = _dc.call("submit_action_execution_result", ext) as Dictionary
		return bool(sub.get("ok", false)) or sub.has("result")
	return bool(res.get("ok", false)) or res.has("result")


func _play_ideal_date(girl_id: StringName, seed: int) -> DatingResult:
	var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
	if girl == null:
		return null
	_reset()
	_boost_for_ideal_date()
	_gs.call("mark_girl_discovered", girl_id)
	_gs.call("add_girl_contact", girl_id)
	var req: DatingStartRequest = _make_request(girl, seed)
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	if not bool(start.get("ok", false)):
		return null
	_dc.call("continue_arrival")
	_dc.call("select_greeting", _pick_best_greeting(girl))
	return _search_actions_for_plus5(girl)


func _search_actions_for_plus5(girl: GirlDefinition) -> DatingResult:
	var session: DatingSession = _dc.call("get_session") as DatingSession
	if session == null:
		return null
	var planned: Array[StringName] = session.central_event_ids.duplicate()
	var greeting_id: StringName = session.selected_greeting_id
	var location_id: StringName = session.location_id
	var girl_id: StringName = girl.id
	var ids: Array[StringName] = _available_action_ids()
	return _search_prefix(girl_id, location_id, greeting_id, planned, [], ids)


func _search_prefix(
	girl_id: StringName,
	location_id: StringName,
	greeting_id: StringName,
	planned: Array[StringName],
	prefix: Array[StringName],
	next_choices: Array[StringName],
) -> DatingResult:
	if prefix.size() == 4:
		return _replay_scripted(girl_id, location_id, greeting_id, planned, prefix)
	var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
	var ordered: Array[Dictionary] = []
	for aid in next_choices:
		var action: DatingActionDefinition = _dc.call("find_dating_action", aid) as DatingActionDefinition
		var score: int = 0
		if action != null and girl != null:
			score = PrimaryTraitEvaluator.evaluate(girl.primary_trait, action.direct_tags)
		ordered.append({"id": aid, "score": score})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]))
	for item in ordered:
		var aid: StringName = item["id"] as StringName
		var next_prefix: Array[StringName] = prefix.duplicate()
		next_prefix.append(aid)
		var trial: DatingResult = _replay_scripted(girl_id, location_id, greeting_id, planned, next_prefix)
		if trial != null and next_prefix.size() == 4:
			if trial.date_delta >= 5:
				return trial
			continue
		# Advance one step to discover next choices.
		_reset()
		_boost_for_ideal_date()
		_gs.call("mark_girl_discovered", girl_id)
		_gs.call("add_girl_contact", girl_id)
		var req: DatingStartRequest = DatingStartRequest.new()
		req.girl_id = girl_id
		req.location_id = location_id
		var gdef: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
		req.greeting_ids = gdef.dating_greeting_ids.duplicate()
		req.farewell_id = gdef.dating_farewell_id
		req.rng_seed = 1
		var start: Dictionary = _dc.call("start_date", req) as Dictionary
		if not bool(start.get("ok", false)):
			continue
		var s: DatingSession = _dc.call("get_session") as DatingSession
		s.central_event_ids = planned.duplicate()
		_dc.call("continue_arrival")
		_dc.call("select_greeting", greeting_id)
		var ok_prefix: bool = true
		for step_id in next_prefix:
			if not _select_action_resolved(step_id):
				ok_prefix = false
				break
		if not ok_prefix:
			continue
		var s2: DatingSession = _dc.call("get_session") as DatingSession
		if s2 != null and s2.finished and s2.result != null:
			if s2.result.date_delta >= 5:
				return s2.result
			continue
		var child: DatingResult = _search_prefix(
			girl_id,
			location_id,
			greeting_id,
			planned,
			next_prefix,
			_available_action_ids(),
		)
		if child != null:
			return child
	return null


func _replay_scripted(
	girl_id: StringName,
	location_id: StringName,
	greeting_id: StringName,
	planned: Array[StringName],
	action_ids: Array[StringName],
) -> DatingResult:
	_reset()
	_boost_for_ideal_date()
	_gs.call("mark_girl_discovered", girl_id)
	_gs.call("add_girl_contact", girl_id)
	var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
	var req: DatingStartRequest = DatingStartRequest.new()
	req.girl_id = girl_id
	req.location_id = location_id
	req.greeting_ids = girl.dating_greeting_ids.duplicate()
	req.farewell_id = girl.dating_farewell_id
	req.rng_seed = 1
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	if not bool(start.get("ok", false)):
		return null
	var s: DatingSession = _dc.call("get_session") as DatingSession
	s.central_event_ids = planned.duplicate()
	_dc.call("continue_arrival")
	_dc.call("select_greeting", greeting_id)
	for aid in action_ids:
		if not _select_action_resolved(aid):
			return null
	var s2: DatingSession = _dc.call("get_session") as DatingSession
	if s2 == null:
		return null
	return s2.result


func _forced_plans_for_girl(girl_id: StringName) -> Array:
	var out: Array = []
	match girl_id:
		StoryIds.GIRL_NEIGHBOR:
			out.append([
				&"date_event_apartment_laminate",
				&"date_event_apartment_chair",
				&"date_event_apartment_mug_rule",
			] as Array[StringName])
			out.append([
				&"date_event_apartment_neighbor_noise",
				&"date_event_apartment_chair",
				&"date_event_apartment_balcony",
			] as Array[StringName])
		StoryIds.GIRL_ACTRESS:
			out.append([
				&"date_event_cafe_attention",
				&"date_event_cafe_queue",
				&"date_event_actress_spotlight",
			] as Array[StringName])
		StoryIds.GIRL_MINE_BOSS:
			# THRILL+CONSISTENT: need AURA liked path into farewell SPONTANEITY.
			out.append([
				&"date_event_cafe_rule",
				&"date_event_cafe_queue",
				&"date_event_cafe_dessert_first",
			] as Array[StringName])
			out.append([
				&"date_event_cafe_rule",
				&"date_event_cafe_queue",
				&"date_event_mine_boss_risk_route",
			] as Array[StringName])
			out.append([
				&"date_event_cafe_rule",
				&"date_event_cafe_spill",
				&"date_event_cafe_statue",
			] as Array[StringName])
	return out


func _play_forced_plan(girl_id: StringName, planned: Array[StringName]) -> DatingResult:
	var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
	if girl == null:
		return null
	_reset()
	_boost_for_ideal_date()
	_gs.call("mark_girl_discovered", girl_id)
	_gs.call("add_girl_contact", girl_id)
	var req: DatingStartRequest = _make_request(girl, 7)
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	if not bool(start.get("ok", false)):
		return null
	var session: DatingSession = _dc.call("get_session") as DatingSession
	session.central_event_ids = planned.duplicate()
	_dc.call("continue_arrival")
	var greeting_id: StringName = _pick_best_greeting(girl)
	_dc.call("select_greeting", greeting_id)
	return _search_actions_for_plus5(girl)


func _test_plus5_story_girls() -> void:
	for girl_id in [StoryIds.GIRL_ACTRESS, StoryIds.GIRL_MINE_BOSS]:
		var reached: bool = false
		var best_delta: int = -999
		for seed in range(1, 21):
			var result: DatingResult = _play_ideal_date(girl_id, seed)
			if result == null:
				continue
			if result.date_delta > best_delta:
				best_delta = result.date_delta
			if result.date_delta >= 5:
				reached = true
				break
		if not reached:
			for plan_variant in _forced_plans_for_girl(girl_id):
				var planned: Array[StringName] = []
				for eid in plan_variant as Array:
					planned.append(eid as StringName)
				var forced: DatingResult = _play_forced_plan(girl_id, planned)
				if forced == null:
					continue
				if forced.date_delta > best_delta:
					best_delta = forced.date_delta
				if forced.date_delta >= 5:
					reached = true
					break
		_ok(reached, "+5 feasible %s (best=%s)" % [String(girl_id), best_delta])


func _test_repeat_date_feasibility() -> void:
	for girl_id in [
		StoryIds.GIRL_ACTRESS,
		StoryIds.GIRL_MINE_BOSS,
		&"girl_cafe_laptop",
	]:
		var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
		_ok(girl != null, "repeat girl exists %s" % String(girl_id))
		if girl == null:
			continue
		_reset()
		_boost_for_ideal_date()
		_gs.call("mark_girl_discovered", girl_id)
		_gs.call("add_girl_contact", girl_id)
		var req1: DatingStartRequest = _make_request(girl, 11)
		var start1: Dictionary = _dc.call("start_date", req1) as Dictionary
		_ok(bool(start1.get("ok", false)), "first date plan %s" % String(girl_id))
		if not bool(start1.get("ok", false)):
			continue
		var session1: DatingSession = _dc.call("get_session") as DatingSession
		var first_events: Array[StringName] = session1.central_event_ids.duplicate()
		_ok(first_events.size() == 3, "first date 3 events %s" % String(girl_id))
		_gs.call("record_girl_played_dating_events", girl_id, first_events)
		_dc.call("force_clear_session")
		var req2: DatingStartRequest = _make_request(girl, 17)
		var start2: Dictionary = _rel.call("start_date_with_history", req2) as Dictionary
		_ok(bool(start2.get("ok", false)), "second date plan %s" % String(girl_id))
		if not bool(start2.get("ok", false)):
			print("MODULE_14A_TEST second-date error %s: %s" % [String(girl_id), str(start2.get("error", &""))])
			continue
		var session2: DatingSession = _dc.call("get_session") as DatingSession
		var second_events: Array[StringName] = session2.central_event_ids.duplicate()
		var reused: int = 0
		for eid in second_events:
			if first_events.has(eid):
				reused += 1
		_ok(reused == 0, "no immediate reuse %s" % String(girl_id))
		_dc.call("force_clear_session")


func _action_available_at_baseline(action: DatingActionDefinition) -> bool:
	if action == null:
		return false
	if action.required_characteristic_level > 0:
		return false
	if action.money_cost > 0:
		return false
	if String(action.required_perk_id) != "":
		return false
	return true


func _test_money_softlock() -> void:
	var events: Array = _db.call("list_dating_events") as Array
	_ok(not events.is_empty(), "production events present")
	for entry in events:
		var ev: DatingEventDefinition = entry as DatingEventDefinition
		if ev == null:
			continue
		var any_ok: bool = false
		for action in ev.actions:
			if _action_available_at_baseline(action):
				any_ok = true
				break
		_ok(any_ok, "money softlock free action %s" % String(ev.id))


func _test_stage_progression_skeleton() -> void:
	_reset()
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.PROLOGUE), "start PROLOGUE")
	_gs.call("set_story_flag", StoryIds.FLAG_TUTORIAL_DATE_COMPLETE, true)
	_ok(
		int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_1),
		"tutorial milestone -> STAGE_1",
	)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_ACTRESS)
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_1), "rival alone keeps STAGE_1")
	_gs.call("mark_girl_conquered", StoryIds.GIRL_ACTRESS)
	_ok(bool(_story.call("reconcile_current_stage")), "actress -> STAGE_2")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_2), "STAGE_2")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MINE_BOSS)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_MINE_BOSS)
	_ok(bool(_story.call("reconcile_current_stage")), "mine boss -> STAGE_3")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_3), "STAGE_3")
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE)), "SALARY_MINE unlocked")
	var result := DatingResult.new()
	result.date_id = 9001
	result.girl_id = &"girl_city_bicycle"
	result.location_id = &"cafe"
	result.central_event_ids = [&"date_event_cafe_attention", &"date_event_cafe_spill", &"date_event_cafe_queue"]
	result.date_delta = 5
	_gs.call("mark_girl_discovered", &"girl_city_bicycle")
	_gs.call("add_girl_contact", &"girl_city_bicycle")
	var applied: RelationshipDateResult = _rel.call("apply_date_result", result) as RelationshipDateResult
	_ok(applied != null and applied.ok, "ordinary +5 apply")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_3), "ordinary girl does not change stage")


func _test_reset_cleanliness() -> void:
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_2)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_ACTRESS)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MINE_BOSS)
	_gs.call("mark_girl_discovered", StoryIds.GIRL_ACTRESS)
	_gs.call("add_girl_contact", StoryIds.GIRL_ACTRESS)
	_gs.call("set_girl_relationship", StoryIds.GIRL_ACTRESS, 3)
	_gs.call("add_money", 40)
	if _day != null and _day.has_method("advance_day"):
		_day.call("advance_day")
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.PROLOGUE), "reset stage PROLOGUE")
	if _day != null and _day.has_method("get_current_day"):
		_ok(int(_day.call("get_current_day")) == 1, "reset GameDay 1")
	else:
		_ok(true, "reset GameDay skipped")
	_ok(not bool(_gs.call("is_rival_defeated", StoryIds.RIVAL_ACTRESS)), "reset rival actress undefeated")
	_ok(not bool(_gs.call("is_rival_defeated", StoryIds.RIVAL_MINE_BOSS)), "reset rival mine undefeated")
	var contacts: Array = _gs.call("get_girl_contact_ids") as Array if _gs.has_method("get_girl_contact_ids") else []
	if _gs.has_method("get_girl_contact_ids"):
		_ok(contacts.is_empty(), "reset contacts empty")
	else:
		_ok(not bool(_gs.call("has_girl_contact", StoryIds.GIRL_ACTRESS)), "reset no actress contact")
	_ok(int(_gs.call("get_girl_relationship", StoryIds.GIRL_ACTRESS)) == 0, "reset relationships 0")
	_ok(int(_gs.call("get_money")) == 0, "reset money 0")
	_ok(
		not bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_NEIGHBOR)),
		"friend-only Neighbor is not a story romance spawn",
	)
	_ok(not bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_ACTRESS)), "reset actress absent")
	_ok(not bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_MINE_BOSS)), "reset mine boss absent")
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE)), "reset salary locked")
