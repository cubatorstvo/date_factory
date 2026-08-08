extends Node
## MODULE 20 LateGameExpansion core self-test (spec §§95–106, 109–111, 114).
## Run: res://game/late_game/test/late_game_test.tscn --quit-after 60000


var _failed: int = 0
var _passed: int = 0
var _pass_labels: Array[String] = []
var _gs: Node = null
var _lge: Node = null
var _ci: Node = null
var _story: Node = null
var _day: Node = null
var _overload: Node = null
var _completed_count: int = 0
var _final_signal_count: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_lge = get_node("/root/LateGameExpansion")
	_ci = get_node("/root/CloneIncremental")
	_story = get_node("/root/Story")
	_day = get_node("/root/GameDay")
	_overload = get_node("/root/DatingOverload")
	await get_tree().process_frame
	if _ci.has_method("set_realtime_simulation"):
		_ci.call("set_realtime_simulation", false)
	if _lge.has_signal("world_expansion_completed") and not _lge.is_connected("world_expansion_completed", _on_completed):
		_lge.connect("world_expansion_completed", _on_completed)
	if _lge.has_signal("final_target_detected") and not _lge.is_connected("final_target_detected", _on_final):
		_lge.connect("final_target_detected", _on_final)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_20_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_20_TEST: ALL PASS (%s)" % _passed)
		for label in _pass_labels:
			print("MODULE_20_TEST PASS: %s" % label)
	else:
		DfLog.error("MODULE_20_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_20_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_completed() -> void:
	_completed_count += 1


func _on_final() -> void:
	_final_signal_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
		_pass_labels.append(label)
	else:
		_failed += 1
		push_error("[MODULE_20_TEST] FAIL: %s" % label)
		print("MODULE_20_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_completed_count = 0
	_final_signal_count = 0


func _enter_stage6() -> void:
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)


func _set_clones(total: int, working: int, dating: int) -> void:
	_gs.call("set_clone_counts", total, working, dating)
	_ci.call("recalculate_rates")


func _run_all() -> void:
	_test_autoload_present()
	_test_inactive_stage5()
	_test_stage6_initial()
	_test_reach_from_late_xp()
	_test_no_reach_from_backlog()
	_test_multipliers_and_costs()
	_test_effective_rates()
	_test_elapsed_preserved()
	_test_optional_events()
	_test_completion()
	_test_terminal_prompts()
	_test_no_module_21()
	_test_reset()
	await _test_phone_stage5_to_finale()
	await _test_president_anchor_and_discovery_gate()
	_reset()


func _test_autoload_present() -> void:
	_ok(_lge != null, "autoload LateGameExpansion present")
	_ok(_lge.has_method("get_production_multiplier"), "has get_production_multiplier")
	_ok(_lge.has_method("buy_global_upgrade"), "has buy_global_upgrade")
	_ok(_lge.has_method("add_reach"), "has add_reach")
	_ok(_ci.has_method("refresh_external_modifiers"), "CloneIncremental.refresh_external_modifiers")


func _test_inactive_stage5() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_set_clones(2, 1, 1)
	_ok(is_equal_approx(float(_lge.call("get_production_multiplier")), 1.0), "95 prod ×1")
	_ok(is_equal_approx(float(_lge.call("get_work_multiplier")), 1.0), "95 work ×1")
	_ok(is_equal_approx(float(_lge.call("get_dating_multiplier")), 1.0), "95 dating ×1")
	var buy: GlobalUpgradePurchaseResult = _lge.call(
		"buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION
	) as GlobalUpgradePurchaseResult
	_ok(buy != null and not buy.ok and buy.error == LateGameTypes.GlobalUpgradePurchaseError.LOCKED, "95 purchase LOCKED")
	var reach0: int = int(_gs.call("get_world_reach"))
	_ci.emit_signal("late_experience_granted", 1)
	_ok(int(_gs.call("get_world_reach")) == reach0, "95 Reach unchanged Stage5")


func _test_stage6_initial() -> void:
	_reset()
	_gs.call("add_experience", 500)
	_enter_stage6()
	_ok(int(_gs.call("get_world_reach")) == 0, "96 Reach0")
	_ok(int(_gs.call("get_global_production_upgrade_level")) == 0, "96 prod0")
	_ok(int(_gs.call("get_global_work_upgrade_level")) == 0, "96 work0")
	_ok(int(_gs.call("get_global_dating_upgrade_level")) == 0, "96 dating0")
	_ok(is_equal_approx(float(_lge.call("get_production_multiplier")), 1.0), "96 mult1")
	_ok(is_equal_approx(float(_lge.call("get_work_multiplier")), 1.0), "96 work1")
	_ok(is_equal_approx(float(_lge.call("get_dating_multiplier")), 1.0), "96 dating1")


func _test_reach_from_late_xp() -> void:
	_reset()
	_enter_stage6()
	_ci.emit_signal("late_experience_granted", 1)
	_ok(int(_gs.call("get_world_reach")) == 2, "97 +2 Reach")
	_ci.emit_signal("late_experience_granted", 5)
	_ok(int(_gs.call("get_world_reach")) == 12, "97 +10 Reach")
	_gs.call("set_world_reach", 99)
	_ci.emit_signal("late_experience_granted", 5)
	_ok(int(_gs.call("get_world_reach")) == 100, "97 clamp100")


func _test_no_reach_from_backlog() -> void:
	_reset()
	_enter_stage6()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_6)
	if not bool(_gs.call("is_dating_overload_started")):
		_gs.call("mark_dating_overload_started", int(_day.call("get_current_day")))
	var entry: DatingDemandEntry = DatingDemandEntry.new()
	entry.request_id = int(_gs.call("allocate_dating_demand_request_id"))
	entry.girl_id = &"girl_appearance_flash"
	entry.created_day = int(_day.call("get_current_day"))
	entry.appointment_day = int(_day.call("get_current_day"))
	entry.slot = DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING
	entry.status = DatingOverloadTypes.DatingDemandStatus.WAITING
	entry.fulfilled_day = -1
	_gs.call("append_dating_demand", entry)
	_set_clones(1, 0, 1)
	var reach0: int = int(_gs.call("get_world_reach"))
	# 0.5 dpm => 1 date in 120s; backlog fulfill does not emit late_experience_granted.
	_ci.call("advance_simulation_for_test", 120.0)
	_ok(int(_overload.call("get_backlog_count")) == 0, "98 backlog cleared")
	_ok(int(_gs.call("get_world_reach")) == reach0, "98 Reach unchanged by backlog")


