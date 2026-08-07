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
	var journal_script: Script = load("res://ui/phone/phone_journal.gd") as Script
	var journal: Node = journal_script.new()
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
