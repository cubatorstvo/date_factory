extends Node
## MODULE 16 Dating Overload self-test (M16_A_CORE + M16_B phone helpers).
## Run: res://game/dating_overload/test/dating_overload_test.tscn --quit-after 40000


var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _gs: Node = null
var _day: Node = null
var _media: Node = null
var _rel: Node = null
var _overload: Node = null
var _story: Node = null
var _content: Node = null
var _date_id_seq: int = 1000
var _started_count: int = 0
var _clone_needed_count: int = 0
var _recognized_count: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_day = get_node("/root/GameDay")
	_media = get_node("/root/Media")
	_rel = get_node("/root/Relationships")
	_overload = get_node("/root/DatingOverload")
	_story = get_node("/root/Story")
	_content = get_node("/root/ContentDB")
	await get_tree().process_frame
	if _overload.has_signal("overload_started") and not _overload.is_connected("overload_started", _on_started):
		_overload.connect("overload_started", _on_started)
	if _overload.has_signal("clone_solution_needed") and not _overload.is_connected("clone_solution_needed", _on_clone_needed):
		_overload.connect("clone_solution_needed", _on_clone_needed)
	if _overload.has_signal("problem_recognized") and not _overload.is_connected("problem_recognized", _on_recognized):
		_overload.connect("problem_recognized", _on_recognized)
	_run_all()
	if _failed == 0:
		DfLog.info("MODULE_16_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_16_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_16_TEST PASS: %s" % label)
	else:
		DfLog.error("MODULE_16_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_16_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_started() -> void:
	_started_count += 1


func _on_clone_needed() -> void:
	_clone_needed_count += 1


func _on_recognized() -> void:
	_recognized_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_16_TEST] FAIL: %s" % label)
		print("MODULE_16_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_started_count = 0
	_clone_needed_count = 0
	_recognized_count = 0
	if _rel.has_method("clear_applied_date_ids"):
		_rel.call("clear_applied_date_ids")


func _seed_stage4_media_ready(attention: int = 45, offers: int = 3) -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_4)
	_gs.call("add_experience", 4)
	_gs.call("mark_media_photo_session_completed")
	var candidates: Array[StringName] = [
		&"girl_appearance_flash",
		&"girl_public_sculpture",
		&"girl_cafe_receipt_notes",
		&"girl_gym_chalk",
	]
	for i in range(mini(offers, candidates.size())):
		var gid: StringName = candidates[i]
		_gs.call("add_girl_contact", gid)
		_gs.call("add_media_incoming_offer", gid)
	_gs.call("set_media_attention", attention)
	# Media attention change emits overload_ready → DatingOverload activates when ready.
	if attention >= 45 and offers >= 3:
		# Ensure activation even if signal already fired before listener in prior state.
		if _overload.has_method("_ensure_started_from_media"):
			_overload.call("_ensure_started_from_media")


func _make_result(girl_id: StringName, delta: int = 0) -> DatingResult:
	var r: DatingResult = DatingResult.new()
	_date_id_seq += 1
	r.date_id = _date_id_seq
	r.girl_id = girl_id
	r.date_delta = delta
	var evs: Array[StringName] = [
		StringName("date_event_m16_%s_a" % _date_id_seq),
		StringName("date_event_m16_%s_b" % _date_id_seq),
		StringName("date_event_m16_%s_c" % _date_id_seq),
	]
	r.central_event_ids = evs
	return r


func _complete_date(girl_id: StringName, delta: int = 0) -> RelationshipDateResult:
	_gs.call("set_girl_date_cooldown_days_remaining", girl_id, 0)
	return _rel.call("apply_date_result", _make_result(girl_id, delta)) as RelationshipDateResult


func _entries() -> Array:
	return _gs.call("get_dating_demand_entries") as Array


