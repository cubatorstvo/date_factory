extends Node
## MODULE 22 UiNumberFormat exact cases (spec §101).
## Run: --path . --headless res://ui/hud/test/ui_number_format_test.tscn


var _failed: int = 0
var _passed: int = 0


func _ready() -> void:
	await get_tree().process_frame
	_run_all()
	if _failed == 0:
		print("MODULE_22_NUMBER_FORMAT_TEST: ALL PASS (%s)" % _passed)
	else:
		print("MODULE_22_NUMBER_FORMAT_TEST: FAIL passed=%s failed=%s" % [_passed, _failed])
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0 if _failed == 0 else 1)


func _run_all() -> void:
	_expect(UiNumberFormat.format_compact(0), "0", "0 compact")
	_expect(UiNumberFormat.format_compact(9999), "9 999", "9999 compact")
	_expect(UiNumberFormat.format_compact(10000), "10K", "10000 compact")
	_expect(UiNumberFormat.format_compact(12400), "12.4K", "12400 compact")
	_expect(UiNumberFormat.format_compact(1250000), "1.25M", "1250000 compact")
	_expect(UiNumberFormat.format_compact(1000000000), "1B", "1000000000 compact")
	_expect(UiNumberFormat.format_signed(1), "+1", "signed +1")
	_expect(UiNumberFormat.format_signed(0), "0", "signed 0")
	_expect(UiNumberFormat.format_signed(-1), "-1", "signed -1")
	_expect(UiNumberFormat.format_money(120), "$ 120", "money 120")
	_expect(UiNumberFormat.format_money(12400), "$ 12.4K", "money 12.4K")


func _expect(actual: String, expected: String, label: String) -> void:
	if actual == expected:
		_passed += 1
	else:
		_failed += 1
		var msg: String = "%s expected='%s' actual='%s'" % [label, expected, actual]
		push_error("[MODULE_22_NUMBER_FORMAT_TEST] FAIL: %s" % msg)
		print("MODULE_22_NUMBER_FORMAT_TEST FAIL: %s" % msg)
