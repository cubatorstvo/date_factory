extends Node
## MODULE 24 domain save roundtrip tests (GameState / GameDay / CloneIncremental).
## Run: --path . --headless res://game/state/test/game_state_save_self_test.tscn


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _day: Node = null
var _ci: Node = null
var _money_signals: int = 0
var _girl_conquered_signals: int = 0
var _stage_signals: int = 0
var _day_advanced_signals: int = 0
var _state_restored_signals: int = 0
var _media_attention_signals: int = 0
var _clone_count_signals: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_day = get_node("/root/GameDay")
	_ci = get_node("/root/CloneIncremental")
	await get_tree().process_frame
	if _ci != null and _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	_connect_signals()
	_run_all()
	if _failed == 0:
		DfLog.info("MODULE_24_DOMAIN_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_24_DOMAIN_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_24_DOMAIN_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_24_DOMAIN_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _connect_signals() -> void:
	_gs.connect("money_changed", func(_v: int, _d: int) -> void: _money_signals += 1)
	_gs.connect("girl_conquered", func(_id: StringName) -> void: _girl_conquered_signals += 1)
	_gs.connect("stage_changed", func(_n: GameTypes.GameStage, _p: GameTypes.GameStage) -> void: _stage_signals += 1)
	_gs.connect("media_attention_changed", func(_v: int, _d: int) -> void: _media_attention_signals += 1)
	_gs.connect("clone_counts_changed", func(_t: int, _w: int, _d: int, _f: int) -> void: _clone_count_signals += 1)
	_gs.connect("state_restored", func() -> void: _state_restored_signals += 1)
	_day.connect("day_advanced", func(_d: int) -> void: _day_advanced_signals += 1)


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_24_DOMAIN_TEST] FAIL: %s" % label)
		print("MODULE_24_DOMAIN_TEST FAIL: %s" % label)


func _run_all() -> void:
	_test_demand_entry_codec()
	_test_game_day_restore_silent()
	_test_clone_runtime_roundtrip()
	_test_gamestate_exhaustive_roundtrip()
	_test_restore_is_silent()
	_test_invalid_restore_rejected()
	_test_sync_after_load_present()
	_gs.call("reset_for_new_game")


func _test_demand_entry_codec() -> void:
	var entry: DatingDemandEntry = DatingDemandEntry.new()
	entry.request_id = 7
	entry.girl_id = &"girl_neighbor"
	entry.created_day = 3
	entry.appointment_day = 4
	entry.slot = DatingOverloadTypes.DatingDemandSlot.LATE_EVENING
	entry.status = DatingOverloadTypes.DatingDemandStatus.WAITING
	entry.fulfilled_day = -1
	var encoded: Dictionary = _gs.call("encode_dating_demand_entry", entry) as Dictionary
	_ok(encoded.has("appointment_day"), "demand encode has appointment_day")
	_ok(not encoded.has("scheduled_day"), "demand encode has no scheduled_day")
	_ok(int(encoded["appointment_day"]) == 4, "demand encode appointment_day value")
	var decoded: DatingDemandEntry = _gs.call("decode_dating_demand_entry", encoded) as DatingDemandEntry
	_ok(decoded != null, "demand decode non-null")
	_ok(decoded.request_id == 7, "demand decode request_id")
	_ok(decoded.girl_id == &"girl_neighbor", "demand decode girl_id")
	_ok(decoded.appointment_day == 4, "demand decode appointment_day")
	_ok(decoded.slot == DatingOverloadTypes.DatingDemandSlot.LATE_EVENING, "demand decode slot")
	var bad: Dictionary = encoded.duplicate(true)
	bad.erase("appointment_day")
	bad["scheduled_day"] = 4
	_ok(_gs.call("decode_dating_demand_entry", bad) == null, "demand decode rejects scheduled_day-only")


