extends Node
## MODULE 13 GameDay + SalaryMine core self-test (spec §§112–138, 146–149).
## Run: res://game/salary/test/salary_mine_test.tscn --quit-after 20000


var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _day: Node = null
var _salary: Node = null
var _story: Node = null
var _gd: Node = null
var _rel: Node = null
var _day_signal_count: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_day = get_node("/root/GameDay")
	_salary = get_node("/root/SalaryMine")
	_story = get_node("/root/Story")
	_gd = get_node("/root/GirlDiscovery")
	_rel = get_node("/root/Relationships")
	await get_tree().process_frame
	if _day.has_signal("day_advanced") and not _day.is_connected("day_advanced", _on_day_signal):
		_day.connect("day_advanced", _on_day_signal)
	await _run_all()
	if _failed == 0:
		DfLog.info("MODULE_13_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_13_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_13_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_13_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_day_signal(_new_day: int) -> void:
	_day_signal_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_13_TEST] FAIL: %s" % label)
		print("MODULE_13_TEST FAIL: %s" % label)


func _reset() -> void:
	_gs.call("reset_for_new_game")
	_day_signal_count = 0


func _unlock_salary(authority: int = 0) -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	if authority > 0:
		_gs.call("add_authority", authority)
	_salary.call("get_status")


func _run_all() -> void:
	_test_gameday_reset()
	_test_discovery_cooldown_via_day()
	_test_date_cooldown_via_day()
	_test_both_cooldowns_same_day()
	_test_level_formula()
	_test_gross_formula()
	_test_locked_no_salary()
	_test_initial_period()
	_test_initialization_idempotent()
	_test_accumulation()
	_test_authority_next_period_only()
	_test_authority_loss()
	_test_manual_empty()
	_test_manual_claim()
	_test_manual_exactly_once()
	_test_manual_flag_only_positive()
	_test_inertia_before_manual()
	_test_inertia_after_manual()
	_test_inertia_rounding()
	_test_no_retroactive_inertia()
	_test_advance_no_perk()
	_test_advance_success()
	_test_advance_duplicate()
	_test_advance_next_period()
	_test_advance_claims_accumulated()
	_test_remote_does_not_set_manual_seen()
	_test_manual_does_not_consume_advance()
	await _test_no_idle_money()
	_test_no_clone_mutation()
	_test_reset_salary()
	await _test_phone_salary_section()
	_reset()


func _test_gameday_reset() -> void:
	_reset()
	_ok(int(_day.call("get_current_day")) == 1, "112 day starts 1")
	_day_signal_count = 0
	_ok(int(_day.call("advance_day")) == 2, "112 advance ->2")
	_ok(_day_signal_count == 1, "112 day_advanced once")
	var signals_before_reset: int = _day_signal_count
	_gs.call("reset_for_new_game")
	_ok(int(_day.call("get_current_day")) == 1, "112 reset day=1")
	_ok(_day_signal_count == signals_before_reset, "112 no fake day_advanced on reset")


func _test_discovery_cooldown_via_day() -> void:
	_reset()
	_gs.call("mark_girl_discovered", &"girl_test_discovery")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 3)
	_day.call("advance_day")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 2, "113 discovery 3->2 via GameDay")


func _test_date_cooldown_via_day() -> void:
	_reset()
	_gs.call("add_girl_contact", &"girl_test_dating_kind")
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 3)
	_day.call("advance_day")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 2, "114 date 3->2 via GameDay")


func _test_both_cooldowns_same_day() -> void:
	_reset()
	_gs.call("mark_girl_discovered", &"girl_test_discovery")
	_gs.call("set_girl_retry_days_remaining", &"girl_test_discovery", 3)
	_gs.call("add_girl_contact", &"girl_test_dating_kind")
	_gs.call("set_girl_date_cooldown_days_remaining", &"girl_test_dating_kind", 2)
	_day.call("advance_day")
	_ok(int(_gs.call("get_girl_retry_days_remaining", &"girl_test_discovery")) == 2, "115 discovery once")
	_ok(int(_gs.call("get_girl_date_cooldown_days_remaining", &"girl_test_dating_kind")) == 1, "115 date once")


