extends Node
## MODULE 09 Dating Core self-test (spec §§129–184).
## Run: res://game/dating/test/dating_test.tscn --quit-after 15000

var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _db: Node = null
var _dc: Node = null
var _finished_count: int = 0
var _last_result: DatingResult = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_db = get_node("/root/ContentDB")
	_dc = get_node("/root/DatingCore")
	var relationships: Node = get_node_or_null("/root/Relationships")
	if relationships != null and relationships.has_method("set_auto_apply_enabled"):
		relationships.call("set_auto_apply_enabled", false)
	await get_tree().process_frame
	DatingTestFixtures.register_all(_db)
	_dc.connect("date_finished", _on_date_finished)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_09_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_09_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_09_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_09_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_date_finished(result: DatingResult) -> void:
	_finished_count += 1
	_last_result = result


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_09_TEST] FAIL: %s" % label)
		print("MODULE_09_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_dc.call("force_clear_session")
	_dc.call("clear_external_resolver")
	var relationships: Node = get_node_or_null("/root/Relationships")
	if relationships != null and relationships.has_method("set_auto_apply_enabled"):
		relationships.call("set_auto_apply_enabled", false)
	_finished_count = 0
	_last_result = null
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	_dc.call("set_rng", rng)


func _contact(girl_id: StringName = &"girl_test_dating_kind") -> void:
	_gs.call("mark_girl_discovered", girl_id)
	_gs.call("add_girl_contact", girl_id)


func _start(girl_id: StringName = &"girl_test_dating_kind", seed: int = 42) -> Dictionary:
	var req: DatingStartRequest = DatingTestFixtures.default_request(girl_id)
	req.rng_seed = seed
	return _dc.call("start_date", req) as Dictionary


func _run_all() -> void:
	_test_planner_pure()
	_test_primary_pure()
	_test_secondary_pure()
	_test_no_contact()
	_test_already_active()
	_test_insufficient()
	_test_excluded_and_location()
	_test_sequence_immutable()
	_test_greeting_diagnostic()
	_test_silence_perks()
	_test_direct_and_external()
	_test_gates_money_perks()
	_test_encore()
	_test_full_plus_minus()
	_test_boundary_untouched()
	_test_phone_labels()
	_test_no_limit_not_fake()
	_test_finish_once()
	_test_module25_ordinary_date_feasibility()
	_test_module25_ordinary_planner_sample()
	_gs.call("reset_for_new_game")
	_dc.call("force_clear_session")


func _test_planner_pure() -> void:
	var seqs: Array = DatingEventPlanner.all_valid_category_sequences()
	_ok(seqs.size() == 24, "24 valid category sequences")
	for seq in seqs:
		var t: Array = seq as Array
		_ok(not (int(t[0]) == int(t[1]) and int(t[1]) == int(t[2])), "no AAA triple")
	var slots: Array = DatingEventPlanner.marginal_category_counts(seqs)
	for i in range(3):
		var d: Dictionary = slots[i] as Dictionary
		for cat in [
			GameTypes.DatingEventCategory.CONVERSATION,
			GameTypes.DatingEventCategory.SPACE_EVENT,
			GameTypes.DatingEventCategory.GIRL_PROPOSAL,
		]:
			_ok(int(d.get(int(cat), 0)) == 8, "slot %s cat %s count 8" % [i, cat])


func _test_primary_pure() -> void:
	var def: PrimaryTraitDefinition = _db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.KIND) as PrimaryTraitDefinition
	var liked: Array[GameTypes.ActionTag] = [GameTypes.ActionTag.CARE]
	var disliked: Array[GameTypes.ActionTag] = [GameTypes.ActionTag.DOMINANCE]
	var both: Array[GameTypes.ActionTag] = [GameTypes.ActionTag.CARE, GameTypes.ActionTag.DOMINANCE]
	var neither: Array[GameTypes.ActionTag] = [GameTypes.ActionTag.PRESTIGE]
	_ok(PrimaryTraitEvaluator.evaluate_with_definition(def, liked) == 1, "primary liked")
	_ok(PrimaryTraitEvaluator.evaluate_with_definition(def, disliked) == -1, "primary disliked")
	_ok(PrimaryTraitEvaluator.evaluate_with_definition(def, both) == 0, "primary both")
	_ok(PrimaryTraitEvaluator.evaluate_with_definition(def, neither) == 0, "primary neither")
	var status: PrimaryTraitDefinition = _db.call("get_primary_trait", GameTypes.PrimaryGirlTrait.STATUS) as PrimaryTraitDefinition
	var coll: Array[GameTypes.ActionTag] = [GameTypes.ActionTag.PRESTIGE, GameTypes.ActionTag.ABSURDITY]
	_ok(PrimaryTraitEvaluator.evaluate_with_definition(status, coll) == 0, "status collision")


func _test_secondary_pure() -> void:
	var r_pub := _rec(GameTypes.PlayerCharacteristic.MUSCLE, [GameTypes.ActionTag.CONFLICT], 1, true)
	var r_priv := _rec(GameTypes.PlayerCharacteristic.AURA, [GameTypes.ActionTag.CARE], 1, false)
	var scandal_pos: Array[DatingDecisionRecord] = [r_pub, r_priv, r_priv, r_priv]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.SCANDALOUS, scandal_pos) == 1, "scandal +1")
	var all_priv: Array[DatingDecisionRecord] = [r_priv, r_priv, r_priv, r_priv]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.SCANDALOUS, all_priv) == -1, "scandal -1")
	var pub_no_c := _rec(GameTypes.PlayerCharacteristic.MUSCLE, [GameTypes.ActionTag.CARE], 1, true)
	var scandal0: Array[DatingDecisionRecord] = [pub_no_c, r_priv, r_priv, r_priv]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.SCANDALOUS, scandal0) == 0, "scandal 0")
	var c_plus: Array[DatingDecisionRecord] = [
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.AURA, [], 0, false),
	]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.CONSISTENT, c_plus) == 1, "consistent +1")
	var c_minus: Array[DatingDecisionRecord] = [
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.APPEARANCE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.CAPITAL, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.AURA, [], 1, false),
	]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.CONSISTENT, c_minus) == -1, "consistent -1")
	var c_zero: Array[DatingDecisionRecord] = [
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.AURA, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.AURA, [], 1, false),
	]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.CONSISTENT, c_zero) == 0, "consistent 0")
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.VARIETY_SEEKING, c_minus) == 1, "variety +1")
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.VARIETY_SEEKING, c_plus) == -1, "variety -1")
	var dem_pos: Array[DatingDecisionRecord] = [
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.AURA, [], 1, false),
		_rec(GameTypes.PlayerCharacteristic.CAPITAL, [], 0, false),
		_rec(GameTypes.PlayerCharacteristic.APPEARANCE, [], 0, false),
	]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.DEMANDING, dem_pos) == 1, "demanding +1")
	var dem_neg: Array[DatingDecisionRecord] = [
		_rec(GameTypes.PlayerCharacteristic.MUSCLE, [], -1, false),
		_rec(GameTypes.PlayerCharacteristic.AURA, [], -1, false),
		_rec(GameTypes.PlayerCharacteristic.CAPITAL, [], 0, false),
		_rec(GameTypes.PlayerCharacteristic.APPEARANCE, [], 1, false),
	]
	_ok(SecondaryTraitEvaluator.evaluate(GameTypes.SecondaryGirlTrait.DEMANDING, dem_neg) == -1, "demanding -1")


