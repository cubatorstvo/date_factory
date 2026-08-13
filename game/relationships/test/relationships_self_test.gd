extends Node
## MODULE 10 Relationships self-test (spec §§98–134).
## Run: res://game/relationships/test/relationships_test.tscn --quit-after 15000

var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _db: Node = null
var _dc: Node = null
var _rel: Node = null
var _gd: Node = null
var _completed_count: int = 0
var _available_again_count: int = 0
var _last_completed_girl: StringName = &""
var _date_id_seq: int = 1000


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_db = get_node("/root/ContentDB")
	_dc = get_node("/root/DatingCore")
	_rel = get_node("/root/Relationships")
	_gd = get_node("/root/GirlDiscovery")
	await get_tree().process_frame
	DatingTestFixtures.register_all(_db)
	if _rel.has_signal("girl_completed"):
		_rel.connect("girl_completed", _on_girl_completed)
	if _rel.has_signal("girl_date_available_again"):
		_rel.connect("girl_date_available_again", _on_date_available_again)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_10_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_10_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_10_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_10_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_girl_completed(girl_id: StringName, _result: RelationshipDateResult) -> void:
	_completed_count += 1
	_last_completed_girl = girl_id


func _on_date_available_again(_girl_id: StringName) -> void:
	_available_again_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_10_TEST] FAIL: %s" % label)
		print("MODULE_10_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_dc.call("force_clear_session")
	_dc.call("clear_external_resolver")
	_rel.call("clear_applied_date_ids")
	_rel.call("set_auto_apply_enabled", true)
	_completed_count = 0
	_available_again_count = 0
	_last_completed_girl = &""
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	rng.state = 0
	_rel.call("set_rng", rng)
	_dc.call("set_rng", rng)


func _contact(girl_id: StringName = &"girl_test_dating_kind") -> void:
	_gs.call("mark_girl_discovered", girl_id)
	_gs.call("add_girl_contact", girl_id)


func _make_result(
	girl_id: StringName,
	delta: int,
	events: Array[StringName] = [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"],
) -> DatingResult:
	var r := DatingResult.new()
	_date_id_seq += 1
	r.date_id = _date_id_seq
	r.girl_id = girl_id
	r.date_delta = delta
	r.central_event_ids = events.duplicate()
	return r


func _run_all() -> void:
	_test_clamp_positive()
	_test_clamp_negative()
	_test_first_plus5_reward()
	_test_repeat_plus5_no_reward()
	_test_conquered_persistence()
	_test_normalize_inconsistent()
	_test_cooldown_range()
	_test_cooldown_separate()
	_test_day_decrement()
	_test_availability_signal()
	_test_no_double_day()
	_test_history_record()
	_test_history_unique()
	_test_normal_exclusion()
	_test_cycle_exhaustion()
	_test_no_immediate_repeat_after_cycle()
	_test_second_insufficient()
	_test_perfect_first_records()
	_test_date_id_duplicate()
	_test_invalid_result()
	_test_invalid_central_ids()
	_test_zero_delta()
	_test_phone_relationship()
	_test_phone_cooldown()
	_test_phone_completion()
	_test_secondary_hidden()
	_test_secondary_reveal()
	_test_no_auto_trait_reveal()
	_test_dating_core_pure()
	_test_e2e_perfect()
	_test_e2e_negative()
	_test_exclusions_on_repeat()
	_test_availability_states()
	_test_date_invite()
	_test_pending_21_ready_at_2110()
	_test_date_bonus_span()
	_test_reset()
	_gs.call("reset_for_new_game")
	_dc.call("force_clear_session")


func _test_clamp_positive() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 4)
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 4)) as RelationshipDateResult
	_ok(r.ok, "98 apply ok")
	_ok(r.relationship_after == 5, "98 after 5")
	_ok(r.applied_delta == 1, "98 applied +1")
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 8)
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == 8, "98 GameState allows to 10")
	var r_span: RelationshipDateResult = _rel.call(
		"apply_date_result", _make_result(&"girl_test_dating_kind", 5)
	) as RelationshipDateResult
	_ok(r_span.ok and r_span.relationship_after == 5, "98 apply clamps to girl span 5")