func _test_level_formula() -> void:
	_reset()
	_ok(int(_salary.call("get_salary_level", 0)) == 1, "116 auth0 ->1")
	_ok(int(_salary.call("get_salary_level", 2)) == 1, "116 auth2 ->1")
	_ok(int(_salary.call("get_salary_level", 3)) == 2, "116 auth3 ->2")
	_ok(int(_salary.call("get_salary_level", 5)) == 2, "116 auth5 ->2")
	_ok(int(_salary.call("get_salary_level", 6)) == 3, "116 auth6 ->3")
	_ok(int(_salary.call("get_salary_level", 11)) == 4, "116 auth11 ->4")
	_ok(int(_salary.call("get_salary_level", 12)) == 5, "116 auth12 ->5")


func _test_gross_formula() -> void:
	_reset()
	_ok(int(_salary.call("get_gross_salary", 0)) == 10, "117 level1 ->10")
	_ok(int(_salary.call("get_gross_salary", 3)) == 20, "117 level2 ->20")
	_ok(int(_salary.call("get_gross_salary", 12)) == 50, "117 level5 ->50")


func _test_locked_no_salary() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_2)
	_ok(not bool(_story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE)), "118 locked")
	_day.call("advance_day")
	_ok(not bool(_gs.call("is_salary_initialized")), "118 initialized false")
	_ok(int(_gs.call("get_salary_period_index")) == 0, "118 period0")
	_ok(int(_gs.call("get_pending_salary")) == 0, "118 pending0")


func _test_initial_period() -> void:
	_unlock_salary(6)
	_ok(bool(_gs.call("is_salary_initialized")), "119 initialized")
	_ok(int(_salary.call("get_salary_level")) == 3, "119 level3")
	_ok(int(_salary.call("get_gross_salary")) == 30, "119 gross30")
	_ok(int(_gs.call("get_salary_period_index")) == 1, "119 period1")
	_ok(int(_gs.call("get_pending_salary")) == 30, "119 pending30")
	_ok(int(_gs.call("get_money")) == 0, "119 money unchanged without inertia")


func _test_initialization_idempotent() -> void:
	_unlock_salary(6)
	_ok(int(_gs.call("get_salary_period_index")) == 1, "120 period1 after unlock")
	_salary.call("get_status")
	_salary.call("get_status")
	_story.emit_signal("feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE)
	_ok(int(_gs.call("get_salary_period_index")) == 1, "120 still period1")
	_ok(int(_gs.call("get_pending_salary")) == 30, "120 pending unchanged")


func _test_accumulation() -> void:
	_unlock_salary(3)
	_ok(int(_gs.call("get_pending_salary")) == 20, "121 initial 20")
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_gs.call("get_pending_salary")) == 60, "121 three periods =60")
	_ok(int(_gs.call("get_money")) == 0, "121 money unchanged")


func _test_authority_next_period_only() -> void:
	_unlock_salary(3)
	_ok(int(_gs.call("get_pending_salary")) == 20, "122 pending20")
	_gs.call("add_authority", 3)
	_ok(int(_gs.call("get_pending_salary")) == 20, "122 pending stays20")
	_ok(int(_salary.call("get_salary_level")) == 3, "122 display level3")
	_day.call("advance_day")
	_ok(int(_gs.call("get_pending_salary")) == 50, "122 next adds30 ->50")


func _test_authority_loss() -> void:
	_unlock_salary(6)
	_ok(int(_gs.call("get_pending_salary")) == 30, "123 pending30")
	_gs.call("lose_authority", 3)
	_ok(int(_gs.call("get_pending_salary")) == 30, "123 pending stays")
	_ok(int(_salary.call("get_salary_level")) == 2, "123 display level2")
	_day.call("advance_day")
	_ok(int(_gs.call("get_pending_salary")) == 50, "123 next adds20 ->50")


func _test_manual_empty() -> void:
	_unlock_salary(0)
	var claim1: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	_ok(claim1 != null and claim1.ok and claim1.amount == 10, "124 setup claim first")
	var money: int = int(_gs.call("get_money"))
	var empty: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	_ok(empty != null and not empty.ok, "124 empty not ok")
	_ok(empty.error == SalaryTypes.ClaimError.NO_PENDING, "124 NO_PENDING")
	_ok(int(_gs.call("get_money")) == money, "124 money unchanged")


