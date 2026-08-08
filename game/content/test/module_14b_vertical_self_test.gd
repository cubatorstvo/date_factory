extends Node
## MODULE 14B Editor & Pre-Media vertical-slice integration self-test (§§13,36–44).
## Run: res://game/content/test/module_14b_vertical_test.tscn --quit-after 50000

var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _db: Node = null
var _dc: Node = null
var _rel: Node = null
var _story: Node = null
var _day: Node = null
var _re: Node = null
var _fake_runner: RivalFakeCompetitionRunner = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_db = get_node("/root/ContentDB")
	_dc = get_node("/root/DatingCore")
	_rel = get_node("/root/Relationships")
	_story = get_node("/root/Story")
	_day = get_node_or_null("/root/GameDay")
	_re = get_node("/root/RivalEncounters")
	await get_tree().process_frame
	_rel.call("set_auto_apply_enabled", false)
	_dc.call("set_external_resolver", Callable(self, "_external_success"))
	_fake_runner = RivalFakeCompetitionRunner.new()
	_fake_runner.attach(_re)
	await _run_all()
	if _fake_runner != null:
		_fake_runner.restore_production_runner()
	if _failed == 0:
		DfLog.info("MODULE_14B_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_14B_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_14B_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_14B_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_14B_TEST] FAIL: %s" % label)
		print("MODULE_14B_TEST FAIL: %s" % label)


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
	_re.call("force_clear_session")
	_rel.call("set_auto_apply_enabled", false)
	_rel.call("clear_applied_date_ids")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	_dc.call("set_rng", rng)
	_rel.call("set_rng", rng)
	if _fake_runner != null:
		_fake_runner.reset_counts()
		_fake_runner.auto_submit = true
		_fake_runner.set_forced(
			GameTypes.RivalCompetitionOutcome.PLAYER_WIN,
			GameTypes.VictoryGrade.CLOSE,
		)


func _run_all() -> void:
	_test_validate_and_counts()
	await _test_editor_plus5_and_minus2()
	_test_editor_rival_money_and_win()
	await _test_editor_completion_stage4()
	await _test_stage4_scientist_safety_and_phone()
	_test_try_get_scientist_present()
	_test_reset_cleanliness()
	_test_repeat_date_new_girls()
	_reset()


func _test_validate_and_counts() -> void:
	var result: Dictionary = _db.call("validate_all") as Dictionary
	_ok(bool(result.get("ok", false)), "ContentDB validate_all ok")
	if not bool(result.get("ok", false)):
		for e in result.get("errors", []):
			print("MODULE_14B_TEST validate error: %s" % str(e))
	var girls: Array = _db.call("list_girls") as Array
	var rivals: Array = _db.call("list_rivals") as Array
	var situations: Array = _db.call("list_discovery_situations") as Array
	var pools: Array = _db.call("list_dating_pools") as Array
	_ok(girls.size() == 14, "14 girls")
	_ok(rivals.size() == 14, "14 rivals")
	_ok(situations.size() == 13, "13 discovery situations")
	var editor_pool: DatingEventPoolDefinition = _db.call("get_dating_pool", &"date_pool_magazine_editor") as DatingEventPoolDefinition
	_ok(editor_pool != null, "date_pool_magazine_editor exists")
	_ok(pools.size() >= 6, "dating pools >= 6")
	for gid in [
		StoryIds.GIRL_MAGAZINE_EDITOR,
		&"girl_public_sculpture",
		&"girl_cafe_receipt_notes",
		&"girl_appearance_flash",
	]:
		_ok(_db.call("get_girl", gid) != null, "girl present %s" % String(gid))
	for rid in [
		StoryIds.RIVAL_MAGAZINE_EDITOR,
		&"rival_public_coat",
		&"rival_public_watch",
		&"rival_appearance_tripod",
	]:
		_ok(_db.call("get_rival", rid) != null, "rival present %s" % String(rid))


func _boost_for_ideal_date() -> void:
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 5)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 5)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 5)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 5)
	_gs.call("add_money", 500)