func _test_clamp_negative() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", -4)
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", -4)) as RelationshipDateResult
	_ok(r.ok, "99 apply ok")
	_ok(r.relationship_after == -5, "99 after -5")
	_ok(r.applied_delta == -1, "99 applied -1")
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", -12)
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == -10, "99 GameState clamps to -10")
	var r_span_n: RelationshipDateResult = _rel.call(
		"apply_date_result", _make_result(&"girl_test_dating_kind", -5)
	) as RelationshipDateResult
	_ok(r_span_n.ok and r_span_n.relationship_after == -5, "99 apply clamps to girl span -5")


func _test_first_plus5_reward() -> void:
	_reset()
	_contact()
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 5)) as RelationshipDateResult
	_ok(r.ok and r.newly_conquered, "100 newly conquered")
	_ok(r.experience_gained == 1 and r.upgrade_points_gained == 1, "100 XP/UP +1")
	_ok(int(_gs.call("get_experience")) == 1, "100 xp field")
	_ok(int(_gs.call("get_upgrade_points")) == 1, "100 up field")
	_ok(bool(_gs.call("is_girl_conquered", &"girl_test_dating_kind")), "100 conquered")
	_ok(_completed_count == 1, "100 girl_completed signal")


func _test_repeat_plus5_no_reward() -> void:
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 5))
	var xp: int = int(_gs.call("get_experience"))
	var up: int = int(_gs.call("get_upgrade_points"))
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 3)
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 2)) as RelationshipDateResult
	_ok(r.ok and r.relationship_after == 5, "101 back to 5")
	_ok(not r.newly_conquered, "101 not newly")
	_ok(int(_gs.call("get_experience")) == xp, "101 xp unchanged")
	_ok(int(_gs.call("get_upgrade_points")) == up, "101 up unchanged")


func _test_conquered_persistence() -> void:
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 5))
	var xp: int = int(_gs.call("get_experience"))
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", -5, [&"date_event_test_conv_2", &"date_event_test_space_2", &"date_event_test_prop_2"]))
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == 0, "102 dropped")
	_ok(bool(_gs.call("is_girl_conquered", &"girl_test_dating_kind")), "102 still conquered")
	_ok(int(_gs.call("get_experience")) == xp, "102 xp unchanged")


func _test_normalize_inconsistent() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 5)
	_ok(not bool(_gs.call("is_girl_conquered", &"girl_test_dating_kind")), "103 setup")
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 0)) as RelationshipDateResult
	_ok(r.newly_conquered and r.experience_gained == 1, "103 normalize reward")


func _test_cooldown_range() -> void:
	_reset()
	_contact()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	rng.state = 0
	_rel.call("set_rng", rng)
	var seen: Dictionary = {}
	for i in range(30):
		var r: RelationshipDateResult = _rel.call(
			"apply_date_result",
			_make_result(&"girl_test_dating_kind", 0, [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]),
		) as RelationshipDateResult
		_ok(r.repeat_cooldown_days >= 1 and r.repeat_cooldown_days <= 3, "104 range %s" % r.repeat_cooldown_days)
		seen[r.repeat_cooldown_days] = true
	_ok(seen.has(1) and seen.has(2) and seen.has(3), "104 saw 1..3")


func _test_cooldown_separate() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_retry_days_remaining", &"girl_test_dating_kind", 2)
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 3)
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_dating_kind")) == 2, "105 discovery 2")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 3, "105 date 3")


func _test_day_decrement() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 3)
	_rel.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 2, "106 ->2")
	_rel.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 1, "106 ->1")
	_rel.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 0, "106 ->0")


func _test_availability_signal() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 1)
	_available_again_count = 0
	_rel.call("notify_game_day_advanced")
	_ok(_available_again_count == 1, "107 signal once")
	_rel.call("notify_game_day_advanced")
	_ok(_available_again_count == 1, "107 no second")


func _test_no_double_day() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_retry_days_remaining", &"girl_test_dating_kind", 3)
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 3)
	_gd.call("notify_game_day_advanced")
	_rel.call("notify_game_day_advanced")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_dating_kind")) == 2, "108 discovery once")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 2, "108 date once")


func _test_history_record() -> void:
	_reset()
	_contact()
	var evs: Array[StringName] = [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 1, evs))
	var hist: Array = _gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array
	var last: Array = _gs.call("get_girl_last_date_event_ids", &"girl_test_dating_kind") as Array
	_ok(hist.size() == 3 and last.size() == 3, "109 sizes")
	_ok(hist[0] == evs[0] and last[2] == evs[2], "109 content")


