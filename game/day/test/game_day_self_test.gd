extends Node
## Focused GameDay hour/minute clock tests.
## Run with autoloads; does not open the game for play.

var _failed: int = 0
var _passed: int = 0
var _gs: Node = null
var _day: Node = null
var _hour_signals: int = 0
var _day_signals: int = 0
var _minute_signals: int = 0


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_day = get_node("/root/GameDay")
	await get_tree().process_frame
	if _day.has_signal("hour_changed"):
		_day.connect("hour_changed", _on_hour_changed)
	if _day.has_signal("day_advanced"):
		_day.connect("day_advanced", _on_day_advanced)
	if _day.has_signal("minute_changed"):
		_day.connect("minute_changed", _on_minute_changed)
	_run_all()
	if _failed == 0:
		DfLog.info("GAMEDAY_HOUR_TEST", "ALL PASS (%s)" % _passed)
		print("GAMEDAY_HOUR_TEST: ALL PASS (%s)" % _passed)
	else:
		DfLog.error("GAMEDAY_HOUR_TEST", "FAIL passed=%s failed=%s" % [_passed, _failed])
		print("GAMEDAY_HOUR_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.25).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _on_hour_changed(_new_hour: int) -> void:
	_hour_signals += 1


func _on_minute_changed(_new_minute: int) -> void:
	_minute_signals += 1


func _on_day_advanced(_new_day: int) -> void:
	_day_signals += 1


func _ok(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("[GAMEDAY_HOUR_TEST] FAIL: %s" % label)
		print("GAMEDAY_HOUR_TEST FAIL: %s" % label)


func _run_all() -> void:
	_test_default_and_wait()
	_test_next_day_when_hour_passed()
	_test_wait_until_same_hour_keeps_day()
	_test_advance_day_resets_hour()
	_test_restore_hour_silent()
	_test_state_reset_hour()
	_test_minute_tick_and_wrap()


func _test_default_and_wait() -> void:
	_gs.call("reset_for_new_game")
	_ok(int(_day.call("get_current_hour")) == 8, "default hour 8")
	_ok(int(_day.call("get_current_day")) == 1, "default day 1")
	_ok(int(_day.call("get_current_minute")) == 0, "default minute 0")
	var hours_before: int = _hour_signals
	var days_before: int = _day_signals
	_day.call("wait_until_hour", 15)
	_ok(int(_day.call("get_current_hour")) == 15, "wait 15 same day")
	_ok(int(_day.call("get_current_day")) == 1, "wait 15 does not advance day")
	_ok(_hour_signals == hours_before + 1, "wait future emits hour_changed")
	_ok(_day_signals == days_before, "wait future no day_advanced")


func _test_next_day_when_hour_passed() -> void:
	_gs.call("reset_for_new_game")
	_ok(bool(_day.call("restore_hour", 18)), "set hour 18")
	var days_before: int = _day_signals
	_day.call("wait_until_hour", 12)
	_ok(int(_day.call("get_current_day")) == 2, "passed hour advances day")
	_ok(int(_day.call("get_current_hour")) == 12, "then sets chosen hour")
	_ok(_day_signals == days_before + 1, "advance_day emitted")


func _test_wait_until_same_hour_keeps_day() -> void:
	_gs.call("reset_for_new_game")
	_ok(bool(_day.call("restore_hour", 21)), "set hour 21")
	_ok(bool(_day.call("restore_minute", 10)), "set minute 10")
	var days_before: int = _day_signals
	_day.call("wait_until_hour", 21)
	_ok(int(_day.call("get_current_day")) == 1, "21:10 wait 21 same day")
	_ok(int(_day.call("get_current_hour")) == 21, "21:10 wait 21 stays hour")
	_ok(int(_day.call("get_current_minute")) == 0, "21:10 wait 21 snaps minute")
	_ok(_day_signals == days_before, "21:10 wait 21 no day_advanced")


func _test_advance_day_resets_hour() -> void:
	_gs.call("reset_for_new_game")
	_day.call("wait_until_hour", 21)
	var hours_before: int = _hour_signals
	var new_day: int = int(_day.call("advance_day"))
	_ok(new_day == 2, "advance_day returns next day")
	_ok(int(_day.call("get_current_hour")) == 8, "advance_day hour 8")
	_ok(int(_day.call("get_current_minute")) == 0, "advance_day minute 0")
	_ok(_hour_signals == hours_before + 1, "advance_day emits hour_changed")


func _test_restore_hour_silent() -> void:
	_gs.call("reset_for_new_game")
	var hours_before: int = _hour_signals
	var days_before: int = _day_signals
	_ok(bool(_day.call("restore_hour", 21)), "restore_hour 21")
	_ok(int(_day.call("get_current_hour")) == 21, "restore_hour value")
	_ok(_hour_signals == hours_before, "restore_hour no hour_changed")
	_ok(_day_signals == days_before, "restore_hour no day_advanced")
	_ok(not bool(_day.call("restore_hour", -1)), "restore_hour rejects -1")
	_ok(not bool(_day.call("restore_hour", 24)), "restore_hour rejects 24")
	_ok(int(_day.call("get_current_hour")) == 21, "reject keeps hour")


func _test_state_reset_hour() -> void:
	_ok(bool(_day.call("restore_hour", 21)), "pre-reset hour 21")
	_ok(bool(_day.call("restore_day", 4)), "pre-reset day 4")
	_ok(bool(_day.call("restore_minute", 40)), "pre-reset minute 40")
	_gs.call("reset_for_new_game")
	_ok(int(_day.call("get_current_day")) == 1, "reset day 1")
	_ok(int(_day.call("get_current_hour")) == 8, "reset hour 8")
	_ok(int(_day.call("get_current_minute")) == 0, "reset minute 0")


func _test_minute_tick_and_wrap() -> void:
	_gs.call("reset_for_new_game")
	_ok(int(_day.call("get_current_minute")) == 0, "tick default minute 0")
	_ok(bool(_day.call("restore_minute", 59)), "restore_minute 59")
	_ok(int(_day.call("get_current_minute")) == 59, "restore_minute value")
	var hours_before: int = _hour_signals
	var minutes_before: int = _minute_signals
	_day.call("tick_one_minute")
	_ok(int(_day.call("get_current_minute")) == 0, "59+1 wraps minute")
	_ok(int(_day.call("get_current_hour")) == 9, "59+1 advances hour")
	_ok(_hour_signals == hours_before + 1, "minute wrap emits hour_changed")
	_ok(_minute_signals == minutes_before + 1, "tick emits minute_changed")
	_ok(bool(_day.call("restore_hour", 23)), "set hour 23")
	_ok(bool(_day.call("restore_minute", 59)), "set minute 59")
	var days_before: int = _day_signals
	_day.call("tick_one_minute")
	_ok(int(_day.call("get_current_hour")) == 0, "midnight wraps hour")
	_ok(int(_day.call("get_current_day")) == 2, "midnight advances day")
	_ok(_day_signals == days_before + 1, "midnight emits day_advanced")
	_ok(not bool(_day.call("restore_minute", 60)), "restore_minute rejects 60")