func _test_multipliers_and_costs() -> void:
	_reset()
	_enter_stage6()
	_gs.call("add_money", 100000)
	var expected_mult: Array[float] = [1.0, 2.0, 4.0, 8.0]
	var costs: Array[int] = [1000, 5000, 25000]
	for i in range(4):
		_ok(
			is_equal_approx(float(_lge.call("get_production_multiplier")), expected_mult[i]),
			"100 prod ×%s" % expected_mult[i]
		)
		if i < 3:
			_ok(int(_lge.call("get_upgrade_cost", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION)) == costs[i], "101 cost %s" % costs[i])
			var buy: GlobalUpgradePurchaseResult = _lge.call(
				"buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION
			) as GlobalUpgradePurchaseResult
			_ok(buy != null and buy.ok and buy.money_spent == costs[i], "101 buy L%s" % (i + 1))
	var maxed: GlobalUpgradePurchaseResult = _lge.call(
		"buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION
	) as GlobalUpgradePurchaseResult
	_ok(maxed != null and maxed.error == LateGameTypes.GlobalUpgradePurchaseError.MAX_LEVEL, "101 MAX")
	# Independent tracks.
	_ok(int(_lge.call("get_upgrade_cost", LateGameTypes.GlobalUpgradeType.GLOBAL_WORK)) == 1000, "101 work cost independent")
	_ok(int(_lge.call("get_upgrade_cost", LateGameTypes.GlobalUpgradeType.GLOBAL_DATING)) == 1000, "101 dating cost independent")


func _test_effective_rates() -> void:
	_reset()
	_enter_stage6()
	_set_clones(1, 0, 0)
	_gs.call("set_clone_production_upgrade_level", 4) # local interval 10
	_ci.call("recalculate_rates")
	_ok(is_equal_approx(float(_ci.call("get_production_interval")), 10.0), "102 local10 global1")
	_gs.call("add_money", 100000)
	_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION) # ×2
	_ok(is_equal_approx(float(_ci.call("get_production_interval")), 5.0), "102 local10 global2 =>5")
	_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION) # ×4
	_ok(is_equal_approx(float(_ci.call("get_production_interval")), 2.5), "102 local10 global4 =>2.5")
	_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION) # ×8
	_ok(is_equal_approx(float(_ci.call("get_production_interval")), 1.25), "102 local10 global8 =>1.25")
	_gs.call("set_clone_production_upgrade_level", 5) # local 5
	_ci.call("refresh_external_modifiers")
	_ok(is_equal_approx(float(_ci.call("get_production_interval")), 0.625), "102 local5 global8 =>0.625")
	# Work / dating multipliers.
	_reset()
	_enter_stage6()
	_set_clones(10, 10, 0)
	_gs.call("set_clone_work_upgrade_level", 5)
	_ci.call("recalculate_rates")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 700.0), "103 local700")
	_gs.call("add_money", 100000)
	_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_WORK)
	_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_WORK) # ×4
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 2800.0), "103 effective2800")
	_reset()
	_enter_stage6()
	_set_clones(10, 0, 10)
	_gs.call("set_clone_dating_upgrade_level", 2)
	_ci.call("recalculate_rates")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 10.0), "104 local10")
	_gs.call("add_money", 100000)
	for _i in range(3):
		_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_DATING)
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 80.0), "104 effective80")