func _test_history_unique() -> void:
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 0, [&"e1", &"e2", &"e3"]))
	# e1..e3 not real content IDs — validation rejects unknown? central IDs don't need to exist in ContentDB
	# Wait — validation only checks size/unique/girl. Good.
	# But first apply used fake IDs — girl is known. OK.
	# Actually first call above used fake e1 — that's fine.
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 0, [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]))
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 0, [&"date_event_test_conv_1", &"date_event_test_conv_2", &"date_event_test_space_2"]))
	var hist: Array = _gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array
	_ok(hist.size() == 5, "110 unique size 5 got %s" % hist.size())
	var last: Array = _gs.call("get_girl_last_date_event_ids", &"girl_test_dating_kind") as Array
	_ok(last.size() == 3 and last[0] == &"date_event_test_conv_1", "110 last date")


func _test_normal_exclusion() -> void:
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 0))
	var ex: Array = _rel.call("get_event_exclusions_for_next_date", &"girl_test_dating_kind") as Array
	_ok(ex.size() == 3, "111 exclusions = history")


func _test_cycle_exhaustion() -> void:
	_reset()
	_contact()
	# Fill history with many events so planner is insufficient, then cycle reset.
	var all_ids: Array[StringName] = []
	for ev in _db.call("list_dating_events") as Array:
		var def: DatingEventDefinition = ev as DatingEventDefinition
		if def != null:
			all_ids.append(def.id)
	if all_ids.is_empty():
		# fixtures register via overrides; gather from known test IDs
		all_ids = [
			&"date_event_test_conv_1", &"date_event_test_conv_2", &"date_event_test_conv_3", &"date_event_test_conv_4",
			&"date_event_test_space_1", &"date_event_test_space_2", &"date_event_test_space_3", &"date_event_test_space_4",
			&"date_event_test_prop_1", &"date_event_test_prop_2", &"date_event_test_prop_3", &"date_event_test_prop_4",
		]
	_gs.call("record_girl_played_dating_events", &"girl_test_dating_kind", all_ids)
	# ensure last date is 3 ids
	var last3: Array[StringName] = [all_ids[0], all_ids[1], all_ids[2]]
	_gs.call("record_girl_played_dating_events", &"girl_test_dating_kind", last3)
	var before_hist: Array = _gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array
	_ok(before_hist.size() >= 3, "112 history filled")
	var after_reset: Array = _rel.call("begin_new_event_cycle", &"girl_test_dating_kind") as Array
	var hist2: Array = _gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array
	_ok(hist2.is_empty(), "112 history cleared")
	_ok(after_reset.size() == 3, "112 exclusions = last 3")


func _test_no_immediate_repeat_after_cycle() -> void:
	_reset()
	_contact()
	var last3: Array[StringName] = [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]
	_gs.call("record_girl_played_dating_events", &"girl_test_dating_kind", last3)
	var excl_raw: Array = _rel.call("begin_new_event_cycle", &"girl_test_dating_kind") as Array
	var excl: Array[StringName] = []
	for e in excl_raw:
		excl.append(e as StringName)
	var req: DatingStartRequest = DatingTestFixtures.default_request()
	req.excluded_event_ids = excl
	req.rng_seed = 11
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	_ok(bool(start.get("ok", false)), "113 start after cycle")
	if bool(start.get("ok", false)):
		var session: DatingSession = _dc.call("get_session") as DatingSession
		for eid in session.central_event_ids:
			_ok(not excl.has(eid), "113 no immediate repeat %s" % String(eid))
	_dc.call("force_clear_session")


func _test_second_insufficient() -> void:
	_reset()
	_contact(&"girl_test_dating_thin")
	# Thin pool has 1 event — any exclusion of that event or full history fails.
	var thin_hist: Array[StringName] = [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]
	_gs.call("record_girl_played_dating_events", &"girl_test_dating_thin", thin_hist)
	var req: DatingStartRequest = DatingTestFixtures.default_request(&"girl_test_dating_thin")
	var res: Dictionary = _rel.call("start_date_with_history", req) as Dictionary
	_ok(not bool(res.get("ok", true)), "114 still insufficient")
	_ok(res.get("error", &"") == DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT, "114 error code")
	var last: Array = _gs.call("get_girl_last_date_event_ids", &"girl_test_dating_thin") as Array
	_ok(last.size() == 3, "114 last preserved")