func _make_request(girl: GirlDefinition, seed: int) -> DatingStartRequest:
	var req := DatingStartRequest.new()
	req.girl_id = girl.id
	req.location_id = girl.default_date_location_id
	req.greeting_ids = girl.dating_greeting_ids.duplicate()
	req.farewell_id = girl.dating_farewell_id
	req.rng_seed = seed
	return req


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


func _pick_worst_greeting(girl: GirlDefinition) -> StringName:
	var worst_id: StringName = girl.dating_greeting_ids[0]
	var worst_score: int = 999
	for gid in girl.dating_greeting_ids:
		var def: DatingGreetingDefinition = _db.call("get_dating_greeting", gid) as DatingGreetingDefinition
		if def == null:
			continue
		var score: int = PrimaryTraitEvaluator.evaluate(girl.primary_trait, def.direct_tags)
		if score < worst_score:
			worst_score = score
			worst_id = gid
	return worst_id


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


func _search_prefix(
	girl_id: StringName,
	location_id: StringName,
	greeting_id: StringName,
	planned: Array[StringName],
	prefix: Array[StringName],
	next_choices: Array[StringName],
	target_min: int,
	prefer_high: bool,
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
	if prefer_high:
		ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) > int(b["score"]))
	else:
		ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["score"]) < int(b["score"]))
	for item in ordered:
		var aid: StringName = item["id"] as StringName
		var next_prefix: Array[StringName] = prefix.duplicate()
		next_prefix.append(aid)
		var trial: DatingResult = _replay_scripted(girl_id, location_id, greeting_id, planned, next_prefix)
		if trial != null and next_prefix.size() == 4:
			if prefer_high and trial.date_delta >= target_min:
				return trial
			if (not prefer_high) and trial.date_delta <= target_min:
				return trial
			continue
		_reset()
		_boost_for_ideal_date()
		_gs.call("mark_girl_discovered", girl_id)
		_gs.call("add_girl_contact", girl_id)
		var req := DatingStartRequest.new()
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
			if prefer_high and s2.result.date_delta >= target_min:
				return s2.result
			if (not prefer_high) and s2.result.date_delta <= target_min:
				return s2.result
			continue
		var child: DatingResult = _search_prefix(
			girl_id,
			location_id,
			greeting_id,
			planned,
			next_prefix,
			_available_action_ids(),
			target_min,
			prefer_high,
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
	var req := DatingStartRequest.new()
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


func _play_forced_plan(
	girl_id: StringName,
	planned: Array[StringName],
	target_min: int,
	prefer_high: bool,
) -> DatingResult:
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
	var greeting_id: StringName = _pick_best_greeting(girl) if prefer_high else _pick_worst_greeting(girl)
	_dc.call("select_greeting", greeting_id)
	return _search_prefix(
		girl_id,
		session.location_id,
		greeting_id,
		planned,
		[],
		_available_action_ids(),
		target_min,
		prefer_high,
	)


func _test_editor_plus5_and_minus2() -> void:
	var girl_id: StringName = StoryIds.GIRL_MAGAZINE_EDITOR
	var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
	var planned_plus: Array[StringName] = [
		&"date_event_editor_publishable_failure",
		&"date_event_editor_headline",
		&"date_event_editor_public_argument",
	]
	# Canonical STRANGE+SCANDALOUS route: 3 liked centrals + ABSURDITY farewell + public CONFLICT.
	var scripted_plus: DatingResult = _replay_scripted(
		girl_id,
		girl.default_date_location_id,
		&"dating_greeting_immediate_joke",
		planned_plus,
		[
			&"date_action_editor_fail_consequence",
			&"date_action_editor_headline_table",
			&"date_action_editor_arg_spoon_law",
			&"date_action_farewell_absurd_line",
		] as Array[StringName],
	)
	var plus_reached: bool = scripted_plus != null and scripted_plus.date_delta >= 5
	var best_delta: int = scripted_plus.date_delta if scripted_plus != null else -999
	if not plus_reached:
		var forced: DatingResult = _play_forced_plan(girl_id, planned_plus, 5, true)
		if forced != null:
			best_delta = forced.date_delta
			plus_reached = forced.date_delta >= 5
	_ok(plus_reached, "Editor +5 feasible (best=%s)" % best_delta)
	if scripted_plus != null:
		_ok(scripted_plus.primary_total == 4, "Editor +5 primary_total 4")
		_ok(scripted_plus.secondary_reaction == 1, "Editor +5 secondary +1")
	var scripted_minus: DatingResult = _replay_scripted(
		girl_id,
		girl.default_date_location_id,
		&"dating_greeting_simple",
		planned_plus,
		[
			&"date_action_editor_fail_expensive",
			&"date_action_editor_headline_plain",
			&"date_action_editor_arg_criteria",
			&"date_action_farewell_walk",
		] as Array[StringName],
	)
	var minus_reached: bool = scripted_minus != null and scripted_minus.date_delta <= -2
	var worst_delta: int = scripted_minus.date_delta if scripted_minus != null else 999
	if not minus_reached:
		var bad: DatingResult = _play_forced_plan(girl_id, planned_plus, -2, false)
		if bad != null:
			worst_delta = bad.date_delta
			minus_reached = bad.date_delta <= -2
	_ok(minus_reached, "Editor <=-2 feasible (worst=%s)" % worst_delta)
	await get_tree().process_frame


func _advance_to_stage3() -> void:
	_gs.call("mark_girl_conquered", StoryIds.GIRL_NEIGHBOR)
	_story.call("reconcile_current_stage")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_ACTRESS)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_ACTRESS)
	_story.call("reconcile_current_stage")
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MINE_BOSS)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_MINE_BOSS)
	_story.call("reconcile_current_stage")