func _test_elapsed_preserved() -> void:
	_reset()
	_enter_stage6()
	_set_clones(1, 0, 0)
	_gs.call("set_clone_production_upgrade_level", 5) # local 5s
	_ci.call("recalculate_rates")
	_ci.call("advance_simulation_for_test", 4.0)
	_ok(is_equal_approx(float(_ci.call("get_production_elapsed")), 4.0), "106 elapsed4")
	_ok(int(_gs.call("get_total_clones")) == 1, "106 still1")
	_gs.call("add_money", 1000)
	_lge.call("buy_global_upgrade", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION) # ×2 => 2.5s
	_ok(int(_gs.call("get_total_clones")) == 2, "106 spawn on global buy")
	_ok(is_equal_approx(float(_ci.call("get_production_elapsed")), 1.5), "106 remainder1.5")


func _test_optional_events() -> void:
	_reset()
	_enter_stage6()
	_ok(not bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.CUSTOMS)), "109 customs19 no")
	_gs.call("set_world_reach", 19)
	_ok(not bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.CUSTOMS)), "109 customs19 still no")
	_gs.call("set_world_reach", 20)
	_ok(bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.CUSTOMS)), "109 customs20 yes")
	_ok(bool(_lge.call("complete_optional_event", LateGameTypes.OptionalEvent.CUSTOMS)), "110 customs once")
	_ok(int(_gs.call("get_world_reach")) == 30, "110 customs +10")
	_ok(bool(_gs.call("get_story_flag", LateGameTypes.FLAG_EVENT_CUSTOMS)), "110 customs flag")
	_ok(not bool(_lge.call("complete_optional_event", LateGameTypes.OptionalEvent.CUSTOMS)), "110 customs second reject")
	_ok(int(_gs.call("get_world_reach")) == 30, "110 no second +10")
	_gs.call("set_world_reach", 49)
	_ok(not bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.WORLD_ROUTE)), "109 route49 no")
	_gs.call("set_world_reach", 50)
	_ok(bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.WORLD_ROUTE)), "109 route50 yes")
	_gs.call("set_world_reach", 79)
	_ok(not bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.LAST_CONTINENT)), "109 continent79 no")
	_gs.call("set_world_reach", 80)
	_ok(bool(_lge.call("is_optional_event_available", LateGameTypes.OptionalEvent.LAST_CONTINENT)), "109 continent80 yes")


func _test_completion() -> void:
	_reset()
	_enter_stage6()
	_completed_count = 0
	_final_signal_count = 0
	_gs.call("set_world_reach", 100)
	_ok(bool(_gs.call("get_story_flag", StoryIds.FLAG_WORLD_EXPANSION_COMPLETE)), "114 flag set")
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "114 FINALE")
	_ok(_completed_count == 1, "114 completed signal once")
	_ok(_final_signal_count == 1, "114 final signal once")
	_ok(bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.FINAL_DATE)), "114 FINAL_DATE unlocked")
	# Multipliers persist in FINALE.
	_gs.call("set_global_upgrade_level", LateGameTypes.GlobalUpgradeType.GLOBAL_WORK, 2)
	_ok(is_equal_approx(float(_lge.call("get_work_multiplier")), 4.0), "114 mult persists FINALE")


func _test_terminal_prompts() -> void:
	_reset()
	var node: GlobalExpansionTerminalInteractable = GlobalExpansionTerminalInteractable.new()
	add_child(node)
	_ok(node.get_interaction_prompt(null) == LateGameTypes.TERMINAL_LOCKED_PROMPT, "terminal locked pre6")
	_enter_stage6()
	_ok(node.get_interaction_prompt(null) == "[E] %s" % LateGameTypes.TERMINAL_PROMPT, "terminal open Stage6")
	node.queue_free()


func _test_no_module_21() -> void:
	_ok(ResourceLoader.exists("res://data/content/girls/girl_final_target.tres"), "girl_final_target content present")
	_ok(not ResourceLoader.exists("res://game/finale/"), "no finale gameplay dir")


func _test_reset() -> void:
	_reset()
	_enter_stage6()
	_gs.call("set_world_reach", 40)
	_gs.call("set_global_upgrade_level", LateGameTypes.GlobalUpgradeType.GLOBAL_PRODUCTION, 2)
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_world_reach")) == 0, "reset reach0")
	_ok(int(_gs.call("get_global_production_upgrade_level")) == 0, "reset prod0")
	_ok(int(_gs.call("get_global_work_upgrade_level")) == 0, "reset work0")
	_ok(int(_gs.call("get_global_dating_upgrade_level")) == 0, "reset dating0")