func _test_perfect_first_records() -> void:
	_reset()
	_contact()
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 5)) as RelationshipDateResult
	_ok(r.ok and r.newly_conquered, "115 complete")
	_ok((_gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array).size() == 3, "115 history")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) > 0, "115 cooldown")


func _test_date_id_duplicate() -> void:
	_reset()
	_contact()
	var dr: DatingResult = _make_result(&"girl_test_dating_kind", 2)
	var r1: RelationshipDateResult = _rel.call("apply_date_result", dr) as RelationshipDateResult
	var rel_before: int = int(_gs.call("get_girl_relationship", &"girl_test_dating_kind"))
	var r2: RelationshipDateResult = _rel.call("apply_date_result", dr) as RelationshipDateResult
	_ok(r1.ok and not r2.ok, "116 first ok second fail")
	_ok(r2.error == RelationshipTypes.ERR_ALREADY_APPLIED, "116 ALREADY_APPLIED")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == rel_before, "116 no second mutation")


func _test_invalid_result() -> void:
	_reset()
	_contact()
	var dr: DatingResult = _make_result(&"girl_test_dating_kind", 6)
	var r_ok_bonus: RelationshipDateResult = _rel.call("apply_date_result", dr) as RelationshipDateResult
	_ok(r_ok_bonus.ok and r_ok_bonus.relationship_after == 5, "117 bonus delta 6 applies with span clamp")
	_reset()
	_contact()
	var bad: DatingResult = _make_result(&"girl_test_dating_kind", 99)
	var r: RelationshipDateResult = _rel.call("apply_date_result", bad) as RelationshipDateResult
	_ok(not r.ok, "117 reject delta 99")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == 0, "117 no mutation")


func _test_invalid_central_ids() -> void:
	_reset()
	_contact()
	var dr := DatingResult.new()
	_date_id_seq += 1
	dr.date_id = _date_id_seq
	dr.girl_id = &"girl_test_dating_kind"
	dr.date_delta = 1
	dr.central_event_ids = [&"a", &"b"]
	var r: RelationshipDateResult = _rel.call("apply_date_result", dr) as RelationshipDateResult
	_ok(not r.ok, "118 reject 2 ids")
	dr.central_event_ids = [&"a", &"a", &"b"]
	_date_id_seq += 1
	dr.date_id = _date_id_seq
	var r2: RelationshipDateResult = _rel.call("apply_date_result", dr) as RelationshipDateResult
	_ok(not r2.ok, "118 reject dupes")


func _test_zero_delta() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 2)
	var r: RelationshipDateResult = _rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 0)) as RelationshipDateResult
	_ok(r.ok and r.relationship_after == 2 and r.applied_delta == 0, "119 same rel")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) > 0, "119 cooldown")
	_ok((_gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array).size() == 3, "119 history")


func _phone_detail(girl_id: StringName) -> String:
	var journal_scene: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	var journal: PhoneJournal = journal_scene.instantiate() as PhoneJournal
	add_child(journal)
	journal.open()
	journal.select_girl_by_id(girl_id)
	var text: String = journal.get_detail_text()
	journal.queue_free()
	return text


func _test_phone_relationship() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", -3)
	var text: String = _phone_detail(&"girl_test_dating_kind")
	_ok(text.contains("Отношения: -3 / 5") or text.contains("Отношения: +-3 / 5"), "120 phone rel got: %s" % text.substr(0, 80))
	# %+d for -3 is "-3"
	_ok(text.contains("-3 / 5"), "120 signed -3")


func _test_phone_cooldown() -> void:
	_reset()
	_contact()
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 3)
	var text: String = _phone_detail(&"girl_test_dating_kind")
	_ok(text.contains("через 3 дн."), "121 cooldown 3")
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 0)
	text = _phone_detail(&"girl_test_dating_kind")
	_ok(text.contains("доступно"), "121 available")


func _test_phone_completion() -> void:
	_reset()
	_contact()
	_gs.call("mark_girl_conquered", &"girl_test_dating_kind")
	var text: String = _phone_detail(&"girl_test_dating_kind")
	_ok(text.contains("Отношения завершены"), "122 completion label")


func _test_secondary_hidden() -> void:
	_reset()
	_contact()
	_ok(not bool(_gs.call("is_secondary_trait_revealed", &"girl_test_dating_kind")), "123 flag false")
	var text: String = _phone_detail(&"girl_test_dating_kind")
	_ok(text.contains("Доп. черта: ?"), "123 hidden")
	_ok(not text.contains("Требовательная"), "123 no name")