func _run_all() -> void:
	_test_inactive_before_ready()
	_test_activation_slots()
	_test_activation_idempotent()
	_test_capacity_before_overload()
	_test_capacity_after_overload()
	_test_capacity_next_day()
	_test_fulfill_matching()
	_test_fulfill_one_of_multiple()
	_test_unrelated_consumes()
	_test_bad_date_fulfills()
	_test_aging_and_wave()
	_test_feed_boost()
	_test_boosted_wave()
	_test_recognition_gates()
	_test_recognition_requires_date()
	_test_recognition_once_and_stops()
	_test_cap_persists_after_recognition()
	_test_boost_disabled_after_recognition()
	_test_stage_unchanged()
	_test_no_scientist()
	_test_status_snapshot()
	_test_date_venue_annotation()
	_test_phone_overload_helpers()
	_test_reset()
	_reset()


func _test_inactive_before_ready() -> void:
	_seed_stage4_media_ready(35, 2)
	_ok(not bool(_overload.call("is_started")), "110 inactive started false")
	_ok(_entries().is_empty(), "110 no demand")
	_ok(bool(_overload.call("can_start_personal_date")), "110 no date cap")


func _test_activation_slots() -> void:
	_seed_stage4_media_ready(45, 3)
	_ok(bool(_overload.call("is_started")), "111 started")
	_ok(int(_gs.call("get_dating_overload_start_day")) == int(_day.call("get_current_day")), "111 start_day")
	var entries: Array = _entries()
	_ok(entries.size() == 3, "111 three requests")
	_ok(int(_overload.call("get_backlog_count")) == 3, "111 backlog3")
	if entries.size() >= 3:
		var e0: DatingDemandEntry = entries[0] as DatingDemandEntry
		var e1: DatingDemandEntry = entries[1] as DatingDemandEntry
		var e2: DatingDemandEntry = entries[2] as DatingDemandEntry
		_ok(e0.slot == DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING, "113 EARLY1")
		_ok(e1.slot == DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING, "113 EARLY2")
		_ok(e2.slot == DatingOverloadTypes.DatingDemandSlot.LATE_EVENING, "113 LATE")
		var current: int = int(_day.call("get_current_day"))
		_ok(e0.appointment_day == current and e1.appointment_day == current and e2.appointment_day == current, "111 appointment today")
		_ok(e0.girl_id == &"girl_appearance_flash", "111 cycle A")
		_ok(e1.girl_id == &"girl_public_sculpture", "111 cycle B")
		_ok(e2.girl_id == &"girl_cafe_receipt_notes", "111 cycle C")


func _test_activation_idempotent() -> void:
	_seed_stage4_media_ready(45, 3)
	var before: int = _entries().size()
	_started_count = 0
	_gs.call("add_media_attention", 5)
	if _overload.has_method("_ensure_started_from_media"):
		_overload.call("_ensure_started_from_media")
	_ok(_entries().size() == before and before == 3, "112 idempotent 3 only")
	_ok(_started_count == 0, "112 no re-emit")


func _test_capacity_before_overload() -> void:
	_seed_stage4_media_ready(35, 2)
	var gid: StringName = &"girl_appearance_flash"
	_gs.call("add_girl_contact", gid)
	var r1: RelationshipDateResult = _complete_date(gid, 1)
	_ok(r1 != null and r1.ok, "114 first date ok")
	_gs.call("set_girl_date_cooldown_days_remaining", gid, 0)
	var r2: RelationshipDateResult = _complete_date(gid, 0)
	_ok(r2 != null and r2.ok, "114 second same day ok")
	_ok(bool(_overload.call("can_start_personal_date")), "114 still no overload cap")