func _test_editor_rival_money_and_win() -> void:
	_reset()
	_advance_to_stage3()
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_3), "rival test starts STAGE_3")
	var available: Array = _re.call("get_available_competitions", StoryIds.RIVAL_MAGAZINE_EDITOR) as Array
	_ok(available.has(GameTypes.CompetitionType.DANCE), "Editor rival DANCE available without Payable Intent")
	_ok(not available.has(GameTypes.CompetitionType.MONEY), "Editor rival MONEY locked without Payable Intent")
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_PAYABLE_INTENT])
	var with_perk: Array = _re.call("get_available_competitions", StoryIds.RIVAL_MAGAZINE_EDITOR) as Array
	_ok(with_perk.has(GameTypes.CompetitionType.MONEY), "Editor rival MONEY with Payable Intent")
	_ok(with_perk.has(GameTypes.CompetitionType.DANCE), "Editor rival DANCE with Payable Intent")
	# Win path without Payable Intent: DANCE, Auth+3, stage stays 3.
	_reset()
	_advance_to_stage3()
	_gs.call("add_authority", 4)
	_ok(int(_gs.call("get_authority")) == 4, "Auth4 before Editor rival")
	var start: Dictionary = _re.call(
		"start_encounter",
		StoryIds.RIVAL_MAGAZINE_EDITOR,
		GameTypes.RivalEncounterInitiator.PLAYER,
	) as Dictionary
	_ok(bool(start.get("ok", false)), "Editor rival encounter start")
	var choose: Dictionary = _re.call("choose_competition", GameTypes.CompetitionType.DANCE) as Dictionary
	_ok(bool(choose.get("ok", false)), "choose DANCE runs competition")
	_ok(int(_gs.call("get_authority")) == 7, "Auth 4+3=7 after Editor rival win")
	_ok(bool(_gs.call("is_rival_defeated", StoryIds.RIVAL_MAGAZINE_EDITOR)), "Editor rival defeated")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_3), "stage stays STAGE_3 after rival win")
	_ok(bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_MAGAZINE_EDITOR)), "Editor girl available after rival win")