func _test_secondary_reveal() -> void:
	_reset()
	_contact()
	_ok(bool(_gs.call("reveal_secondary_trait", &"girl_test_dating_kind")), "124 reveal")
	var text: String = _phone_detail(&"girl_test_dating_kind")
	_ok(text.contains("Требовательная"), "124 shows name")


func _test_no_auto_trait_reveal() -> void:
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 5))
	_ok(not bool(_gs.call("is_primary_trait_revealed", &"girl_test_dating_kind")), "125 no primary")
	_ok(not bool(_gs.call("is_secondary_trait_revealed", &"girl_test_dating_kind")), "125 no secondary")


func _test_dating_core_pure() -> void:
	var src := FileAccess.open("res://game/dating/dating_core.gd", FileAccess.READ)
	_ok(src != null, "126 read core")
	var text: String = src.get_as_text() if src != null else ""
	_ok(not text.contains("add_girl_relationship"), "126 no add_girl_relationship")
	_ok(not text.contains("set_girl_relationship"), "126 no set_girl_relationship")
	_ok(not text.contains("mark_girl_conquered"), "126 no mark_girl_conquered")
	_ok(not text.contains("add_experience"), "126 no add_experience")


func _force_events(ids: Array[StringName]) -> void:
	var req: DatingStartRequest = DatingTestFixtures.default_request()
	req.rng_seed = 42
	var start: Dictionary = _dc.call("start_date", req) as Dictionary
	_ok(bool(start.get("ok", false)), "force start")
	var session: DatingSession = _dc.call("get_session") as DatingSession
	if session != null:
		session.central_event_ids = ids.duplicate()


func _play_scripted(action_ids: Array[StringName]) -> DatingResult:
	_force_events([&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	for aid in action_ids:
		var res: Dictionary = _dc.call("select_action", aid) as Dictionary
		if bool(res.get("encore", false)):
			_dc.call("resolve_encore", false)
		if bool(res.get("waiting", false)):
			var ext := DatingActionExecutionResult.new()
			ext.outcome = DatingTypes.ExecutionOutcome.SUCCESS
			_dc.call("submit_action_execution_result", ext)
	var s: DatingSession = _dc.call("get_session") as DatingSession
	return s.result if s != null else null


func _test_e2e_perfect() -> void:
	_reset()
	_contact()
	_rel.call("set_auto_apply_enabled", true)
	var result: DatingResult = _play_scripted([
		&"action_test_care",
		&"action_test_private_care",
		&"action_test_simplicity",
		&"action_test_farewell_care",
	])
	_ok(result != null and result.trait_delta == 5, "127 trait_delta +5")
	_ok(result != null and result.venue_quality_bonus == 1, "127 cafe quality +1")
	_ok(result != null and result.date_delta == 6, "127 date_delta +6 with cafe")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == 5, "127 rel span-clamped 5")
	_ok(bool(_gs.call("is_girl_conquered", &"girl_test_dating_kind")), "127 conquered")
	_ok(int(_gs.call("get_experience")) == 1, "127 xp")
	_ok(int(_gs.call("get_upgrade_points")) == 1, "127 up")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) > 0, "127 cd")
	_ok((_gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array).size() == 3, "127 hist")
	_ok(result.date_id > 0, "127 date_id")


func _test_e2e_negative() -> void:
	_reset()
	_contact()
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 3)
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 2)
	_force_events([&"date_event_test_conv_2", &"date_event_test_space_1", &"date_event_test_prop_2"])
	_dc.call("continue_arrival")
	_dc.call("select_greeting", &"dating_greeting_test_simple")
	_dc.call("select_action", &"action_test_muscle_gate")
	_dc.call("select_action", &"action_test_public_conflict")
	_dc.call("select_action", &"action_test_dominance")
	_dc.call("select_action", &"action_test_farewell_dislike")
	var s: DatingSession = _dc.call("get_session") as DatingSession
	var neg: DatingResult = s.result if s != null else null
	_ok(neg != null and neg.trait_delta == -5, "128 trait -5")
	_ok(neg != null and neg.venue_quality_bonus == 1, "128 cafe quality +1")
	_ok(neg != null and neg.date_delta == -4, "128 delta -4 with cafe")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == -2, "128 rel -2")
	_ok(int(_gs.call("get_experience")) == 0, "128 no xp")