func _test_capacity_after_overload() -> void:
	_seed_stage4_media_ready(45, 3)
	var gid: StringName = &"girl_appearance_flash"
	var other: StringName = &"girl_public_sculpture"
	var r1: RelationshipDateResult = _complete_date(gid, 1)
	_ok(r1 != null and r1.ok, "115 complete one")
	_ok(not bool(_overload.call("can_start_personal_date")), "115 capacity used")
	# Cooldown is checked before body capacity for the same girl; use another available contact.
	_gs.call("set_girl_date_cooldown_days_remaining", other, 0)
	var avail: Dictionary = _rel.call("get_date_availability", other) as Dictionary
	_ok(avail.get("status", &"") == DatingOverloadTypes.AVAIL_BODY_CAPACITY_USED, "115 BODY_CAPACITY_USED")
	var req: DatingStartRequest = DatingStartRequest.new()
	req.girl_id = other
	req.location_id = &"cafe"
	var start: Dictionary = _rel.call("start_date_with_history", req) as Dictionary
	_ok(not bool(start.get("ok", true)), "115 start blocked")
	_ok(start.get("error", &"") == DatingOverloadTypes.AVAIL_BODY_CAPACITY_USED, "115 start error")


func _test_capacity_next_day() -> void:
	_seed_stage4_media_ready(45, 3)
	var gid: StringName = &"girl_appearance_flash"
	_complete_date(gid, 0)
	_ok(not bool(_overload.call("can_start_personal_date")), "116 used today")
	_day.call("advance_day")
	_ok(bool(_overload.call("can_start_personal_date")), "116 next day available")


func _test_fulfill_matching() -> void:
	_seed_stage4_media_ready(45, 3)
	var entries: Array = _entries()
	var a: DatingDemandEntry = entries[0] as DatingDemandEntry
	var b: DatingDemandEntry = entries[1] as DatingDemandEntry
	_complete_date(a.girl_id, 1)
	var after: Array = _entries()
	var a2: DatingDemandEntry = null
	var b2: DatingDemandEntry = null
	for item in after:
		var e: DatingDemandEntry = item as DatingDemandEntry
		if e.request_id == a.request_id:
			a2 = e
		if e.request_id == b.request_id:
			b2 = e
	_ok(a2 != null and a2.status == DatingOverloadTypes.DatingDemandStatus.FULFILLED, "118 A fulfilled")
	_ok(b2 != null and b2.is_backlog(), "118 B active")
	_ok(int(_overload.call("get_backlog_count")) == 2, "118 backlog2")


func _test_fulfill_one_of_multiple() -> void:
	_seed_stage4_media_ready(45, 3)
	# Force two demands for same girl by advancing with only one offer? Instead append manually via cycle.
	# After activation offers A,B,C — complete none, advance day adds A,B again → A has request1 and request4.
	_day.call("advance_day")
	var gid: StringName = &"girl_appearance_flash"
	var before_active: int = int(_overload.call("get_demand_count_for_girl", gid))
	_ok(before_active >= 2, "119 multiple A demands")
	_complete_date(gid, 0)
	var after_active: int = int(_overload.call("get_demand_count_for_girl", gid))
	_ok(after_active == before_active - 1, "119 one fulfilled only")


func _test_unrelated_consumes() -> void:
	_seed_stage4_media_ready(45, 3)
	var backlog_before: int = int(_overload.call("get_backlog_count"))
	var other: StringName = &"girl_gym_chalk"
	_gs.call("add_girl_contact", other)
	_complete_date(other, 0)
	_ok(not bool(_overload.call("can_start_personal_date")), "120 capacity consumed")
	_ok(int(_overload.call("get_backlog_count")) == backlog_before, "120 backlog unchanged")


func _test_bad_date_fulfills() -> void:
	_seed_stage4_media_ready(45, 3)
	var gid: StringName = &"girl_appearance_flash"
	_complete_date(gid, -5)
	var entries: Array = _entries()
	var found: bool = false
	for item in entries:
		var e: DatingDemandEntry = item as DatingDemandEntry
		if e.girl_id == gid and e.status == DatingOverloadTypes.DatingDemandStatus.FULFILLED:
			found = true
	_ok(found, "121 bad date fulfills")