func _test_game_day_restore_silent() -> void:
	_gs.call("reset_for_new_game")
	var before: int = _day_advanced_signals
	_ok(bool(_day.call("restore_day", 12)), "restore_day accepts 12")
	_ok(int(_day.call("get_current_day")) == 12, "restore_day value 12")
	_ok(_day_advanced_signals == before, "restore_day does not emit day_advanced")
	_ok(not bool(_day.call("restore_day", 0)), "restore_day rejects 0")
	_ok(int(_day.call("get_current_day")) == 12, "restore_day reject keeps day")


func _test_clone_runtime_roundtrip() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("set_clone_counts", 5, 2, 1)
	_gs.call("set_clone_production_upgrade_level", 1)
	_gs.call("set_clone_work_upgrade_level", 2)
	_ci.call("recalculate_rates")
	_ci.call("advance_simulation_for_test", 12.5)
	var exported: Dictionary = _ci.call("export_runtime_state") as Dictionary
	_ok(exported.has("production_elapsed_seconds"), "ci export elapsed")
	_ok(exported.has("money_fraction"), "ci export money_fraction")
	_ok(exported.has("date_fraction"), "ci export date_fraction")
	var elapsed_before: float = float(exported["production_elapsed_seconds"])
	var money_before: float = float(exported["money_fraction"])
	var date_before: float = float(exported["date_fraction"])
	_ok(elapsed_before > 0.0, "ci elapsed advanced")
	_gs.call("reset_for_new_game")
	_gs.call("set_clone_counts", 5, 2, 1)
	_gs.call("set_clone_production_upgrade_level", 1)
	_gs.call("set_clone_work_upgrade_level", 2)
	_ok(bool(_ci.call("restore_runtime_state", exported)), "ci restore ok")
	var again: Dictionary = _ci.call("export_runtime_state") as Dictionary
	_ok(is_equal_approx(float(again["production_elapsed_seconds"]), elapsed_before), "ci elapsed preserved")
	_ok(is_equal_approx(float(again["money_fraction"]), money_before), "ci money_fraction preserved")
	_ok(is_equal_approx(float(again["date_fraction"]), date_before), "ci date_fraction preserved")
	_ok(float(_gs.call("get_money_per_minute")) > 0.0, "ci rates recalculated after restore")
	_ok(not bool(_ci.call("restore_runtime_state", {"production_elapsed_seconds": -1.0, "money_fraction": 0.1, "date_fraction": 0.1})), "ci rejects negative elapsed")