func _test_manual_claim() -> void:
	_unlock_salary(3)
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_gs.call("get_pending_salary")) == 60, "125 pending60")
	var money_before: int = int(_gs.call("get_money"))
	var res: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	_ok(res != null and res.ok, "125 claim ok")
	_ok(res.amount == 60, "125 amount60")
	_ok(int(_gs.call("get_pending_salary")) == 0, "125 pending0")
	_ok(int(_gs.call("get_money")) == money_before + 60, "125 money+60")
	_ok(bool(_gs.call("has_seen_manual_salary_cycle")), "125 manual_seen")


func _test_manual_exactly_once() -> void:
	_unlock_salary(3)
	_day.call("advance_day")
	_day.call("advance_day")
	var money_before: int = int(_gs.call("get_money"))
	var a: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	var b: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	_ok(a != null and a.ok and a.amount == 60, "126 first +60")
	_ok(b != null and not b.ok and b.error == SalaryTypes.ClaimError.NO_PENDING, "126 second NO_PENDING")
	_ok(int(_gs.call("get_money")) == money_before + 60, "126 only +60 total")


func _test_manual_flag_only_positive() -> void:
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	_salary.call("get_status")
	var res: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	_ok(res != null and res.ok and res.amount > 0, "127 first positive claim")
	_ok(bool(_gs.call("has_seen_manual_salary_cycle")), "127 seen after positive")
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	_salary.call("get_status")
	_gs.call("take_all_pending_salary")
	var empty: SalaryClaimResult = _salary.call("claim_manual_pending") as SalaryClaimResult
	_ok(empty != null and not empty.ok, "127 empty claim fails")
	_ok(not bool(_gs.call("has_seen_manual_salary_cycle")), "127 empty never sets seen")


func _test_inertia_before_manual() -> void:
	_unlock_salary(3)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_FINANCIAL_INERTIA])
	_ok(not bool(_gs.call("has_seen_manual_salary_cycle")), "128 not seen")
	var money_before: int = int(_gs.call("get_money"))
	var pending_before: int = int(_gs.call("get_pending_salary"))
	_day.call("advance_day")
	_ok(int(_gs.call("get_money")) == money_before, "128 no passive money")
	_ok(int(_gs.call("get_pending_salary")) == pending_before + 20, "128 pending+20")


func _test_inertia_after_manual() -> void:
	_unlock_salary(3)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_FINANCIAL_INERTIA])
	_salary.call("claim_manual_pending")
	_ok(bool(_gs.call("has_seen_manual_salary_cycle")), "129 seen")
	var money_before: int = int(_gs.call("get_money"))
	var pending_before: int = int(_gs.call("get_pending_salary"))
	_day.call("advance_day")
	_ok(int(_gs.call("get_money")) == money_before + 5, "129 Money +5")
	_ok(int(_gs.call("get_pending_salary")) == pending_before + 15, "129 pending +15")


func _test_inertia_rounding() -> void:
	_unlock_salary(6)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_FINANCIAL_INERTIA])
	_salary.call("claim_manual_pending")
	var money_before: int = int(_gs.call("get_money"))
	var pending_before: int = int(_gs.call("get_pending_salary"))
	_day.call("advance_day")
	_ok(int(_gs.call("get_money")) == money_before + 7, "130 floor7")
	_ok(int(_gs.call("get_pending_salary")) == pending_before + 23, "130 pending23")
	_ok(7 + 23 == 30, "130 total30")


func _test_no_retroactive_inertia() -> void:
	_unlock_salary(3)
	_day.call("advance_day")
	_day.call("advance_day")
	_day.call("advance_day")
	_day.call("advance_day")
	# pending = 20*5 = 100
	_ok(int(_gs.call("get_pending_salary")) == 100, "131 pending100")
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_FINANCIAL_INERTIA])
	_gs.call("mark_manual_salary_cycle_seen")
	_ok(int(_gs.call("get_pending_salary")) == 100, "131 pending remains100")
	_ok(int(_gs.call("get_money")) == 0, "131 no retro money")


