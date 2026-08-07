extends Node
## Reproducible MODULE 02 GameState tests (spec sections 48–59).
## Run via world/test/game_state_test.tscn (headless: --path . --headless res://world/test/game_state_test.tscn).

const _GS := preload("res://game/state/game_state.gd")

var _failed: int = 0
var _passed: int = 0
var _money_signal_count: int = 0
var _xp_signal_count: int = 0
var _up_signal_count: int = 0
var _unlock_signal_count: int = 0
var _reset_signal_count: int = 0
var _gs: Node = null


func _ready() -> void:
	_gs = get_node("/root/GameState")
	await get_tree().process_frame
	_run_all()
	if _failed == 0:
		DfLog.info("MODULE_02_TEST", "ALL PASS (%s)" % _passed)
		print("MODULE_02_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("MODULE_02_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("MODULE_02_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	_connect_signals()
	_test_reset_defaults()
	_test_money()
	_test_authority()
	_test_experience_upgrade_points()
	_test_characteristics()
	_test_relationships()
	_test_conquered()
	_test_locations()
	_test_story_flags()
	_test_stages()
	_test_clones()
	_test_late_rates()
	_test_signals()
	_gs.call("reset_for_new_game")


func _connect_signals() -> void:
	_gs.connect("money_changed", _on_money_changed)
	_gs.connect("experience_changed", _on_xp_changed)
	_gs.connect("upgrade_points_changed", _on_up_changed)
	_gs.connect("location_unlocked", _on_location_unlocked)
	_gs.connect("state_reset", _on_state_reset)


func _on_money_changed(_new_value: int, _delta: int) -> void:
	_money_signal_count += 1


func _on_xp_changed(_new_value: int, _delta: int) -> void:
	_xp_signal_count += 1


func _on_up_changed(_new_value: int, _delta: int) -> void:
	_up_signal_count += 1


func _on_location_unlocked(_location_id: StringName) -> void:
	_unlock_signal_count += 1


func _on_state_reset() -> void:
	_reset_signal_count += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[MODULE_02_TEST] FAIL: %s" % label)
		print("MODULE_02_TEST FAIL: %s" % label)


func _test_reset_defaults() -> void:
	var before_reset: int = _reset_signal_count
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_stage")) == int(_GS.Stage.PROLOGUE), "reset stage PROLOGUE")
	_ok(int(_gs.call("get_money")) == 0, "reset money 0")
	_ok(int(_gs.call("get_authority")) == 0, "reset authority 0")
	_ok(int(_gs.call("get_experience")) == 0, "reset experience 0")
	_ok(int(_gs.call("get_upgrade_points")) == 0, "reset upgrade_points 0")
	_ok(int(_gs.call("get_muscle")) == 0, "reset muscle 0")
	_ok(int(_gs.call("get_appearance")) == 0, "reset appearance 0")
	_ok(int(_gs.call("get_capital")) == 0, "reset capital 0")
	_ok(int(_gs.call("get_aura")) == 0, "reset aura 0")
	_ok(int(_gs.call("get_total_clones")) == 0, "reset total clones 0")
	_ok(int(_gs.call("get_free_clones")) == 0, "reset free clones 0")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 0.0), "reset mpm 0")
	_ok(_reset_signal_count == before_reset + 1, "reset emits state_reset")


func _test_money() -> void:
	_gs.call("reset_for_new_game")
	var sig_before: int = _money_signal_count
	_gs.call("add_money", 100)
	_ok(int(_gs.call("get_money")) == 100, "add_money 100")
	_ok(_money_signal_count == sig_before + 1, "add_money signal")
	_ok(bool(_gs.call("can_afford", 40)), "can_afford 40")
	_ok(not bool(_gs.call("can_afford", 150)), "cannot afford 150")
	var spend_ok: bool = bool(_gs.call("spend_money", 40))
	_ok(spend_ok and int(_gs.call("get_money")) == 60, "spend_money 40 => 60")
	var spend_fail: bool = bool(_gs.call("spend_money", 100))
	_ok(not spend_fail and int(_gs.call("get_money")) == 60, "spend_money over balance rejected")
	var sig_mid: int = _money_signal_count
	_gs.call("spend_money", 100)
	_ok(_money_signal_count == sig_mid, "failed spend no money_changed")
	_gs.call("add_money", -5)
	_ok(int(_gs.call("get_money")) == 60, "negative add_money rejected")


func _test_authority() -> void:
	_gs.call("reset_for_new_game")
	_gs.call("add_authority", 7)
	_ok(int(_gs.call("get_authority")) == 7, "add_authority 7")
	_gs.call("add_authority", -1)
	_ok(int(_gs.call("get_authority")) == 7, "negative authority rejected")
	_ok(not _gs.has_method("spend_authority"), "no spend_authority API")


func _test_experience_upgrade_points() -> void:
	_gs.call("reset_for_new_game")
	var xp_before: int = _xp_signal_count
	var up_before: int = _up_signal_count
	_gs.call("add_experience", 5)
	_ok(int(_gs.call("get_experience")) == 5, "xp +5")
	_ok(int(_gs.call("get_upgrade_points")) == 5, "up +5 with xp")
	_ok(_xp_signal_count == xp_before + 1, "xp signal")
	_ok(_up_signal_count == up_before + 1, "up signal with xp")
	_ok(bool(_gs.call("spend_upgrade_points", 2)), "spend up 2")
	_ok(int(_gs.call("get_upgrade_points")) == 3, "up after spend 3")
	_ok(int(_gs.call("get_experience")) == 5, "xp unchanged after spend")
	_ok(not bool(_gs.call("spend_upgrade_points", 10)), "spend up over balance rejected")
	_ok(int(_gs.call("get_upgrade_points")) == 3, "up still 3 after fail")
	_ok(not _gs.has_method("add_upgrade_points"), "no gameplay add_upgrade_points")