func _mutate_many_fields() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_gs.call("add_money", 1234)
	_gs.call("add_authority", 7)
	_gs.call("add_experience", 20)
	_gs.call("spend_upgrade_points", 3)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.MUSCLE, 2)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.APPEARANCE, 3)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.CAPITAL, 1)
	_gs.call("restore_characteristic", GameTypes.PlayerCharacteristic.AURA, 4)
	_gs.call("restore_purchased_perks", ["perk_muscle_1", "perk_aura_1"])
	_gs.call("mark_rival_defeated", &"rival_actor")
	_gs.call("set_girl_relationship", &"girl_neighbor", 3)
	_gs.call("mark_girl_discovered", &"girl_neighbor")
	_gs.call("mark_girl_discovered", &"girl_scientist")
	_gs.call("add_girl_contact", &"girl_neighbor")
	_gs.call("reveal_girl_clue", &"girl_scientist", 0)
	_gs.call("reveal_girl_clue", &"girl_scientist", 2)
	_gs.call("reveal_primary_trait", &"girl_neighbor")
	_gs.call("reveal_secondary_trait", &"girl_neighbor")
	_gs.call("record_girl_known_reaction", &"girl_neighbor", &"gift_flowers", 1)
	_gs.call("set_girl_retry_days_remaining", &"girl_cafe", 2)
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_neighbor", 1)
	var played: Array[StringName] = [&"date_event_a", &"date_event_b"]
	_gs.call("record_girl_played_dating_events", &"girl_neighbor", played)
	_gs.call("mark_girl_conquered", &"girl_neighbor")
	_gs.call("unlock_location", &"location_lab")
	_gs.call("set_story_flag", &"flag_lab_seen", true)
	_gs.call("mark_salary_initialized")
	_gs.call("advance_salary_period_index")
	_gs.call("add_pending_salary", 50)
	_gs.call("mark_manual_salary_cycle_seen")
	_gs.call("set_salary_advance_used_period", 1)
	_gs.call("set_media_photo_pose", &"shot_1", &"pose_a")
	_gs.call("mark_media_photo_session_completed")
	_gs.call("add_media_attention", 14)
	_gs.call("mark_media_photo_published", &"shot_1")
	_gs.call("set_media_last_photo_publish_day", 5)
	_gs.call("add_media_incoming_offer", &"girl_park")
	_gs.call("mark_media_offer_read", &"girl_park")
	_gs.call("append_media_feed_event", &"feed_article_1")
	_gs.call("mark_dating_overload_started", 4)
	var demand: DatingDemandEntry = DatingDemandEntry.new()
	demand.request_id = int(_gs.call("allocate_dating_demand_request_id"))
	demand.girl_id = &"girl_park"
	demand.created_day = 4
	demand.appointment_day = 5
	demand.slot = DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING
	demand.status = DatingOverloadTypes.DatingDemandStatus.OVERDUE
	demand.fulfilled_day = -1
	_gs.call("append_dating_demand", demand)
	_gs.call("set_dating_overload_candidate_cursor", 2)
	_gs.call("set_dating_overload_last_personal_date_day", 5)
	_gs.call("increment_dating_overload_personal_dates_completed")
	_gs.call("set_dating_overload_last_feed_boost_day", 5)
	_gs.call("set_dating_overload_boost_pending", true)
	_gs.call("mark_dating_overload_problem_recognized")
	_gs.call("set_clone_counts", 10, 4, 3)
	_gs.call("set_clone_production_upgrade_level", 2)
	_gs.call("set_clone_work_upgrade_level", 1)
	_gs.call("set_clone_dating_upgrade_level", 3)
	_gs.call("set_world_reach", 42)
	_gs.call("set_global_upgrade_level", int(LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION), 1)
	_gs.call("set_global_upgrade_level", int(LateGameTypes.GlobalUpgradeType.GLOBAL_WORK), 2)
	_gs.call("set_global_upgrade_level", int(LateGameTypes.GlobalUpgradeType.GLOBAL_DATING), 1)
	_day.call("restore_day", 9)
	_ci.call("recalculate_rates")
	_ci.call("advance_simulation_for_test", 7.25)