func _test_exclusions_on_repeat() -> void:
	_reset()
	_contact()
	var first_ids: Array[StringName] = [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 1, first_ids))
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 0)
	var req: DatingStartRequest = DatingTestFixtures.default_request()
	var start: Dictionary = _rel.call("start_date_with_history", req) as Dictionary
	_ok(bool(start.get("ok", false)), "129 start B")
	if bool(start.get("ok", false)):
		var session: DatingSession = _dc.call("get_session") as DatingSession
		for eid in first_ids:
			_ok(not session.central_event_ids.has(eid), "129 excluded %s" % String(eid))
	_dc.call("force_clear_session")


func _test_availability_states() -> void:
	_reset()
	var a0: Dictionary = _rel.call("get_date_availability", &"girl_test_dating_kind") as Dictionary
	_ok(a0.get("status", &"") == RelationshipTypes.AVAIL_NO_CONTACT, "130 NO_CONTACT")
	_ok(not bool(_rel.call("can_start_date", &"girl_test_dating_kind")), "130 can false")
	_contact()
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 2)
	var a1: Dictionary = _rel.call("get_date_availability", &"girl_test_dating_kind") as Dictionary
	_ok(a1.get("status", &"") == RelationshipTypes.AVAIL_COOLDOWN, "131 COOLDOWN")
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 0)
	var a2: Dictionary = _rel.call("get_date_availability", &"girl_test_dating_kind") as Dictionary
	_ok(a2.get("status", &"") == RelationshipTypes.AVAIL_AVAILABLE, "132 AVAILABLE")
	_gs.call("mark_girl_conquered", &"girl_test_dating_kind")
	var a3: Dictionary = _rel.call("get_date_availability", &"girl_test_dating_kind") as Dictionary
	_ok(a3.get("status", &"") == RelationshipTypes.AVAIL_AVAILABLE, "133 conquered available")
	var a4: Dictionary = _rel.call("get_date_availability", &"no_such_girl_xyz") as Dictionary
	_ok(a4.get("status", &"") == RelationshipTypes.AVAIL_UNKNOWN_GIRL, "133 unknown")