func _test_aging_and_wave() -> void:
	_seed_stage4_media_ready(45, 3)
	var day0: int = int(_day.call("get_current_day"))
	_day.call("advance_day")
	var entries: Array = _entries()
	overdue_count_check(entries, day0)
	var waiting_today: int = 0
	for item in entries:
		var e: DatingDemandEntry = item as DatingDemandEntry
		if e.status == DatingOverloadTypes.DatingDemandStatus.WAITING and e.appointment_day == int(_day.call("get_current_day")):
			waiting_today += 1
	_ok(waiting_today == 2, "123 base wave +2")
	_ok(entries.size() == 5, "123 total 5")
	var early_late: bool = false
	var saw_early: bool = false
	var saw_late: bool = false
	for item2 in entries:
		var e2: DatingDemandEntry = item2 as DatingDemandEntry
		if e2.created_day == int(_day.call("get_current_day")):
			if e2.slot == DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING:
				saw_early = true
			if e2.slot == DatingOverloadTypes.DatingDemandSlot.LATE_EVENING:
				saw_late = true
	early_late = saw_early and saw_late
	_ok(early_late, "123 EARLY/LATE pattern")


func overdue_count_check(entries: Array, _day0: int) -> void:
	var overdue_n: int = 0
	for item in entries:
		var e: DatingDemandEntry = item as DatingDemandEntry
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			overdue_n += 1
	_ok(overdue_n == 3, "122 aged to OVERDUE")


func _test_feed_boost() -> void:
	_seed_stage4_media_ready(45, 3)
	var att_before: int = int(_gs.call("get_media_attention"))
	_ok(bool(_overload.call("can_use_feed_boost")), "125 boost available")
	_ok(bool(_overload.call("use_feed_boost")), "125 use ok")
	_ok(int(_gs.call("get_media_attention")) == att_before + 5, "125 +5 attention")
	_ok(bool(_gs.call("is_dating_overload_boost_pending")), "125 boost_pending")
	_ok(not bool(_overload.call("can_use_feed_boost")), "125 second rejected")
	_ok(not bool(_overload.call("use_feed_boost")), "125 second use false")


func _test_boosted_wave() -> void:
	_seed_stage4_media_ready(45, 3)
	_overload.call("use_feed_boost")
	_day.call("advance_day")
	var created_today: int = 0
	var early_n: int = 0
	var late_n: int = 0
	var current: int = int(_day.call("get_current_day"))
	for item in _entries():
		var e: DatingDemandEntry = item as DatingDemandEntry
		if e.created_day == current:
			created_today += 1
			if e.slot == DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING:
				early_n += 1
			if e.slot == DatingOverloadTypes.DatingDemandSlot.LATE_EVENING:
				late_n += 1
	_ok(created_today == 3, "126 boosted +3")
	_ok(early_n == 2 and late_n == 1, "126 EARLY/EARLY/LATE")
	_ok(not bool(_gs.call("is_dating_overload_boost_pending")), "126 pending cleared")


func _test_recognition_gates() -> void:
	_seed_stage4_media_ready(45, 3)
	# Generate huge backlog same day without advancing — still false.
	_gs.call("set_dating_overload_boost_pending", true)
	# Can't force more without day advance; check day gate after artificial personal date + days.
	_complete_date(&"girl_appearance_flash", 0)
	_ok(not bool(_overload.call("is_problem_recognized")), "129 same day false")
	_day.call("advance_day")
	_ok(not bool(_overload.call("is_problem_recognized")), "129 start+1 false")


func _test_recognition_requires_date() -> void:
	_seed_stage4_media_ready(45, 3)
	# Advance without dates: day+1 (+2), day+2 (+2) => generated 7, backlog 7, personal 0
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_overload.call("get_total_generated")) >= 7, "130 generated>=7")
	_ok(int(_overload.call("get_backlog_count")) >= 4, "130 backlog>=4")
	_ok(int(_gs.call("get_dating_overload_personal_dates_completed")) == 0, "130 personal0")
	_ok(not bool(_overload.call("is_problem_recognized")), "130 no recognition without date")
	_complete_date(&"girl_public_sculpture", 0)
	_ok(bool(_overload.call("is_problem_recognized")), "130 recognizes after date")