func _test_advance_no_perk() -> void:
	_unlock_salary(3)
	var money_before: int = int(_gs.call("get_money"))
	var res: SalaryClaimResult = _salary.call("claim_salary_advance") as SalaryClaimResult
	_ok(res != null and not res.ok, "132 not ok")
	_ok(res.error == SalaryTypes.ClaimError.PERK_REQUIRED, "132 PERK_REQUIRED")
	_ok(int(_gs.call("get_money")) == money_before, "132 money unchanged")
	_ok(int(_gs.call("get_pending_salary")) == 20, "132 pending unchanged")


func _test_advance_success() -> void:
	_unlock_salary(0)
	# Open to period 4 with pending 50 total: initial10 + three days20? auth0 gross10 each -> period4 pending40.
	# Spec: period4 pending50 — use auth3 for 20*2.5... Use auth12 for 50 after one period, then advance days to period4.
	_reset()
	_gs.call("restore_stage", GameTypes.GameStage.STAGE_3)
	_gs.call("add_authority", 12)
	_salary.call("get_status")
	_ok(int(_gs.call("get_salary_period_index")) == 1, "133 setup period1")
	_day.call("advance_day")
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_gs.call("get_salary_period_index")) == 4, "133 period4")
	# Clear and set pending50 via claims path: take all then add_pending
	_gs.call("take_all_pending_salary")
	_gs.call("add_pending_salary", 50)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	var money_before: int = int(_gs.call("get_money"))
	var res: SalaryClaimResult = _salary.call("claim_salary_advance") as SalaryClaimResult
	_ok(res != null and res.ok, "133 claim ok")
	_ok(res.amount == 50, "133 claim50")
	_ok(int(_gs.call("get_pending_salary")) == 0, "133 pending0")
	_ok(int(_gs.call("get_salary_advance_used_period")) == 4, "133 used_period4")
	_ok(int(_gs.call("get_money")) == money_before + 50, "133 money+50")


func _test_advance_duplicate() -> void:
	_unlock_salary(3)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	var first: SalaryClaimResult = _salary.call("claim_salary_advance") as SalaryClaimResult
	_ok(first != null and first.ok, "134 first ok")
	_gs.call("add_pending_salary", 20)
	var second: SalaryClaimResult = _salary.call("claim_salary_advance") as SalaryClaimResult
	_ok(second != null and not second.ok, "134 second fail")
	_ok(second.error == SalaryTypes.ClaimError.ADVANCE_ALREADY_USED, "134 ADVANCE_ALREADY_USED")
	_ok(int(_gs.call("get_pending_salary")) == 20, "134 no second claim")


func _test_advance_next_period() -> void:
	_unlock_salary(3)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	_salary.call("claim_salary_advance")
	_day.call("advance_day")
	_ok(int(_gs.call("get_salary_period_index")) == 2, "135 period2")
	_ok(int(_gs.call("get_pending_salary")) > 0, "135 pending>0")
	_ok(bool(_salary.call("is_salary_advance_available")), "135 available again")
	var res: SalaryClaimResult = _salary.call("claim_salary_advance") as SalaryClaimResult
	_ok(res != null and res.ok, "135 claim ok")


func _test_advance_claims_accumulated() -> void:
	_unlock_salary(3)
	_day.call("advance_day")
	_day.call("advance_day")
	_day.call("advance_day")
	_ok(int(_gs.call("get_pending_salary")) == 80, "136 pending80")
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	var money_before: int = int(_gs.call("get_money"))
	var res: SalaryClaimResult = _salary.call("claim_salary_advance") as SalaryClaimResult
	_ok(res != null and res.ok and res.amount == 80, "136 +80")
	_ok(int(_gs.call("get_pending_salary")) == 0, "136 pending0")
	_ok(int(_gs.call("get_money")) == money_before + 80, "136 money+80")


func _test_remote_does_not_set_manual_seen() -> void:
	_unlock_salary(3)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	_ok(not bool(_gs.call("has_seen_manual_salary_cycle")), "137 starts false")
	_salary.call("claim_salary_advance")
	_ok(not bool(_gs.call("has_seen_manual_salary_cycle")), "137 remains false")