func _test_date_invite() -> void:
	_reset()
	var day: Node = get_node_or_null("/root/GameDay")
	_ok(_rel.has_method("get_date_invite_venues"), "invite venues api")
	_ok(_rel.has_method("get_date_invite_hours"), "invite hours api")
	_ok(_rel.has_method("confirm_date_invite"), "invite confirm api")
	var hours: Array = _rel.call("get_date_invite_hours") as Array
	_ok(hours.size() == 4, "invite hours count")
	if hours.size() >= 4:
		var first: Dictionary = hours[0] as Dictionary
		_ok(int(first.get("hour", 0)) == 12, "first invite hour 12")
		_ok(str(first.get("label", "")) == "12:00", "hour label 12:00")
		_ok(not bool(first.get("next_day", true)), "12 next_day false at 8")
	if day != null:
		day.call("restore_hour", 18)
	var hours_late: Array = _rel.call("get_date_invite_hours") as Array
	if hours_late.size() >= 4:
		var h12: Dictionary = hours_late[0] as Dictionary
		var h18: Dictionary = hours_late[2] as Dictionary
		var h21: Dictionary = hours_late[3] as Dictionary
		_ok(bool(h12.get("next_day", false)), "12 next_day after 18")
		_ok(bool(h18.get("next_day", false)), "18 next_day at 18")
		_ok(not bool(h21.get("next_day", true)), "21 same day after 18")
	if day != null:
		day.call("restore_hour", 8)
	var venues: Array = _rel.call("get_date_invite_venues") as Array
	_ok(venues.size() == 8, "invite venues count 8")
	var by_loc: Dictionary = {}
	for row_v in venues:
		var row: Dictionary = row_v as Dictionary
		by_loc[row.get("location_id", &"")] = row
	_ok(by_loc.has(&"apartment") and by_loc.has(&"cafe") and by_loc.has(&"restaurant"), "core venues")
	_ok(by_loc.has(&"park") and by_loc.has(&"cinema") and by_loc.has(&"arcade"), "thematic venues a")
	_ok(by_loc.has(&"museum") and by_loc.has(&"planetarium"), "thematic venues b")
	if by_loc.has(&"apartment"):
		var home: Dictionary = by_loc[&"apartment"] as Dictionary
		_ok(str(home.get("label", "")) == "Дома", "home label")
		_ok(int(home.get("cost", -1)) == 0, "home cost 0")
		_ok(bool(home.get("available", false)), "home available")
	if by_loc.has(&"cafe"):
		var cafe: Dictionary = by_loc[&"cafe"] as Dictionary
		_ok(str(cafe.get("label", "")) == "Кафе", "cafe label")
		_ok(int(cafe.get("cost", -1)) == 30, "cafe cost 30")
		_ok(bool(cafe.get("available", false)), "cafe available for invite")
	if by_loc.has(&"restaurant"):
		_ok(int((by_loc[&"restaurant"] as Dictionary).get("cost", -1)) == 100, "restaurant cost 100")
	if by_loc.has(&"park"):
		_ok(int((by_loc[&"park"] as Dictionary).get("cost", -1)) == 40, "park cost 40")
	var empty: Dictionary = _rel.call("confirm_date_invite", &"", &"apartment", 12) as Dictionary
	_ok(not bool(empty.get("ok", true)), "empty girl fail")
	var no_contact: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"apartment", 12
	) as Dictionary
	_ok(not bool(no_contact.get("ok", true)), "no contact fail")
	_ok(no_contact.get("error", &"") == DatingTypes.ERR_NO_CONTACT, "no contact error")
	var final_t: Dictionary = _rel.call(
		"confirm_date_invite", StoryIds.GIRL_FINAL_TARGET, &"apartment", 12
	) as Dictionary
	_ok(not bool(final_t.get("ok", true)), "final target skip")
	_contact()
	var bad_hour: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"apartment", 10
	) as Dictionary
	_ok(not bool(bad_hour.get("ok", true)), "bad hour fail")
	_ok(bad_hour.get("error", &"") == DatingTypes.ERR_INVALID_HOUR, "bad hour error")
	var bad_loc: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"gym", 12
	) as Dictionary
	_ok(not bool(bad_loc.get("ok", true)), "bad location fail")
	var money_home_before: int = int(_gs.call("get_money"))
	var home_try: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"apartment", 12
	) as Dictionary
	_ok(bool(home_try.get("ok", false)), "home invite books without travel")
	_ok(int(_gs.call("get_money")) == money_home_before, "home invite cost 0")
	_ok(bool(home_try.get("pending", false)), "home invite pending")
	var pending_home: Dictionary = _rel.call("get_pending_date_invite") as Dictionary
	_ok(pending_home.get("location_id", &"") == &"apartment", "pending home location")
	_ok(_dc.call("get_session") == null or not bool(_dc.call("is_date_active")), "no date session yet")
	var cafe_blocked: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"cafe", 12
	) as Dictionary
	_ok(not bool(cafe_blocked.get("ok", true)), "second invite blocked while pending")
	_ok(cafe_blocked.get("error", &"") == DatingTypes.ERR_INVITE_PENDING, "pending error")
	_reset()
	_contact()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	var money_now: int = int(_gs.call("get_money"))
	if money_now > 29:
		_gs.call("spend_money", money_now - 29)
	var money_poor: int = int(_gs.call("get_money"))
	var poor: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"cafe", 12
	) as Dictionary
	_ok(not bool(poor.get("ok", true)), "cafe unaffordable fail")
	_ok(poor.get("error", &"") == DatingTypes.ERR_CANNOT_AFFORD, "cafe unaffordable error")
	_ok(int(_gs.call("get_money")) == money_poor, "cafe unaffordable money unchanged")
	_reset()
	_contact()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_1)
	var money_cafe_before: int = int(_gs.call("get_money"))
	var cafe_try: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"cafe", 15
	) as Dictionary
	_ok(bool(cafe_try.get("ok", false)), "cafe invite books")
	_ok(int(_gs.call("get_money")) == money_cafe_before - 30, "cafe cost 30")
	_ok(bool(cafe_try.get("pending", false)), "cafe booked pending")
	var pending_ok: Dictionary = _rel.call("get_pending_date_invite") as Dictionary
	_ok(pending_ok.get("location_id", &"") == &"cafe", "pending cafe after paid invite")
	_ok(_dc.call("get_session") == null or not bool(_dc.call("is_date_active")), "paid invite no session")
	var day_node: Node = get_node_or_null("/root/GameDay")
	if day_node != null:
		_ok(int(day_node.call("get_current_hour")) == 8, "invite does not jump hour")