func _test_recognition_once_and_stops() -> void:
	_seed_stage4_media_ready(45, 3)
	_clone_needed_count = 0
	_recognized_count = 0
	_complete_date(&"girl_appearance_flash", 0)
	_day.call("advance_day")
	_day.call("advance_day")
	# May already be recognized on second advance if conditions met after wave; ensure recognized.
	if not bool(_overload.call("is_problem_recognized")):
		_complete_date(&"girl_public_sculpture", 0)
	_ok(bool(_overload.call("is_problem_recognized")), "131 recognized")
	_ok(_clone_needed_count == 1, "131 clone_solution_needed once")
	_ok(_recognized_count == 1, "131 problem_recognized once")
	var gen_before: int = int(_overload.call("get_total_generated"))
	var backlog_before: int = int(_overload.call("get_backlog_count"))
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_overload.call("get_total_generated")) == gen_before, "132 no new demand")
	_ok(int(_overload.call("get_backlog_count")) == backlog_before, "132 backlog remains")
	_ok(_clone_needed_count == 1, "131 no second signal")


func _test_cap_persists_after_recognition() -> void:
	_seed_stage4_media_ready(45, 3)
	_complete_date(&"girl_appearance_flash", 0)
	_day.call("advance_day")
	_day.call("advance_day")
	if not bool(_overload.call("is_problem_recognized")):
		_gs.call("set_girl_date_cooldown_days_remaining", &"girl_public_sculpture", 0)
		_complete_date(&"girl_public_sculpture", 0)
	_ok(bool(_overload.call("is_problem_recognized")), "133 recognized")
	# If capacity already used today by recognition date, good; else complete one more day cycle.
	if bool(_overload.call("can_start_personal_date")):
		_day.call("advance_day")
		_complete_date(&"girl_cafe_receipt_notes", 0)
	_ok(not bool(_overload.call("can_start_personal_date")), "133 cap persists")


func _test_boost_disabled_after_recognition() -> void:
	_seed_stage4_media_ready(45, 3)
	_complete_date(&"girl_appearance_flash", 0)
	_day.call("advance_day")
	_day.call("advance_day")
	if not bool(_overload.call("is_problem_recognized")):
		_complete_date(&"girl_public_sculpture", 0)
	_ok(bool(_overload.call("is_problem_recognized")), "134 recognized")
	_ok(not bool(_overload.call("can_use_feed_boost")), "134 boost disabled")
	_ok(not bool(_overload.call("use_feed_boost")), "134 boost use rejected")


func _test_stage_unchanged() -> void:
	_seed_stage4_media_ready(45, 3)
	_complete_date(&"girl_appearance_flash", 0)
	_day.call("advance_day")
	_day.call("advance_day")
	if not bool(_overload.call("is_problem_recognized")):
		_complete_date(&"girl_public_sculpture", 0)
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_4), "135 STAGE_4")


func _test_no_scientist() -> void:
	_reset()
	var girl: Variant = null
	if _content.has_method("try_get_girl"):
		girl = _content.call("try_get_girl", &"girl_scientist")
	elif _content.has_method("get_girl"):
		girl = _content.call("get_girl", &"girl_scientist")
	_ok(girl == null, "136 no scientist")
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.LABORATORY)), "137 no lab")


func _test_status_snapshot() -> void:
	_seed_stage4_media_ready(45, 3)
	var status: DatingOverloadStatus = _overload.call("get_status") as DatingOverloadStatus
	_ok(status != null and status.active, "96 status active")
	_ok(status.backlog_count == 3, "96 backlog3")
	_ok(status.capacity_per_day == 1, "96 capacity1")
	_ok(status.capacity_used_today == 0, "96 unused")
	_ok(status.feed_boost_available, "96 boost available")
	_ok(not status.problem_recognized, "96 not recognized")