func _test_editor_completion_stage4() -> void:
	_reset()
	_advance_to_stage3()
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MAGAZINE_EDITOR)
	_gs.call("add_experience", 3)
	_gs.call("spend_upgrade_points", 3)
	_ok(int(_gs.call("get_experience")) == 3, "before Editor XP3")
	_ok(int(_gs.call("get_upgrade_points")) == 0, "before Editor UP0")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_3), "before Editor STAGE_3")
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION)), "before MEDIA false")
	var result := DatingResult.new()
	result.date_id = 14001
	result.girl_id = StoryIds.GIRL_MAGAZINE_EDITOR
	result.location_id = &"cafe"
	result.central_event_ids = [
		&"date_event_editor_publishable_failure",
		&"date_event_editor_headline",
		&"date_event_editor_public_argument",
	]
	result.date_delta = 5
	_gs.call("mark_girl_discovered", StoryIds.GIRL_MAGAZINE_EDITOR)
	_gs.call("add_girl_contact", StoryIds.GIRL_MAGAZINE_EDITOR)
	var applied: RelationshipDateResult = _rel.call("apply_date_result", result) as RelationshipDateResult
	_ok(applied != null and applied.ok, "Editor +5 apply ok")
	_ok(applied.newly_conquered, "Editor newly conquered")
	_ok(applied.experience_gained == 1, "Editor XP +1 once")
	_ok(applied.upgrade_points_gained == 1, "Editor UP +1 once")
	_ok(int(_gs.call("get_experience")) == 4, "after Editor XP4")
	_ok(int(_gs.call("get_upgrade_points")) == 1, "after Editor UP1")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_4), "after Editor STAGE_4")
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION)), "MEDIA_ATTENTION true")
	_ok(not bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_MAGAZINE_EDITOR)), "Editor StageActor absent at STAGE_4")
	# Second apply must not grant another XP/UP.
	var xp_before: int = int(_gs.call("get_experience"))
	var up_before: int = int(_gs.call("get_upgrade_points"))
	var result2 := DatingResult.new()
	result2.date_id = 14002
	result2.girl_id = StoryIds.GIRL_MAGAZINE_EDITOR
	result2.location_id = &"cafe"
	result2.central_event_ids = [
		&"date_event_editor_bad_photo",
		&"date_event_cafe_queue",
		&"date_event_cafe_rule",
	]
	result2.date_delta = 2
	var applied2: RelationshipDateResult = _rel.call("apply_date_result", result2) as RelationshipDateResult
	_ok(applied2 != null and applied2.ok, "repeat Editor date apply")
	_ok(not applied2.newly_conquered, "no second conquest")
	_ok(int(_gs.call("get_experience")) == xp_before, "XP unchanged on repeat")
	_ok(int(_gs.call("get_upgrade_points")) == up_before, "UP unchanged on repeat")
	await get_tree().process_frame


func _test_stage4_scientist_safety_and_phone() -> void:
	_reset()
	_advance_to_stage3()
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MAGAZINE_EDITOR)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_MAGAZINE_EDITOR)
	_story.call("reconcile_current_stage")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_4), "Stage4 safety stage")
	var progress: StoryStageProgress = _story.call("get_current_progress") as StoryStageProgress
	_ok(progress != null, "Stage4 progress object")
	if progress != null:
		_ok(progress.stage == GameTypes.GameStage.STAGE_4, "progress STAGE_4")
		# MODULE 17 ships Scientist; Stage4 lookups must resolve without crash.
		var try_girl: GirlDefinition = _db.call("try_get_girl", progress.story_girl_id) as GirlDefinition
		var try_rival: RivalDefinition = _db.call("try_get_rival", progress.story_rival_id) as RivalDefinition
		_ok(try_girl != null, "Stage4 story girl present safely")
		_ok(try_rival != null, "Stage4 story rival present safely")
		_ok(progress.story_girl_id == StoryIds.GIRL_SCIENTIST, "Stage4 story girl id scientist")
		_ok(progress.story_rival_id == StoryIds.RIVAL_SCIENTIST, "Stage4 story rival id scientist")
	var journal_script: Script = load("res://ui/phone/phone_journal.gd") as Script
	var journal: PhoneJournal = journal_script.new() as PhoneJournal
	add_child(journal)
	await get_tree().process_frame
	journal.open()
	var story_text: String = journal.get_story_text()
	_ok(story_text.contains("Медийность"), "Phone handoff Медийность")
	_ok(story_text.contains("Фотосессия"), "Phone handoff Фотосессия")
	journal.close()
	journal.queue_free()


