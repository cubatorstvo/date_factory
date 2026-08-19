extends SceneTree


func _init() -> void:
	var tests := DateSystemTests.new()
	var failures: PackedStringArray = tests.run_all()
	print("DATE SYSTEM TESTS: %s" % tests.summary())
	for failure in failures:
		printerr("FAIL: %s" % failure)
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("TESTS FAILED: %d" % failures.size())
		quit(1)