func _test_date_venue_annotation() -> void:
	_seed_stage4_media_ready(45, 3)
	var venue: DateVenueInteractable = DateVenueInteractable.new()
	add_child(venue)
	# Force cafe location via World if possible; otherwise call _build_rows with cafe.
	var rows: Array = venue.call("_build_rows", &"cafe") as Array
	var saw_demand: bool = false
	for row in rows:
		var label: String = str(row.get("label", ""))
		if label.contains("спрос:"):
			saw_demand = true
	_ok(saw_demand, "141 DateVenue demand annotation")
	venue.queue_free()


func _test_phone_overload_helpers() -> void:
	_seed_stage4_media_ready(45, 3)
	var packed: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	_ok(packed != null, "phone scene load")
	if packed == null:
		return
	var phone: PhoneJournal = packed.instantiate() as PhoneJournal
	_ok(phone != null, "phone instantiate")
	if phone == null:
		return
	add_child(phone)
	phone.open(null)
	_ok(phone.has_media_section_visible(), "phone MEDIA preserved")
	_ok(phone.has_overload_section_visible(), "phone OVERLOAD visible")
	var summary: String = phone.get_overload_summary_text()
	_ok(summary.contains("Невыполненный спрос: 3"), "phone backlog 3")
	_ok(summary.contains("Сегодня уже посещено: 0/1"), "phone capacity unused")
	_ok(phone.get_overload_demand_row_count() == 3, "phone demand rows 3")
	_ok(phone.is_overload_boost_visible(), "phone boost visible")
	_ok(phone.is_overload_boost_enabled(), "phone boost enabled")
	_ok(phone.get_overload_boost_button_text().contains("Поднять волну"), "phone boost label")
	var story: String = phone.get_story_text()
	_ok(story.contains("Лично успеваешь: 1 / день"), "phone story §66 capacity")
	_ok(story.contains("Спрос растёт быстрее тебя"), "phone story §66 demand")
	_ok(bool(_overload.call("use_feed_boost")), "phone boost use")
	phone.refresh()
	_ok(phone.get_overload_boost_button_text().contains("Волна поднята"), "phone boost used label")
	_ok(not phone.is_overload_boost_enabled(), "phone boost disabled same day")
	# Recognition path: hide boost, story §67, realization on open.
	_complete_date(&"girl_appearance_flash", 0)
	_day.call("advance_day")
	_day.call("advance_day")
	if not bool(_overload.call("is_problem_recognized")):
		_complete_date(&"girl_public_sculpture", 0)
	_ok(bool(_overload.call("is_problem_recognized")), "phone recognition ready")
	phone.close()
	phone.open(null)
	_ok(not phone.is_overload_boost_visible(), "phone boost hidden after recognition")
	var story_after: String = phone.get_story_text()
	_ok(story_after.contains(DatingOverloadTypes.REALIZATION_LINE_1), "phone story §67 line1")
	_ok(story_after.contains(DatingOverloadTypes.REALIZATION_LINE_2), "phone story §67 line2")
	_ok(phone.was_realization_presented(), "phone realization presented")
	_ok(phone.has_media_section_visible(), "phone MEDIA still visible")
	phone.close()
	phone.queue_free()


func _test_reset() -> void:
	_seed_stage4_media_ready(45, 3)
	_complete_date(&"girl_appearance_flash", 0)
	_overload.call("use_feed_boost")
	_gs.call("reset_for_new_game")
	_ok(not bool(_gs.call("is_dating_overload_started")), "143 started false")
	_ok((_gs.call("get_dating_demand_entries") as Array).is_empty(), "143 requests empty")
	_ok(int(_gs.call("get_dating_overload_last_personal_date_day")) == -1, "143 last day -1")
	_ok(not bool(_gs.call("is_dating_overload_boost_pending")), "143 boost reset")
	_ok(not bool(_gs.call("is_dating_overload_problem_recognized")), "143 recognized false")
	_ok(int(_gs.call("get_dating_overload_candidate_cursor")) == 0, "143 cursor0")