func _test_try_get_scientist_present() -> void:
	var g: GirlDefinition = _db.call("try_get_girl", StoryIds.GIRL_SCIENTIST) as GirlDefinition
	var r: RivalDefinition = _db.call("try_get_rival", StoryIds.RIVAL_SCIENTIST) as RivalDefinition
	_ok(g != null, "try_get_girl(scientist) present")
	_ok(r != null, "try_get_rival(scientist) present")


func _test_reset_cleanliness() -> void:
	_reset()
	_advance_to_stage3()
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_MAGAZINE_EDITOR)
	_gs.call("mark_girl_conquered", StoryIds.GIRL_MAGAZINE_EDITOR)
	_story.call("reconcile_current_stage")
	_gs.call("mark_girl_discovered", &"girl_public_sculpture")
	_gs.call("add_girl_contact", &"girl_public_sculpture")
	_gs.call("set_girl_relationship", StoryIds.GIRL_MAGAZINE_EDITOR, 5)
	_gs.call("add_money", 40)
	if _day != null and _day.has_method("advance_day"):
		_day.call("advance_day")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_4), "pre-reset STAGE_4")
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.PROLOGUE), "reset stage PROLOGUE")
	if _day != null and _day.has_method("get_current_day"):
		_ok(int(_day.call("get_current_day")) == 1, "reset GameDay 1")
	else:
		_ok(true, "reset GameDay skipped")
	_ok(not bool(_gs.call("is_rival_defeated", StoryIds.RIVAL_MAGAZINE_EDITOR)), "reset Editor rival undefeated")
	_ok(not bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_MAGAZINE_EDITOR)), "reset Editor absent wrong stage")
	_ok(not bool(_story.call("should_story_rival_be_present", StoryIds.RIVAL_MAGAZINE_EDITOR)), "reset Editor rival absent wrong stage")
	var contacts: Array = _gs.call("get_girl_contact_ids") as Array if _gs.has_method("get_girl_contact_ids") else []
	if _gs.has_method("get_girl_contact_ids"):
		_ok(contacts.is_empty(), "reset contacts empty")
	else:
		_ok(not bool(_gs.call("has_girl_contact", &"girl_public_sculpture")), "reset no sculpture contact")
	_ok(int(_gs.call("get_girl_relationship", StoryIds.GIRL_MAGAZINE_EDITOR)) == 0, "reset Editor relationship 0")
	_ok(int(_gs.call("get_money")) == 0, "reset money 0")
	_ok(bool(_story.call("should_story_girl_be_present", StoryIds.GIRL_NEIGHBOR)), "reset neighbor present")
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.MEDIA_ATTENTION)), "reset MEDIA locked")
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE)), "reset salary locked")


func _test_repeat_date_new_girls() -> void:
	for girl_id in [
		StoryIds.GIRL_MAGAZINE_EDITOR,
		&"girl_cafe_receipt_notes",
		&"girl_public_sculpture",
	]:
		var girl: GirlDefinition = _db.call("get_girl", girl_id) as GirlDefinition
		_ok(girl != null, "repeat girl exists %s" % String(girl_id))
		if girl == null:
			continue
		_reset()
		_boost_for_ideal_date()
		_gs.call("add_experience", girl.required_experience)
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
			print("MODULE_14B_TEST second-date error %s: %s" % [String(girl_id), str(start2.get("error", &""))])
			continue
		var session2: DatingSession = _dc.call("get_session") as DatingSession
		var second_events: Array[StringName] = session2.central_event_ids.duplicate()
		var reused: int = 0
		for eid in second_events:
			if first_events.has(eid):
				reused += 1
		_ok(reused == 0, "no immediate reuse %s" % String(girl_id))
		_dc.call("force_clear_session")