func _test_characteristics() -> void:
	_gs.call("reset_for_new_game")
	_ok(bool(_gs.call("set_characteristic", _GS.Characteristic.MUSCLE, 3)), "set muscle 3")
	_ok(int(_gs.call("get_muscle")) == 3, "get muscle 3")
	_ok(not bool(_gs.call("set_characteristic", _GS.Characteristic.APPEARANCE, 11)), "char >10 rejected")
	_ok(int(_gs.call("get_appearance")) == 0, "appearance stays 0")
	_ok(not bool(_gs.call("set_characteristic", _GS.Characteristic.CAPITAL, -1)), "char <0 rejected")
	_ok(bool(_gs.call("set_characteristic", _GS.Characteristic.AURA, 10)), "set aura 10")
	_ok(int(_gs.call("get_aura")) == 10, "get aura 10")


func _test_relationships() -> void:
	_gs.call("reset_for_new_game")
	var gid: StringName = &"girl_a"
	_ok(int(_gs.call("get_girl_relationship", gid)) == 0, "unknown rel 0")
	_gs.call("set_girl_relationship", gid, 2)
	_ok(int(_gs.call("get_girl_relationship", gid)) == 2, "set rel 2")
	_gs.call("add_girl_relationship", gid, -5)
	_ok(int(_gs.call("get_girl_relationship", gid)) == -3, "rel can be negative")
	_gs.call("add_girl_relationship", gid, 8)
	_ok(int(_gs.call("get_girl_relationship", gid)) == 5, "rel + to 5")
	_ok(not bool(_gs.call("is_girl_conquered", gid)), "rel +5 does not auto-conquer")


func _test_conquered() -> void:
	_gs.call("reset_for_new_game")
	var gid: StringName = &"girl_b"
	_ok(not bool(_gs.call("is_girl_conquered", gid)), "not conquered")
	_ok(bool(_gs.call("mark_girl_conquered", gid)), "mark conquered")
	_ok(bool(_gs.call("is_girl_conquered", gid)), "is conquered")
	_ok(not bool(_gs.call("mark_girl_conquered", gid)), "duplicate conquer false")


func _test_locations() -> void:
	_gs.call("reset_for_new_game")
	var lid: StringName = &"city_plaza"
	var before: int = _unlock_signal_count
	_ok(not bool(_gs.call("is_location_unlocked", lid)), "loc locked")
	_ok(bool(_gs.call("unlock_location", lid)), "unlock loc")
	_ok(bool(_gs.call("is_location_unlocked", lid)), "loc unlocked")
	_ok(_unlock_signal_count == before + 1, "unlock signal once")
	_ok(not bool(_gs.call("unlock_location", lid)), "unlock again false")
	_ok(_unlock_signal_count == before + 1, "no second unlock signal")


func _test_story_flags() -> void:
	_gs.call("reset_for_new_game")
	var fid: StringName = &"met_mentor"
	_ok(not bool(_gs.call("get_story_flag", fid)), "unknown flag false")
	_gs.call("set_story_flag", fid, true)
	_ok(bool(_gs.call("get_story_flag", fid)), "flag true")
	_gs.call("set_story_flag", fid, false)
	_ok(not bool(_gs.call("get_story_flag", fid)), "flag false")


func _test_stages() -> void:
	_gs.call("reset_for_new_game")
	_ok(int(_gs.call("get_stage")) == int(_GS.Stage.PROLOGUE), "start PROLOGUE")
	_ok(bool(_gs.call("advance_stage", _GS.Stage.STAGE_1)), "advance to STAGE_1")
	_ok(int(_gs.call("get_stage")) == int(_GS.Stage.STAGE_1), "now STAGE_1")
	_ok(not bool(_gs.call("advance_stage", _GS.Stage.PROLOGUE)), "no reverse")
	_ok(int(_gs.call("get_stage")) == int(_GS.Stage.STAGE_1), "still STAGE_1 after reverse")
	_ok(not bool(_gs.call("advance_stage", _GS.Stage.STAGE_4)), "no skip")
	_ok(int(_gs.call("get_stage")) == int(_GS.Stage.STAGE_1), "still STAGE_1 after skip")
	_gs.call("restore_stage", _GS.Stage.STAGE_4)
	_ok(int(_gs.call("get_stage")) == int(_GS.Stage.STAGE_4), "restore_stage allows jump")


func _test_clones() -> void:
	_gs.call("reset_for_new_game")
	_ok(bool(_gs.call("set_clone_counts", 10, 4, 3)), "valid clone counts")
	_ok(int(_gs.call("get_free_clones")) == 3, "free == 3")
	_ok(not bool(_gs.call("set_clone_counts", 10, 8, 5)), "invalid clones rejected")
	_ok(int(_gs.call("get_total_clones")) == 10, "total unchanged after reject")
	_ok(int(_gs.call("get_clones_working")) == 4, "working unchanged after reject")
	_ok(int(_gs.call("get_clones_dating")) == 3, "dating unchanged after reject")


func _test_late_rates() -> void:
	_gs.call("reset_for_new_game")
	_ok(bool(_gs.call("set_late_rates", 1.5, 0.25)), "set rates")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 1.5), "mpm")
	_ok(is_equal_approx(float(_gs.call("get_dates_per_minute")), 0.25), "dpm")
	_ok(not bool(_gs.call("set_late_rates", -1.0, 0.0)), "negative rate rejected")
	_ok(is_equal_approx(float(_gs.call("get_money_per_minute")), 1.5), "mpm unchanged")


func _test_signals() -> void:
	_ok(true, "signals covered by prior cases")
