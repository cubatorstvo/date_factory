extends SceneTree

const _ProgressionLabTests := preload("res://date_system/tests/progression_lab_tests.gd")

var _started: bool = false


func _init() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	if _started:
		return
	_started = true
	print("DATE SYSTEM TESTS: start")
	var tests := DateSystemTests.new()
	var failures: PackedStringArray = tests.run_all()
	print("DATE SYSTEM TESTS: %s" % tests.summary())
	for failure in failures:
		printerr("FAIL: %s" % failure)
	var lab_tests: _ProgressionLabTests = _ProgressionLabTests.new()
	var lab_failures: PackedStringArray = lab_tests.run_all()
	print("PROGRESSION LAB TESTS: %s" % lab_tests.summary())
	for failure in lab_failures:
		failures.append(failure)
		printerr("FAIL: %s" % failure)
	var report := FileAccess.open("user://date_system_test_results.txt", FileAccess.WRITE)
	if report != null:
		report.store_line(tests.summary())
		report.store_line(lab_tests.summary())
		report.store_line("fail_count=%d" % failures.size())
		for failure in failures:
			report.store_line(failure)
		report.close()
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TESTS FAILED: %d" % failures.size())
		quit(1)