func _test_pending_21_ready_at_2110() -> void:
	_reset()
	_contact()
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null:
		return
	day.call("restore_hour", 8)
	day.call("restore_minute", 0)
	var booked: Dictionary = _rel.call(
		"confirm_date_invite", &"girl_test_dating_kind", &"apartment", 21
	) as Dictionary
	_ok(bool(booked.get("ok", false)), "book 21:00 home")
	day.call("restore_hour", 21)
	day.call("restore_minute", 10)
	var peek: Dictionary = _rel.call("peek_pending_date_status", &"apartment") as Dictionary
	_ok(bool(peek.get("ready", false)), "21:10 ready for 21:00")
	_ok(not bool(peek.get("too_early", true)), "21:10 not too early")
	var started: Dictionary = _rel.call("try_start_pending_date_at", &"apartment") as Dictionary
	var err: StringName = started.get("error", &"") as StringName
	_ok(err != DatingTypes.ERR_DATE_TOO_EARLY, "21:10 not TOO_EARLY")
	_ok(err != DatingTypes.ERR_DATE_MISSED, "21:10 not DATE_MISSED")
	_ok(err != DatingTypes.ERR_NO_PENDING, "21:10 pending still there")
	if bool(_dc.call("is_date_active")):
		_dc.call("force_clear_session")
	day.call("restore_hour", 8)
	day.call("restore_minute", 0)


func _test_date_bonus_span() -> void:
	_reset()
	_contact()
	var girl: GirlDefinition = _db.call("get_girl", &"girl_test_dating_kind") as GirlDefinition
	_ok(girl != null and int(girl.relationship_span) == 5, "test girl span 5")
	girl.relationship_span = 10
	_gs.call("set_girl_relationship", &"girl_test_dating_kind", 8)
	var r10: RelationshipDateResult = _rel.call(
		"apply_date_result", _make_result(&"girl_test_dating_kind", 5)
	) as RelationshipDateResult
	_ok(r10.ok and r10.relationship_after == 10, "span10 apply to 10")
	_ok(r10.newly_conquered, "span10 conquer at 10")
	girl.relationship_span = 5
	_ok(DateVenueCatalog.quality_bonus(&"apartment") == 0, "apartment quality stub 0")
	_ok(DateVenueCatalog.quality_bonus(&"restaurant") == 2, "restaurant quality 2")
	_ok(DateVenueCatalog.invite_cost(&"park") == 40, "park invite 40")
	_ok(DateVenueCatalog.outfit_bonus(&"luxury") == 2, "luxury outfit +2")
	_ok(DateVenueCatalog.outfit_bonus(&"unknown") == 0, "unknown outfit 0")
	_ok(ApartmentWardrobeCatalog.ITEMS.size() == 3, "wardrobe 3 outfits")


func _test_reset() -> void:
	_reset()
	_contact()
	_rel.call("apply_date_result", _make_result(&"girl_test_dating_kind", 5))
	_gs.call("reveal_secondary_trait", &"girl_test_dating_kind")
	var applied_id: int = _date_id_seq
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_girl_relationship", &"girl_test_dating_kind")) == 0, "134 rel cleared")
	_ok(not bool(_gs.call("is_girl_conquered", &"girl_test_dating_kind")), "134 conquered cleared")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 0, "134 date cd")
	_ok((_gs.call("get_girl_played_dating_event_ids", &"girl_test_dating_kind") as Array).is_empty(), "134 hist")
	_ok((_gs.call("get_girl_last_date_event_ids", &"girl_test_dating_kind") as Array).is_empty(), "134 last")
	_ok(not bool(_gs.call("is_secondary_trait_revealed", &"girl_test_dating_kind")), "134 secondary")
	# applied ids cleared — same date_id can apply again after contact
	_contact()
	var dr := DatingResult.new()
	dr.date_id = applied_id
	dr.girl_id = &"girl_test_dating_kind"
	dr.date_delta = 1
	dr.central_event_ids = [&"date_event_test_conv_1", &"date_event_test_space_1", &"date_event_test_prop_1"]
	var r: RelationshipDateResult = _rel.call("apply_date_result", dr) as RelationshipDateResult
	_ok(r.ok, "134 applied ids cleared")