func _test_gamestate_exhaustive_roundtrip() -> void:
	_mutate_many_fields()
	var exported: Dictionary = _gs.call("export_save_state") as Dictionary
	var runtime_exported: Dictionary = _ci.call("export_runtime_state") as Dictionary
	var day_before: int = int(_day.call("get_current_day"))
	_ok(not exported.has("money_per_minute"), "export omits derived money_per_minute")
	_ok(not exported.has("dates_per_minute"), "export omits derived dates_per_minute")
	var clones: Dictionary = exported["clones"] as Dictionary
	_ok(not clones.has("money_per_minute"), "clones omit derived rates")
	var overload: Dictionary = exported["dating_overload"] as Dictionary
	var req0: Dictionary = (overload["requests"] as Array)[0] as Dictionary
	_ok(req0.has("appointment_day"), "overload request uses appointment_day")
	_ok(not req0.has("scheduled_day"), "overload request omits scheduled_day")
	var json_text: String = JSON.stringify(exported)
	var parsed: Variant = JSON.parse_string(json_text)
	_ok(typeof(parsed) == TYPE_DICTIONARY, "export JSON roundtrip parses")
	var snapshot_before: Dictionary = exported.duplicate(true)
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_money")) == 0, "reset cleared money before restore")
	var restore_ok: bool = bool(_gs.call("restore_save_state", parsed as Dictionary))
	_ok(restore_ok, "restore_save_state succeeds")
	_ok(bool(_day.call("restore_day", day_before)), "restore_day after gs")
	_ok(bool(_ci.call("restore_runtime_state", runtime_exported)), "restore runtime after gs")
	var story: Node = get_node_or_null("/root/Story")
	var media: Node = get_node_or_null("/root/Media")
	var overload_svc: Node = get_node_or_null("/root/DatingOverload")
	var late: Node = get_node_or_null("/root/LateGameExpansion")
	if late != null and late.has_method("sync_after_load"):
		late.call("sync_after_load")
	if story != null and story.has_method("sync_after_load"):
		story.call("sync_after_load")
	if media != null and media.has_method("sync_after_load"):
		media.call("sync_after_load")
	if overload_svc != null and overload_svc.has_method("sync_after_load"):
		overload_svc.call("sync_after_load")
	var exported_after: Dictionary = _gs.call("export_save_state") as Dictionary
	_ok(_dicts_equal(snapshot_before, exported_after), "export equal after restore")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.STAGE_5), "stage restored")
	_ok(int(_gs.call("get_money")) == int(snapshot_before["money"]), "money restored")
	_ok(int(_gs.call("get_authority")) == int(snapshot_before["authority"]), "authority restored")
	_ok(int(_gs.call("get_experience")) == int(snapshot_before["experience"]), "experience restored")
	_ok(int(_gs.call("get_upgrade_points")) == int(snapshot_before["upgrade_points"]), "upgrade_points restored")
	_ok(int(_gs.call("get_muscle")) == 2, "muscle restored")
	_ok(bool(_gs.call("has_perk", &"perk_muscle_1")), "perk restored")
	_ok(bool(_gs.call("is_rival_defeated", &"rival_actor")), "rival restored")
	_ok(int(_gs.call("get_girl_relationship", &"girl_neighbor")) == 3, "relationship restored")
	_ok(bool(_gs.call("is_girl_conquered", &"girl_neighbor")), "conquered restored")
	_ok(bool(_gs.call("is_girl_discovered", &"girl_scientist")), "discovered restored")
	_ok(bool(_gs.call("has_girl_contact", &"girl_neighbor")), "contact restored")
	_ok(bool(_gs.call("is_girl_clue_known", &"girl_scientist", 2)), "clue restored")
	_ok(bool(_gs.call("is_primary_trait_revealed", &"girl_neighbor")), "primary trait restored")
	_ok(bool(_gs.call("is_secondary_trait_revealed", &"girl_neighbor")), "secondary trait restored")
	var reactions: Dictionary = _gs.call("get_girl_known_reactions", &"girl_neighbor") as Dictionary
	_ok(int(reactions.get(&"gift_flowers", 99)) == 1, "known reaction restored")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_cafe")) == 2, "retry days restored")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_neighbor")) == 1, "cooldown restored")
	var hist: Array = _gs.call("get_girl_played_dating_event_ids", &"girl_neighbor") as Array
	_ok(hist.size() == 2, "played events restored")
	_ok(bool(_gs.call("is_location_unlocked", &"location_lab")), "location restored")
	_ok(bool(_gs.call("get_story_flag", &"flag_lab_seen")), "story flag restored")
	_ok(bool(_gs.call("is_salary_initialized")), "salary initialized restored")
	_ok(int(_gs.call("get_pending_salary")) == 50, "pending salary restored")
	_ok(int(_gs.call("get_media_attention")) == 14, "media attention restored")
	_ok(bool(_gs.call("is_dating_overload_started")), "overload started restored")
	_ok(bool(_gs.call("is_dating_overload_problem_recognized")), "overload recognized restored")
	var demands: Array = _gs.call("get_dating_demand_entries") as Array
	_ok(demands.size() == 1, "demand entries restored")
	var d0: DatingDemandEntry = demands[0] as DatingDemandEntry
	_ok(d0 != null and d0.appointment_day == 5, "demand appointment_day restored")
	_ok(int(_gs.call("get_total_clones")) == 10, "clones total restored")
	_ok(int(_gs.call("get_clones_working")) == 4, "clones working restored")
	_ok(int(_gs.call("get_clone_dating_upgrade_level")) == 3, "local dating upgrade restored")
	_ok(int(_gs.call("get_world_reach")) == 42, "world reach restored")
	_ok(int(_gs.call("get_global_work_upgrade_level")) == 2, "global work upgrade restored")
	_ok(int(_day.call("get_current_day")) == 9, "day restored without advance")
	var runtime_after: Dictionary = _ci.call("export_runtime_state") as Dictionary
	_ok(is_equal_approx(float(runtime_after["production_elapsed_seconds"]), float(runtime_exported["production_elapsed_seconds"])), "runtime elapsed equal")
	_ok(is_equal_approx(float(runtime_after["money_fraction"]), float(runtime_exported["money_fraction"])), "runtime money_fraction equal")
	_ok(is_equal_approx(float(runtime_after["date_fraction"]), float(runtime_exported["date_fraction"])), "runtime date_fraction equal")