func _rec(
	c: GameTypes.PlayerCharacteristic,
	tags: Array,
	reaction: int,
	was_public: bool,
) -> DatingDecisionRecord:
	var r := DatingDecisionRecord.new()
	r.characteristic = c
	var typed: Array[GameTypes.ActionTag] = []
	for t in tags:
		typed.append(t as GameTypes.ActionTag)
	r.final_tags = typed
	r.primary_reaction = reaction
	r.was_public = was_public
	return r


func _test_no_contact() -> void:
	_reset()
	var res: Dictionary = _start()
	_ok(not bool(res.get("ok", true)), "no contact rejects")
	_ok(res.get("error", &"") == DatingTypes.ERR_NO_CONTACT, "NO_CONTACT code")


func _test_already_active() -> void:
	_reset()
	_contact()
	var a: Dictionary = _start()
	_ok(bool(a.get("ok", false)), "first start ok")
	var b: Dictionary = _start()
	_ok(not bool(b.get("ok", true)), "second start rejected")
	_ok(b.get("error", &"") == DatingTypes.ERR_DATE_ALREADY_ACTIVE, "DATE_ALREADY_ACTIVE")


func _test_insufficient() -> void:
	_reset()
	_contact(&"girl_test_dating_thin")
	var res: Dictionary = _start(&"girl_test_dating_thin")
	_ok(not bool(res.get("ok", true)), "thin pool insufficient")
	_ok(res.get("error", &"") == DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT, "INSUFFICIENT_DATE_CONTENT")
	_ok(not bool(_dc.call("is_date_active")), "no active after insufficient")


func _test_excluded_and_location() -> void:
	_reset()
	_contact()
	var req: DatingStartRequest = DatingTestFixtures.default_request()
	req.excluded_event_ids = [
		&"date_event_test_conv_1",
		&"date_event_test_conv_2",
		&"date_event_test_conv_3",
		&"date_event_test_conv_4",
	]
	req.rng_seed = 7
	var res: Dictionary = _dc.call("start_date", req) as Dictionary
	_ok(bool(res.get("ok", false)), "start with excluded conv still ok via other cats")
	var session: DatingSession = _dc.call("get_session") as DatingSession
	for eid in session.central_event_ids:
		_ok(not req.excluded_event_ids.has(eid), "excluded not selected %s" % String(eid))
	_dc.call("force_clear_session")
	_reset()
	_contact()
	var req2: DatingStartRequest = DatingTestFixtures.default_request()
	req2.location_id = &"gym"
	req2.rng_seed = 11
	var res2: Dictionary = _dc.call("start_date", req2) as Dictionary
	_ok(bool(res2.get("ok", false)), "start at gym")
	var s2: DatingSession = _dc.call("get_session") as DatingSession
	for eid2 in s2.central_event_ids:
		_ok(eid2 != &"date_event_test_conv_4", "cafe-only excluded at gym")


func _test_sequence_immutable() -> void:
	_reset()
	_contact()
	_start()
	var s: DatingSession = _dc.call("get_session") as DatingSession
	var snapshot: Array[StringName] = s.central_event_ids.duplicate()
	_ok(snapshot.size() == 3, "3 central ids")
	_ok(snapshot[0] != snapshot[1] and snapshot[1] != snapshot[2] and snapshot[0] != snapshot[2], "unique ids")
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	var s2: DatingSession = _dc.call("get_session") as DatingSession
	_ok(s2.central_event_ids == snapshot, "central ids immutable")


func _test_greeting_diagnostic() -> void:
	_reset()
	_contact()
	_start()
	_dc.call("continue_arrival")
	var gre: Dictionary = _dc.call("select_greeting", &"dating_greeting_test_simple") as Dictionary
	_ok(int(gre.get("reaction", 0)) == 1, "kind greeting +1")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	_ok(s.greeting_reaction == 1, "greeting_reaction stored")
	_ok(s.decision_records.is_empty(), "greeting not in decision records")
	var reactions: Dictionary = _gs.call("get_girl_known_reactions", &"girl_test_dating_kind") as Dictionary
	_ok(int(reactions.get(&"dating_greeting_test_simple", 99)) == 1, "greeting known reaction")
	# silence without perk
	_reset()
	_contact()
	_start()
	_dc.call("continue_arrival")
	var choices: Array = _dc.call("list_greeting_choices") as Array
	var has_silence: bool = false
	for c in choices:
		if bool((c as Dictionary).get("silence", false)):
			has_silence = true
	_ok(not has_silence, "silence hidden without perk")
	var rej: Dictionary = _dc.call("select_greeting", DatingTypes.SILENCE_GREETING_ID) as Dictionary
	_ok(not bool(rej.get("ok", true)), "silence rejected without perk")