func _test_phone_stage5_to_finale() -> void:
	var packed: PackedScene = load("res://ui/phone/phone_journal.tscn") as PackedScene
	_ok(packed != null, "phone scene load")
	if packed == null:
		return
	var phone: PhoneJournal = packed.instantiate() as PhoneJournal
	_ok(phone != null, "phone instantiate")
	if phone == null:
		return
	add_child(phone)
	# §56 before clone.
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	phone.open(null)
	var s5_lab: String = phone.get_story_text()
	_ok(s5_lab.contains("Лаборатория открыта."), "phone §56 lab")
	_ok(s5_lab.contains("Создай первого клона."), "phone §56 create")
	phone.close()
	# §57 after clone, XP < 10.
	_ok(bool(_gs.call("set_clone_counts", 1, 1, 0)), "phone seed clone")
	phone.open(null)
	var s5_xp: String = phone.get_story_text()
	_ok(s5_xp.contains("Президент"), "phone §57 title")
	_ok(s5_xp.contains("Опытность: 0 / 10"), "phone §57 xp")
	phone.close()
	# §60 STAGE_6 Reach.
	_enter_stage6()
	_set_clones(3, 2, 1)
	_gs.call("set_world_reach", 42)
	phone.open(null)
	var s6: String = phone.get_story_text()
	_ok(s6.contains("СТАДИЯ 6"), "phone §60 stage")
	_ok(s6.contains("Мировое расширение"), "phone §60 title")
	_ok(s6.contains("Охват Земли: 42 / 100"), "phone §60 reach")
	_ok(s6.contains("Клоны: 3"), "phone §60 clones")
	_ok(s6.contains("Расширять мировой охват."), "phone §60 next")
	phone.close()
	# §61 FINALE handoff — no final date start.
	_gs.call("set_world_reach", 100)
	_ok(int(_gs.call("get_stage")) == int(GameTypes.GameStage.FINALE), "phone finale stage")
	phone.open(null)
	var fin: String = phone.get_story_text()
	_ok(fin.contains("ФИНАЛ"), "phone §61 FINALE")
	_ok(fin.contains("Земная цель исчерпана."), "phone §61 earth done")
	_ok(fin.contains("Обнаружена романтическая цель вне Земли."), "phone §61 signal")
	_ok(fin.contains("Финальная локация открыта."), "phone §61 location")
	_ok(not fin.contains("girl_final_target"), "phone no final target id")
	phone.close()
	phone.queue_free()


func _test_president_anchor_and_discovery_gate() -> void:
	var anchor_src: String = FileAccess.get_file_as_string("res://world/actors/stage_actor_anchor.gd")
	_ok(anchor_src.contains("requires_first_clone_created"), "anchor export first clone")
	_ok(anchor_src.contains("clone_counts_changed"), "anchor listens clone_counts_changed")
	_ok(anchor_src.contains("_refresh_spawn"), "anchor refresh spawn")
	var gd: Node = get_node_or_null("/root/GirlDiscovery")
	_ok(gd != null, "GirlDiscovery present")
	if gd == null:
		return
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_5)
	_gs.call("mark_rival_defeated", StoryIds.RIVAL_PRESIDENT)
	_gs.call("add_experience", 10)
	var begin: Dictionary = gd.call("begin_attempt", StoryIds.GIRL_PRESIDENT) as Dictionary
	_ok(begin.get("reason", &"") == &"STORY_PREREQUISITE", "discovery §88 STORY_PREREQUISITE")
	_ok(bool(_gs.call("set_clone_counts", 1, 0, 0)), "discovery seed clone")
	var begin2: Dictionary = gd.call("begin_attempt", StoryIds.GIRL_PRESIDENT) as Dictionary
	_ok(bool(begin2.get("ok", false)), "discovery after clone ok")
	gd.call("force_clear_attempt")
	# Runtime anchor gate without city scene.
	var anchor: StageActorAnchor = StageActorAnchor.new()
	anchor.actor_kind = StageActorAnchor.ActorKind.GIRL
	anchor.content_id = StoryIds.GIRL_PRESIDENT
	anchor.story_stage = GameTypes.GameStage.STAGE_5
	anchor.requires_first_clone_created = true
	add_child(anchor)
	await get_tree().process_frame
	_ok(anchor.get_child_count() == 1, "anchor spawns with clone")
	_gs.call("set_clone_counts", 0, 0, 0)
	await get_tree().process_frame
	_ok(anchor.get_child_count() == 0, "anchor despawns without clone")
	anchor.queue_free()