func _test_restore_is_silent() -> void:
	_mutate_many_fields()
	var payload: Dictionary = _gs.call("export_save_state") as Dictionary
	_gs.call("reset_for_new_game")
	var money_before: int = _money_signals
	var conquered_before: int = _girl_conquered_signals
	var stage_before: int = _stage_signals
	var media_before: int = _media_attention_signals
	var clones_before: int = _clone_count_signals
	var restored_before: int = _state_restored_signals
	var day_before_sig: int = _day_advanced_signals
	_ok(bool(_gs.call("restore_save_state", payload)), "silent restore ok")
	_ok(bool(_day.call("restore_day", 9)), "silent day restore ok")
	_ok(_money_signals == money_before, "restore emits no money_changed")
	_ok(_girl_conquered_signals == conquered_before, "restore emits no girl_conquered")
	_ok(_stage_signals == stage_before, "restore emits no stage_changed")
	_ok(_media_attention_signals == media_before, "restore emits no media_attention_changed")
	_ok(_clone_count_signals == clones_before, "restore emits no clone_counts_changed")
	_ok(_state_restored_signals == restored_before + 1, "restore emits state_restored once")
	_ok(_day_advanced_signals == day_before_sig, "day restore emits no day_advanced")


func _test_invalid_restore_rejected() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("add_money", 10)
	var before_money: int = int(_gs.call("get_money"))
	var bad: Dictionary = _gs.call("export_save_state") as Dictionary
	bad["money"] = -5
	_ok(not bool(_gs.call("restore_save_state", bad)), "rejects negative money")
	_ok(int(_gs.call("get_money")) == before_money, "rejected restore leaves state")
	var bad2: Dictionary = _gs.call("export_save_state") as Dictionary
	var clones: Dictionary = bad2["clones"] as Dictionary
	clones["working"] = 99
	clones["total"] = 1
	_ok(not bool(_gs.call("restore_save_state", bad2)), "rejects invalid clone invariant")


func _test_sync_after_load_present() -> void:
	var story: Node = get_node_or_null("/root/Story")
	var media: Node = get_node_or_null("/root/Media")
	var overload: Node = get_node_or_null("/root/DatingOverload")
	var late: Node = get_node_or_null("/root/LateGameExpansion")
	_ok(story != null and story.has_method("sync_after_load"), "Story.sync_after_load")
	_ok(media != null and media.has_method("sync_after_load"), "Media.sync_after_load")
	_ok(overload != null and overload.has_method("sync_after_load"), "DatingOverload.sync_after_load")
	_ok(late != null and late.has_method("sync_after_load"), "LateGame.sync_after_load")


func _dicts_equal(a: Dictionary, b: Dictionary) -> bool:
	return JSON.stringify(a) == JSON.stringify(b)