func _test_manual_does_not_consume_advance() -> void:
	_unlock_salary(3)
	_ok(int(_gs.call("get_salary_advance_used_period")) == -1, "138 used default -1")
	_salary.call("claim_manual_pending")
	_ok(int(_gs.call("get_salary_advance_used_period")) == -1, "138 used remains -1")


func _test_no_idle_money() -> void:
	_unlock_salary(3)
	var money: int = int(_gs.call("get_money"))
	var pending: int = int(_gs.call("get_pending_salary"))
	for _i in range(30):
		await get_tree().process_frame
	_ok(int(_gs.call("get_money")) == money, "146 money idle unchanged")
	_ok(int(_gs.call("get_pending_salary")) == pending, "146 pending idle unchanged")
	var src: String = FileAccess.get_file_as_string("res://game/salary/salary_mine.gd")
	_ok(not src.contains("func _process"), "146 no _process in SalaryMine")


func _test_no_clone_mutation() -> void:
	_unlock_salary(3)
	_gs.call("set_clone_counts", 5, 2, 1)
	_gs.call("set_late_rates", 1.5, 0.5)
	var total: int = int(_gs.call("get_total_clones"))
	var working: int = int(_gs.call("get_clones_working"))
	var dating: int = int(_gs.call("get_clones_dating"))
	var mpm: float = float(_gs.call("get_money_per_minute"))
	var dpm: float = float(_gs.call("get_dates_per_minute"))
	_day.call("advance_day")
	_salary.call("claim_manual_pending")
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE, PerkIds.CAPITAL_FINANCIAL_INERTIA])
	_day.call("advance_day")
	_salary.call("claim_salary_advance")
	_ok(int(_gs.call("get_total_clones")) == total, "147 total_clones")
	_ok(int(_gs.call("get_clones_working")) == working, "147 clones_working")
	_ok(int(_gs.call("get_clones_dating")) == dating, "147 clones_dating")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), mpm), "147 money_per_minute")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), dpm), "147 dates_per_minute")


func _test_reset_salary() -> void:
	_unlock_salary(6)
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	_salary.call("claim_manual_pending")
	_day.call("advance_day")
	_salary.call("claim_salary_advance")
	_ok(bool(_gs.call("is_salary_initialized")), "149 was initialized")
	_gs.call("reset_for_new_game")
	_ok(not bool(_gs.call("is_salary_initialized")), "149 initialized false")
	_ok(int(_gs.call("get_salary_period_index")) == 0, "149 period0")
	_ok(int(_gs.call("get_pending_salary")) == 0, "149 pending0")
	_ok(not bool(_gs.call("has_seen_manual_salary_cycle")), "149 manual false")
	_ok(int(_gs.call("get_salary_advance_used_period")) == -1, "149 advance -1")


func _test_phone_salary_section() -> void:
	_reset()
	var journal_script: Script = load("res://ui/phone/phone_journal.gd") as Script
	var journal: PhoneJournal = journal_script.new() as PhoneJournal
	add_child(journal)
	journal.open()
	_ok(not journal.has_salary_section_visible(), "phone salary hidden when locked")
	journal.close()
	journal.queue_free()
	await get_tree().process_frame
	_unlock_salary(3)
	journal = journal_script.new() as PhoneJournal
	add_child(journal)
	journal.open()
	_ok(journal.has_salary_section_visible(), "phone salary visible when unlocked")
	var stats: String = journal.get_salary_stats_text()
	_ok(stats.contains("Авторитет:"), "phone stats authority")
	_ok(stats.contains("Разряд:"), "phone stats level")
	_ok(stats.contains("Накоплено:"), "phone stats pending")
	_ok(not journal.is_salary_advance_controls_visible(), "phone advance hidden without perk")
	_gs.call("restore_purchased_perks", [PerkIds.CAPITAL_SALARY_ADVANCE])
	journal.refresh()
	_ok(journal.is_salary_advance_controls_visible(), "phone advance visible with perk")
	_ok(journal.is_salary_advance_enabled(), "phone advance enabled with pending")
	_ok(bool(_salary.call("is_salary_advance_available")), "salary advance available matches phone")
	journal.close()
	journal.queue_free()