func _test_silence_perks() -> void:
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.AURA_RIGHT_TO_SAY_NOTHING])
	_start()
	_dc.call("continue_arrival")
	var r: Dictionary = _dc.call("select_greeting", DatingTypes.SILENCE_GREETING_ID) as Dictionary
	_ok(bool(r.get("ok", false)), "silence ok")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	_ok(s.greeting_reaction == 0, "silence reaction 0")
	_ok(s.used_right_to_say_nothing, "used silence flag")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_dating_kind", 0)), "one clue revealed")
	_ok(not bool(_gs.call("is_girl_clue_known", &"girl_test_dating_kind", 1)), "second clue not yet")
	_ok(not bool(_gs.call("is_primary_trait_revealed", &"girl_test_dating_kind")), "no trait auto reveal")
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.AURA_RIGHT_TO_SAY_NOTHING, PerkIds.AURA_SHE_ALREADY_STARTED])
	_start()
	_dc.call("continue_arrival")
	_dc.call("select_greeting", DatingTypes.SILENCE_GREETING_ID)
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_dating_kind", 0)), "clue0 with both")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_test_dating_kind", 1)), "clue1 with both")
	_ok(not bool(_gs.call("is_primary_trait_revealed", &"girl_test_dating_kind")), "still no trait")


func _test_direct_and_external() -> void:
	_reset()
	_contact()
	_force_events([&"date_event_test_space_3", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	var wait: Dictionary = _dc.call("select_action", &"action_test_external") as Dictionary
	_ok(bool(wait.get("waiting", false)), "external waits")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	_ok(s.phase == DatingTypes.Phase.RESOLVING_ACTION, "RESOLVING_ACTION")
	_ok(s.decision_records.is_empty(), "no record yet")
	var ext := DatingActionExecutionResult.new()
	ext.outcome = DatingTypes.ExecutionOutcome.FAILURE
	ext.has_tag_override = true
	ext.tags = [GameTypes.ActionTag.VULNERABILITY]
	ext.was_public = false
	ext.result_text = "fail liked"
	var sub: Dictionary = _dc.call("submit_action_execution_result", ext) as Dictionary
	_ok(bool(sub.get("ok", false)), "submit ok")
	s = _dc.call("get_session") as DatingSession
	_ok(s.decision_records.size() == 1, "one record")
	_ok(s.decision_records[0].primary_reaction == 1, "FAIL tags liked by kind")
	_ok(s.decision_records[0].execution_outcome == DatingTypes.ExecutionOutcome.FAILURE, "outcome FAILURE")


func _force_events(ids: Array[StringName]) -> void:
	## Start normally then overwrite planned ids for deterministic action tests.
	var res: Dictionary = _start()
	_ok(bool(res.get("ok", false)), "force_events start")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	s.central_event_ids = ids.duplicate()


func _test_gates_money_perks() -> void:
	# Muscle gate
	_reset()
	_contact()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_force_events([&"date_event_test_conv_2", &"date_event_test_space_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	var av: Array = _dc.call("list_action_choices") as Array
	var muscle_ok: bool = false
	for c in av:
		var d: Dictionary = c as Dictionary
		if d.get("id", &"") == &"action_test_muscle_gate":
			muscle_ok = bool(d.get("available", true))
	_ok(not muscle_ok, "muscle 2 blocked for req 3")
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 3)
	av = _dc.call("list_action_choices") as Array
	for c2 in av:
		var d2: Dictionary = c2 as Dictionary
		if d2.get("id", &"") == &"action_test_muscle_gate":
			_ok(bool(d2.get("available", false)), "muscle 3 available")
	# required perk
	var hold_ok: bool = true
	for c3 in av:
		var d3: Dictionary = c3 as Dictionary
		if d3.get("id", &"") == &"action_test_hold_door":
			hold_ok = bool(d3.get("available", true))
	_ok(not hold_ok, "hold doorway blocked without perk")
	_gs.call("restore_purchased_perks", [PerkIds.MUSCLE_HOLD_DOORWAY])
	av = _dc.call("list_action_choices") as Array
	for c4 in av:
		var d4: Dictionary = c4 as Dictionary
		if d4.get("id", &"") == &"action_test_hold_door":
			_ok(bool(d4.get("available", false)), "hold doorway with perk")
	# Public significance
	_reset()
	_contact()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 4)
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_PUBLIC_SIGNIFICANCE])
	_force_events([&"date_event_test_space_4", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	av = _dc.call("list_action_choices") as Array
	var gate5: bool = false
	var gate6: bool = true
	for c5 in av:
		var d5: Dictionary = c5 as Dictionary
		if d5.get("id", &"") == &"action_test_appearance_gate5":
			gate5 = bool(d5.get("available", false)) and bool(d5.get("uses_public_significance", false))
		if d5.get("id", &"") == &"action_test_appearance_gate6":
			gate6 = bool(d5.get("available", true))
	_ok(gate5, "public significance +1 available")
	_ok(not gate6, "public significance +2 still blocked")
	_dc.call("select_action", &"action_test_appearance_gate5")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	_ok(s.used_public_significance, "public significance consumed")
	_ok(s.decision_records[0].used_public_significance, "record flag")
	# normal availability does not consume
	_reset()
	_contact()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 5)
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_PUBLIC_SIGNIFICANCE])
	_force_events([&"date_event_test_space_4", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_appearance_gate5")
	s = _dc.call("get_session") as DatingSession
	_ok(not s.used_public_significance, "charge kept when already enough")
	# Second outfit timing
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_SECOND_OUTFIT])
	_start()
	_ok(bool(_dc.call("can_use_second_outfit")), "second outfit on arrival")
	_dc.call("continue_arrival")
	_ok(bool(_dc.call("can_use_second_outfit")), "second outfit on greeting")
	_dc.call("use_second_outfit")
	s = _dc.call("get_session") as DatingSession
	_ok(s.used_second_outfit, "second outfit used")
	_ok(not bool(_dc.call("can_use_second_outfit")), "second outfit once")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_ok(not bool(_dc.call("can_use_second_outfit")), "unavailable after first evaluated")
	# Representation + Dignity
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_REPRESENTATION_EXPENSES, PerkIds.CAPITAL_DIGNITY_REFUND])
	_ok(int(_gs.call("get_money")) == 0, "money 0")
	_force_events([&"date_event_test_space_2", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	av = _dc.call("list_action_choices") as Array
	var free_ok: bool = false
	for c6 in av:
		var d6: Dictionary = c6 as Dictionary
		if d6.get("id", &"") == &"action_test_paid_normal":
			free_ok = bool(d6.get("available", false)) and bool(d6.get("free_via_representation", false))
	_ok(free_ok, "representation makes first paid free")
	_dc.call("select_action", &"action_test_paid_normal")
	s = _dc.call("get_session") as DatingSession
	_ok(s.used_representation_expenses, "rep consumed")
	_ok(s.decision_records[0].money_spent == 0, "money_spent 0")
	# major does not use rep; second paid blocked
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_REPRESENTATION_EXPENSES])
	_force_events([&"date_event_test_space_2", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	av = _dc.call("list_action_choices") as Array
	var major_blocked: bool = true
	for c7 in av:
		var d7: Dictionary = c7 as Dictionary
		if d7.get("id", &"") == &"action_test_paid_major":
			major_blocked = not bool(d7.get("available", true))
	_ok(major_blocked, "major expense not covered by rep at money 0")
	# Dignity refund
	_reset()
	_contact()
	_gs.call("add_money", 20)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_DIGNITY_REFUND])
	_force_events([&"date_event_test_space_3", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_external_fail")
	var fail_res := DatingActionExecutionResult.new()
	fail_res.outcome = DatingTypes.ExecutionOutcome.FAILURE
	fail_res.has_tag_override = true
	fail_res.tags = [GameTypes.ActionTag.VULNERABILITY]
	fail_res.was_public = false
	_dc.call("submit_action_execution_result", fail_res)
	_ok(int(_gs.call("get_money")) == 20, "dignity refund restores money")
	s = _dc.call("get_session") as DatingSession
	_ok(s.money_spent_total == 0, "net money_spent_total 0")
	_ok(s.decision_records[0].primary_reaction == 1, "refund keeps reaction")


func _test_encore() -> void:
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_ENCORE])
	_force_events([&"date_event_test_space_4", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	var r: Dictionary = _dc.call("select_action", &"action_test_appearance_neutral") as Dictionary
	_ok(bool(r.get("encore", false)), "encore offered on appearance 0")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	_ok(s.phase == DatingTypes.Phase.ENCORE_DECISION, "ENCORE_DECISION")
	# decline keeps charge
	_dc.call("resolve_encore", false)
	s = _dc.call("get_session") as DatingSession
	_ok(not s.used_encore, "encore unused after decline")
	_ok(s.decision_records[0].final_tags.has(GameTypes.ActionTag.PRESTIGE), "original tags kept")
	# use encore transform 1 tag
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_ENCORE])
	_force_events([&"date_event_test_space_4", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_appearance_neutral")
	_dc.call("resolve_encore", true)
	s = _dc.call("get_session") as DatingSession
	_ok(s.used_encore, "encore used")
	var tags: Array[GameTypes.ActionTag] = s.decision_records[0].final_tags
	_ok(tags.size() == 2 and tags.has(GameTypes.ActionTag.ORIGINALITY), "encore adds ORIGINALITY")
	# transform 2 tags
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_ENCORE])
	_force_events([&"date_event_test_space_4", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_appearance_two_tags")
	_dc.call("resolve_encore", true)
	s = _dc.call("get_session") as DatingSession
	tags = s.decision_records[0].final_tags
	_ok(tags.size() == 2 and tags[0] == GameTypes.ActionTag.PRESTIGE and tags[1] == GameTypes.ActionTag.ORIGINALITY, "encore replaces second tag")
	# muscle no encore
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.APPEARANCE_ENCORE])
	_force_events([&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	var r2: Dictionary = _dc.call("select_action", &"action_test_prestige") as Dictionary
	_ok(not bool(r2.get("encore", false)), "no encore for non-appearance")


func _play_scripted_date(action_ids: Array[StringName], girl_id: StringName = &"girl_test_dating_kind") -> DatingResult:
	_reset()
	_contact(girl_id)
	_force_events([&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	for i in range(action_ids.size()):
		var aid: StringName = action_ids[i]
		var res: Dictionary = _dc.call("select_action", aid) as Dictionary
		if bool(res.get("encore", false)):
			_dc.call("resolve_encore", false)
		if bool(res.get("waiting", false)):
			var ext := DatingActionExecutionResult.new()
			ext.outcome = DatingTypes.ExecutionOutcome.SUCCESS
			ext.has_tag_override = false
			ext.tags = []
			ext.was_public = false
			_dc.call("submit_action_execution_result", ext)
	var s: DatingSession = _dc.call("get_session") as DatingSession
	return s.result


func _test_full_plus_minus() -> void:
	# Kind likes CARE/VULNERABILITY/SIMPLICITY; DEMANDING secondary +1 if neg0 and pos>=2
	var result: DatingResult = _play_scripted_date([
		&"action_test_care",
		&"action_test_private_care",
		&"action_test_simplicity",
		&"action_test_farewell_care",
	])
	_ok(result != null, "+path result")
	if result != null:
		_ok(result.primary_total == 4, "primary_total +4 got %s" % result.primary_total)
		_ok(result.secondary_reaction == 1, "secondary +1 demanding")
		_ok(result.date_delta == 5, "date_delta +5")
		_ok(result.decision_records.size() == 4, "exactly 4 records")
	# Exact -5: four disliked tags + DEMANDING with neg>=2
	_reset()
	_contact()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 3)
	_force_events([&"date_event_test_conv_2", &"date_event_test_space_1", &"date_event_test_prop_2"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_muscle_gate") # DOMINANCE => -1
	_dc.call("select_action", &"action_test_public_conflict") # CONFLICT => -1
	_dc.call("select_action", &"action_test_dominance") # DOMINANCE => -1
	_dc.call("select_action", &"action_test_farewell_dislike") # DOMINANCE => -1
	var s_neg: DatingSession = _dc.call("get_session") as DatingSession
	var neg: DatingResult = s_neg.result if s_neg != null else null
	_ok(neg != null, "neg path result exists")
	if neg != null:
		_ok(neg.primary_total == -4, "primary_total -4 got %s" % neg.primary_total)
		_ok(neg.secondary_reaction == -1, "secondary -1 demanding")
		_ok(neg.date_delta == -5, "date_delta -5")
		_ok(neg.decision_records.size() == 4, "neg 4 records")
	# Relationship/XP untouched across a finished +5 date
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 2)
	var before_rel: int = int(_gs.call("get_girl_relationship", &"girl_test_dating_kind"))
	var before_xp: int = int(_gs.call("get_experience"))
	_force_events([&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_care")
	_dc.call("select_action", &"action_test_private_care")
	_dc.call("select_action", &"action_test_simplicity")
	_dc.call("select_action", &"action_test_farewell_care")
	var s_plus: DatingSession = _dc.call("get_session") as DatingSession
	var plus: DatingResult = s_plus.result if s_plus != null else null
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == before_rel, "relationship untouched")
	_ok(int(_gs.call("get_experience")) == before_xp, "xp untouched")
	_ok(not bool(_gs.call("is_girl_conquered", &"girl_test_dating_kind")), "not conquered")
	if plus != null:
		_ok(plus.date_delta == 5, "full +5")


func _test_boundary_untouched() -> void:
	var src := FileAccess.open("res://game/dating/dating_core.gd", FileAccess.READ)
	_ok(src != null, "read dating_core")
	var text: String = src.get_as_text() if src != null else ""
	_ok(not text.contains("add_girl_relationship"), "no add_girl_relationship")
	_ok(not text.contains("set_girl_relationship"), "no set_girl_relationship")
	_ok(not text.contains("mark_girl_conquered"), "no mark_girl_conquered")
	_ok(not text.contains("add_experience"), "no add_experience")
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 2)
	var before: int = int(_gs.call("get_girl_relationship", &"girl_test_dating_kind"))
	_force_events([&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_care")
	_dc.call("select_action", &"action_test_private_care")
	_dc.call("select_action", &"action_test_simplicity")
	_dc.call("select_action", &"action_test_farewell_aura")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == before, "rel still same after date")


func _test_phone_labels() -> void:
	_reset()
	_contact()
	_start()
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_care")
	var journal_scene: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	var journal: Node = journal_scene.instantiate()
	add_child(journal)
	var label_g: String = journal.call("_resolve_reaction_source_label", &"dating_greeting_test_simple") as String
	var label_a: String = journal.call("_resolve_reaction_source_label", &"action_test_care") as String
	_ok(label_g == "Простое приветствие", "phone greeting label")
	_ok(label_a == "Забота", "phone action label")
	journal.queue_free()


func _test_no_limit_not_fake() -> void:
	_reset()
	_contact()
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_NO_LIMIT])
	_force_events([&"date_event_test_space_2", &"date_event_test_conv_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	var av: Array = _dc.call("list_action_choices") as Array
	var paid_ok: bool = true
	for c in av:
		var d: Dictionary = c as Dictionary
		if d.get("id", &"") == &"action_test_paid_normal":
			paid_ok = bool(d.get("available", true))
	_ok(not paid_ok, "NO_LIMIT does not make unpaid date freebie")


func _test_finish_once() -> void:
	_finished_count = 0
	var result: DatingResult = _play_scripted_date([
		&"action_test_care",
		&"action_test_private_care",
		&"action_test_simplicity",
		&"action_test_farewell_care",
	])
	_ok(result != null, "finish result")
	_ok(_finished_count == 1, "date_finished once")
	var again: Dictionary = _dc.call("select_action", &"action_test_care") as Dictionary
	_ok(not bool(again.get("ok", true)), "input rejected after finish")


## MODULE 25 Wave K — ordinary dating feasibility (spec §92–95 practical).
func _ordinary_production_girls() -> Array[GirlDefinition]:
	var out: Array[GirlDefinition] = []
	var girls: Array = _db.call("list_girls") as Array
	for g in girls:
		var girl: GirlDefinition = g as GirlDefinition
		if girl == null or girl.is_story:
			continue
		out.append(girl)
	return out


func _action_usable_level0(action: DatingActionDefinition) -> bool:
	## Spec §92: required characteristic level 0 only (money/perks may still gate runtime).
	if action == null:
		return false
	if action.required_characteristic_level > 0:
		return false
	if String(action.required_perk_id) != "":
		return false
	return true


func _collect_level0_event_slots(girl: GirlDefinition) -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	var location_id: StringName = girl.default_date_location_id
	var seen: Dictionary = {}
	for pool_id in girl.dating_pool_ids:
		var pool: DatingEventPoolDefinition = _db.call("get_dating_pool", pool_id) as DatingEventPoolDefinition
		if pool == null:
			continue
		for eid in pool.event_ids:
			if seen.has(eid):
				continue
			seen[eid] = true
			var ev: DatingEventDefinition = _db.call("get_dating_event", eid) as DatingEventDefinition
			if ev == null:
				continue
			if not DatingEventPlanner.event_allowed_at_location(ev, location_id):
				continue
			var usable: Array[DatingActionDefinition] = []
			for action in ev.actions:
				if _action_usable_level0(action):
					usable.append(action)
			if usable.is_empty():
				continue
			slots.append({
				"event_id": eid,
				"category": ev.category,
				"actions": usable,
			})
	return slots


func _collect_level0_farewell_actions(girl: GirlDefinition) -> Array[DatingActionDefinition]:
	var out: Array[DatingActionDefinition] = []
	var farewell: DatingFarewellDefinition = _db.call("get_dating_farewell", girl.dating_farewell_id) as DatingFarewellDefinition
	if farewell == null:
		return out
	for action in farewell.actions:
		if _action_usable_level0(action):
			out.append(action)
	return out


func _score_actions_for_girl(
	girl: GirlDefinition,
	actions: Array[DatingActionDefinition],
) -> Dictionary:
	var primary_def: PrimaryTraitDefinition = _db.call("get_primary_trait", girl.primary_trait) as PrimaryTraitDefinition
	var records: Array[DatingDecisionRecord] = []
	var primary_total: int = 0
	for action in actions:
		var typed: Array[GameTypes.ActionTag] = []
		for t in action.direct_tags:
			typed.append(t as GameTypes.ActionTag)
		var rec := DatingDecisionRecord.new()
		rec.source_id = action.id
		rec.characteristic = action.characteristic
		rec.final_tags = typed
		rec.primary_reaction = PrimaryTraitEvaluator.evaluate_with_definition(primary_def, typed)
		rec.was_public = action.is_public
		primary_total += rec.primary_reaction
		records.append(rec)
	var secondary: int = SecondaryTraitEvaluator.evaluate(girl.secondary_trait, records)
	var delta: int = clampi(primary_total + secondary, -5, 5)
	return {
		"delta": delta,
		"primary_total": primary_total,
		"secondary": secondary,
	}


func _annotate_action(
	action: DatingActionDefinition,
	primary_def: PrimaryTraitDefinition,
	event_id: StringName,
	category: int,
	is_farewell: bool,
) -> Dictionary:
	var typed: Array[GameTypes.ActionTag] = []
	for t in action.direct_tags:
		typed.append(t as GameTypes.ActionTag)
	var reaction: int = PrimaryTraitEvaluator.evaluate_with_definition(primary_def, typed)
	return {
		"action": action,
		"event_id": event_id,
		"category": category,
		"reaction": reaction,
		"characteristic": int(action.characteristic),
		"is_public": action.is_public,
		"has_conflict": typed.has(GameTypes.ActionTag.CONFLICT),
		"is_farewell": is_farewell,
	}


func _try_score_candidates(girl: GirlDefinition, picks: Array) -> int:
	if picks.size() != 4:
		return -999
	var e0: Dictionary = picks[0] as Dictionary
	var e1: Dictionary = picks[1] as Dictionary
	var e2: Dictionary = picks[2] as Dictionary
	var f: Dictionary = picks[3] as Dictionary
	if bool(e0.get("is_farewell", false)) or bool(e1.get("is_farewell", false)) or bool(e2.get("is_farewell", false)):
		return -999
	if not bool(f.get("is_farewell", false)):
		return -999
	var id0: StringName = e0.get("event_id", &"") as StringName
	var id1: StringName = e1.get("event_id", &"") as StringName
	var id2: StringName = e2.get("event_id", &"") as StringName
	if id0 == id1 or id1 == id2 or id0 == id2:
		return -999
	var c0: int = int(e0.get("category", -1))
	var c1: int = int(e1.get("category", -1))
	var c2: int = int(e2.get("category", -1))
	if c0 == c1 and c1 == c2:
		return -999
	var route: Array[DatingActionDefinition] = [
		e0["action"] as DatingActionDefinition,
		e1["action"] as DatingActionDefinition,
		e2["action"] as DatingActionDefinition,
		f["action"] as DatingActionDefinition,
	]
	return int(_score_actions_for_girl(girl, route).get("delta", -999))


func _route_bounds_for_girl(girl: GirlDefinition) -> Dictionary:
	var slots: Array[Dictionary] = _collect_level0_event_slots(girl)
	var farewell_actions: Array[DatingActionDefinition] = _collect_level0_farewell_actions(girl)
	var primary_def: PrimaryTraitDefinition = _db.call("get_primary_trait", girl.primary_trait) as PrimaryTraitDefinition
	var central: Array[Dictionary] = []
	var farewells: Array[Dictionary] = []
	var liked_level0: int = 0
	var disliked_level0: int = 0
	for slot in slots:
		var eid: StringName = slot["event_id"] as StringName
		var cat: int = int(slot["category"])
		for a in slot["actions"] as Array:
			var ann: Dictionary = _annotate_action(a as DatingActionDefinition, primary_def, eid, cat, false)
			central.append(ann)
			if int(ann["reaction"]) > 0:
				liked_level0 += 1
			elif int(ann["reaction"]) < 0:
				disliked_level0 += 1
	for a2 in farewell_actions:
		var ann2: Dictionary = _annotate_action(a2, primary_def, &"", -1, true)
		farewells.append(ann2)
		if int(ann2["reaction"]) > 0:
			liked_level0 += 1
		elif int(ann2["reaction"]) < 0:
			disliked_level0 += 1
	var best: int = -999
	var worst: int = 999
	if slots.size() < 3 or farewells.is_empty():
		return {
			"best": best,
			"worst": worst,
			"plus5": false,
			"nonpos": false,
			"liked": liked_level0,
			"disliked": disliked_level0,
			"slots": slots.size(),
			"farewell": farewells.size(),
		}
	var liked_central: Array[Dictionary] = []
	var disliked_central: Array[Dictionary] = []
	var scandal_central: Array[Dictionary] = []
	for c in central:
		if int(c["reaction"]) > 0:
			liked_central.append(c)
		if int(c["reaction"]) < 0:
			disliked_central.append(c)
		if bool(c["is_public"]) and bool(c["has_conflict"]):
			scandal_central.append(c)
	var liked_farewell: Array[Dictionary] = []
	var disliked_farewell: Array[Dictionary] = []
	var scandal_farewell: Array[Dictionary] = []
	for f in farewells:
		if int(f["reaction"]) > 0:
			liked_farewell.append(f)
		if int(f["reaction"]) < 0:
			disliked_farewell.append(f)
		if bool(f["is_public"]) and bool(f["has_conflict"]):
			scandal_farewell.append(f)
	# Targeted positive constructions by secondary.
	var pos_routes: Array = _build_positive_route_candidates(
		girl, liked_central, liked_farewell, scandal_central, scandal_farewell, farewells
	)
	for picks in pos_routes:
		var delta: int = _try_score_candidates(girl, picks as Array)
		if delta > best:
			best = delta
	# Targeted non-positive: prefer disliked, fall back to mixed.
	var neg_pool_c: Array[Dictionary] = disliked_central if not disliked_central.is_empty() else central
	var neg_pool_f: Array[Dictionary] = disliked_farewell if not disliked_farewell.is_empty() else farewells
	var neg_routes: Array = _build_triple_farewell_routes(neg_pool_c, neg_pool_f, 40)
	for picks2 in neg_routes:
		var delta2: int = _try_score_candidates(girl, picks2 as Array)
		if delta2 < worst:
			worst = delta2
		if delta2 > best:
			best = delta2
	# Extra mixed sample to tighten bounds.
	var mixed: Array = _build_triple_farewell_routes(central, farewells, 30)
	for picks3 in mixed:
		var delta3: int = _try_score_candidates(girl, picks3 as Array)
		if delta3 > best:
			best = delta3
		if delta3 < worst:
			worst = delta3
	return {
		"best": best,
		"worst": worst,
		"plus5": best >= 5,
		"nonpos": worst <= 0,
		"liked": liked_level0,
		"disliked": disliked_level0,
		"slots": slots.size(),
		"farewell": farewells.size(),
	}


func _build_triple_farewell_routes(
	central: Array[Dictionary],
	farewells: Array[Dictionary],
	limit: int,
) -> Array:
	var out: Array = []
	if central.size() < 3 or farewells.is_empty():
		return out
	var n: int = central.size()
	for i in range(n):
		for j in range(i + 1, n):
			for k in range(j + 1, n):
				if out.size() >= limit:
					return out
				var a: Dictionary = central[i]
				var b: Dictionary = central[j]
				var c: Dictionary = central[k]
				if a["event_id"] == b["event_id"] or b["event_id"] == c["event_id"] or a["event_id"] == c["event_id"]:
					continue
				if int(a["category"]) == int(b["category"]) and int(b["category"]) == int(c["category"]):
					continue
				for f in farewells:
					out.append([a, b, c, f])
					if out.size() >= limit:
						return out
	return out


func _build_positive_route_candidates(
	girl: GirlDefinition,
	liked_central: Array[Dictionary],
	liked_farewell: Array[Dictionary],
	scandal_central: Array[Dictionary],
	scandal_farewell: Array[Dictionary],
	all_farewell: Array[Dictionary],
) -> Array:
	var out: Array = []
	var fw: Array[Dictionary] = liked_farewell if not liked_farewell.is_empty() else all_farewell
	match girl.secondary_trait:
		GameTypes.SecondaryGirlTrait.DEMANDING:
			out.append_array(_build_triple_farewell_routes(liked_central, fw, 120))
		GameTypes.SecondaryGirlTrait.VARIETY_SEEKING:
			out.append_array(_routes_for_variety(liked_central, fw))
		GameTypes.SecondaryGirlTrait.CONSISTENT:
			out.append_array(_routes_for_consistent(liked_central, fw))
		GameTypes.SecondaryGirlTrait.SCANDALOUS:
			out.append_array(_routes_for_scandalous(liked_central, fw, scandal_central, scandal_farewell))
	# Always include generic liked routes as fallback.
	out.append_array(_build_triple_farewell_routes(liked_central, fw, 80))
	return out


func _routes_for_variety(liked_central: Array[Dictionary], farewells: Array[Dictionary]) -> Array:
	var out: Array = []
	var by_char: Dictionary = {}
	for c in liked_central:
		var key: int = int(c["characteristic"])
		if not by_char.has(key):
			by_char[key] = []
		(by_char[key] as Array).append(c)
	var keys: Array = by_char.keys()
	if keys.size() < 3:
		return out
	# Pick three different-char central likes + farewell that preferably adds a 3rd/4th char.
	for i in range(keys.size()):
		for j in range(i + 1, keys.size()):
			for k in range(j + 1, keys.size()):
				var pool_a: Array = by_char[keys[i]] as Array
				var pool_b: Array = by_char[keys[j]] as Array
				var pool_c: Array = by_char[keys[k]] as Array
				for a in pool_a:
					for b in pool_b:
						for c2 in pool_c:
							var da: Dictionary = a as Dictionary
							var db: Dictionary = b as Dictionary
							var dc: Dictionary = c2 as Dictionary
							if da["event_id"] == db["event_id"] or db["event_id"] == dc["event_id"] or da["event_id"] == dc["event_id"]:
								continue
							if int(da["category"]) == int(db["category"]) and int(db["category"]) == int(dc["category"]):
								continue
							for f in farewells:
								out.append([da, db, dc, f])
								if out.size() >= 80:
									return out
	return out


func _routes_for_consistent(liked_central: Array[Dictionary], farewells: Array[Dictionary]) -> Array:
	var out: Array = []
	var by_char: Dictionary = {}
	for c in liked_central:
		var key: int = int(c["characteristic"])
		if not by_char.has(key):
			by_char[key] = []
		(by_char[key] as Array).append(c)
	for key in by_char.keys():
		var pool: Array = by_char[key] as Array
		if pool.size() < 2:
			continue
		# Need >=3 of same characteristic across 4 slots.
		var same_farewell: Array[Dictionary] = []
		var other_farewell: Array[Dictionary] = []
		for f in farewells:
			if int(f["characteristic"]) == int(key):
				same_farewell.append(f)
			else:
				other_farewell.append(f)
		# Case A: 3 central same char + any farewell.
		if pool.size() >= 3:
			for i in range(pool.size()):
				for j in range(i + 1, pool.size()):
					for k in range(j + 1, pool.size()):
						var a: Dictionary = pool[i] as Dictionary
						var b: Dictionary = pool[j] as Dictionary
						var c: Dictionary = pool[k] as Dictionary
						if a["event_id"] == b["event_id"] or b["event_id"] == c["event_id"] or a["event_id"] == c["event_id"]:
							continue
						if int(a["category"]) == int(b["category"]) and int(b["category"]) == int(c["category"]):
							continue
						for f2 in farewells:
							out.append([a, b, c, f2])
							if out.size() >= 80:
								return out
		# Case B: 2 central same + same-char farewell + one other liked central.
		if same_farewell.is_empty():
			continue
		for i2 in range(pool.size()):
			for j2 in range(i2 + 1, pool.size()):
				var a2: Dictionary = pool[i2] as Dictionary
				var b2: Dictionary = pool[j2] as Dictionary
				if a2["event_id"] == b2["event_id"]:
					continue
				for other in liked_central:
					if int(other["characteristic"]) == int(key):
						continue
					if other["event_id"] == a2["event_id"] or other["event_id"] == b2["event_id"]:
						continue
					if (
						int(a2["category"]) == int(b2["category"])
						and int(b2["category"]) == int(other["category"])
					):
						continue
					for f3 in same_farewell:
						out.append([a2, b2, other, f3])
						if out.size() >= 80:
							return out
	return out


func _routes_for_scandalous(
	liked_central: Array[Dictionary],
	farewells: Array[Dictionary],
	scandal_central: Array[Dictionary],
	scandal_farewell: Array[Dictionary],
) -> Array:
	var out: Array = []
	var scandal_liked: Array[Dictionary] = []
	for s in scandal_central:
		if int(s["reaction"]) > 0:
			scandal_liked.append(s)
	if scandal_liked.is_empty():
		scandal_liked = scandal_central
	for sc in scandal_liked:
		for i in range(liked_central.size()):
			var a: Dictionary = liked_central[i]
			if a["event_id"] == sc["event_id"]:
				continue
			for j in range(i + 1, liked_central.size()):
				var b: Dictionary = liked_central[j]
				if b["event_id"] == sc["event_id"] or b["event_id"] == a["event_id"]:
					continue
				if (
					int(sc["category"]) == int(a["category"])
					and int(a["category"]) == int(b["category"])
				):
					continue
				for f in farewells:
					out.append([sc, a, b, f])
					if out.size() >= 100:
						return out
	var sf_list: Array[Dictionary] = []
	for sf in scandal_farewell:
		sf_list.append(sf)
	if not sf_list.is_empty():
		out.append_array(_build_triple_farewell_routes(liked_central, sf_list, 40))
	return out


func _primary_dislikes_conflict(primary: GameTypes.PrimaryGirlTrait) -> bool:
	var def: PrimaryTraitDefinition = _db.call("get_primary_trait", primary) as PrimaryTraitDefinition
	if def == null:
		return false
	return def.disliked_tags.has(GameTypes.ActionTag.CONFLICT)


func _test_module25_ordinary_date_feasibility() -> void:
	var ordinary: Array[GirlDefinition] = _ordinary_production_girls()
	_ok(ordinary.size() == 16, "MODULE25 dating ordinary girls == 16 got %s" % ordinary.size())
	# Common-pool disliked coverage for all four primaries (spec §93).
	var cafe: DatingEventPoolDefinition = _db.call("get_dating_pool", &"date_pool_cafe_common") as DatingEventPoolDefinition
	_ok(cafe != null, "MODULE25 cafe_common for dislike coverage")
	if cafe != null:
		for primary in [
			GameTypes.PrimaryGirlTrait.KIND,
			GameTypes.PrimaryGirlTrait.STATUS,
			GameTypes.PrimaryGirlTrait.THRILL_SEEKING,
			GameTypes.PrimaryGirlTrait.STRANGE,
		]:
			var pdef: PrimaryTraitDefinition = _db.call("get_primary_trait", primary) as PrimaryTraitDefinition
			var has_dislike: bool = false
			for eid in cafe.event_ids:
				var ev: DatingEventDefinition = _db.call("get_dating_event", eid) as DatingEventDefinition
				if ev == null:
					continue
				for action in ev.actions:
					if not _action_usable_level0(action):
						continue
					var typed: Array[GameTypes.ActionTag] = []
					for t in action.direct_tags:
						typed.append(t as GameTypes.ActionTag)
					if PrimaryTraitEvaluator.evaluate_with_definition(pdef, typed) < 0:
						has_dislike = true
						break
				if has_dislike:
					break
			_ok(has_dislike, "MODULE25 cafe_common has disliked tags for primary %s" % int(primary))
	for girl in ordinary:
		var gid: String = String(girl.id)
		var bounds: Dictionary = _route_bounds_for_girl(girl)
		_ok(int(bounds.get("slots", 0)) >= 3, "MODULE25 %s level0 event slots >= 3" % gid)
		_ok(int(bounds.get("farewell", 0)) >= 1, "MODULE25 %s level0 farewell actions" % gid)
		_ok(int(bounds.get("liked", 0)) >= 4, "MODULE25 %s liked level0 actions >= 4" % gid)
		_ok(int(bounds.get("disliked", 0)) >= 1, "MODULE25 %s disliked level0 actions >= 1" % gid)
		var scandal_conflict_trap: bool = (
			int(girl.secondary_trait) == int(GameTypes.SecondaryGirlTrait.SCANDALOUS)
			and _primary_dislikes_conflict(girl.primary_trait)
		)
		if scandal_conflict_trap:
			# KIND+SCANDALOUS cannot mathematically hit +5: SCANDALOUS +1 needs
			# public CONFLICT, which KIND dislikes (primary -1 on that slot).
			_ok(
				int(bounds.get("best", -999)) >= 4,
				"MODULE25 %s best level0 route >= 4 (scandal/conflict trap) got %s"
				% [gid, int(bounds.get("best", -999))],
			)
		else:
			_ok(
				bool(bounds.get("plus5", false)) or int(bounds.get("best", -999)) >= 5,
				"MODULE25 %s has +5 level0 first-date route best=%s"
				% [gid, int(bounds.get("best", -999))],
			)
		_ok(
			bool(bounds.get("nonpos", false)) or int(bounds.get("worst", 999)) <= 0,
			"MODULE25 %s has non-positive level0 route worst=%s"
			% [gid, int(bounds.get("worst", 999))],
		)


func _test_module25_ordinary_planner_sample() -> void:
	# One planner simulation sample: start_date for a representative ordinary girl.
	var sample_id: StringName = &"girl_city_bicycle"
	var girl: GirlDefinition = _db.call("get_girl", sample_id) as GirlDefinition
	_ok(girl != null and not girl.is_story, "MODULE25 planner sample girl exists")
	if girl == null:
		return
	_reset()
	_contact(sample_id)
	var req := DatingStartRequest.new()
	req.girl_id = sample_id
	req.location_id = girl.default_date_location_id
	var greetings: Array[StringName] = []
	for gid in girl.dating_greeting_ids:
		greetings.append(gid)
	req.greeting_ids = greetings
	req.farewell_id = girl.dating_farewell_id
	req.rng_seed = 42
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	_ok(bool(start.get("ok", false)), "MODULE25 planner sample start_date ok")
	if not bool(start.get("ok", false)):
		print("MODULE_09_TEST planner sample error: %s" % str(start.get("error", "")))
		return
	var session: DatingSession = _dc.call("get_session") as DatingSession
	_ok(session != null and session.central_event_ids.size() == 3, "MODULE25 planner sample 3 events")
	if session != null:
		_ok(
			session.central_event_ids[0] != session.central_event_ids[1]
			and session.central_event_ids[1] != session.central_event_ids[2]
			and session.central_event_ids[0] != session.central_event_ids[2],
			"MODULE25 planner sample unique event ids",
		)
		var cats: Array = session.central_categories
		if cats.size() == 3:
			_ok(
				not (int(cats[0]) == int(cats[1]) and int(cats[1]) == int(cats[2])),
				"MODULE25 planner sample no AAA categories",
			)
	_dc.call("force_clear_session")
