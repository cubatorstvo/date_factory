extends SceneTree
## Headless release SMOKE entry. Auto-quits with non-zero on failure.
## Artifacts: tests/release/artifacts/smoke_godot.log (via --log-file) + smoke_report.txt


const REPORT_RES := "res://tests/release/artifacts/smoke_report.txt"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	await process_frame
	var report_script: GDScript = load("res://tests/release/harness/release_test_report.gd") as GDScript
	var seed_script: GDScript = load("res://tests/release/harness/release_test_seed.gd") as GDScript
	var helpers_script: GDScript = load("res://tests/release/harness/release_test_helpers.gd") as GDScript
	var suite_script: GDScript = load("res://tests/release/suites/smoke_suite.gd") as GDScript
	if report_script == null or seed_script == null or helpers_script == null or suite_script == null:
		push_error("RELEASE_SMOKE_LOAD_FAIL")
		quit(2)
		return
	var report: RefCounted = report_script.new()
	var seed_helper: RefCounted = seed_script.new()
	var helpers: RefCounted = helpers_script.new()
	var suite: RefCounted = suite_script.new()
	report.begin("smoke")
	helpers.setup(report, seed_helper)
	var ok: bool = bool(suite.call("run", self, helpers, seed_helper, report))
	# Soft failures in smoke (check) still fail the mode.
	if not helpers.errors.is_empty():
		ok = false
	report.write_to(REPORT_RES, ok)
	if ok:
		print("RELEASE_SMOKE_PASS")
		quit(0)
	else:
		print("RELEASE_SMOKE_FAIL failed_step=%s errors=%s" % [report.failed_step, helpers.errors])
		quit(1)
