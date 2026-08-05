class_name ReleaseTestReport
extends RefCounted
## Concise release-test report writer (separate from raw Godot engine log).


var mode: String = ""
var started_unix: int = 0
var started_msec: int = 0
var steps: Array[Dictionary] = []
var failed_step: String = ""
var notes: PackedStringArray = PackedStringArray()


func begin(mode_id: String) -> void:
	mode = mode_id
	started_unix = int(Time.get_unix_time_from_system())
	started_msec = Time.get_ticks_msec()
	steps.clear()
	failed_step = ""
	notes.clear()


func note(text: String) -> void:
	notes.append(text)


func record_step(step_id: String, ok: bool, detail: String = "") -> void:
	steps.append({
		"id": step_id,
		"ok": ok,
		"detail": detail,
	})
	if not ok and failed_step.is_empty():
		failed_step = step_id


func write_to(path: String, overall_ok: bool) -> bool:
	var finished_unix: int = int(Time.get_unix_time_from_system())
	var duration_ms: int = maxi(0, Time.get_ticks_msec() - started_msec)
	var duration_sec: float = float(duration_ms) / 1000.0
	var lines: PackedStringArray = PackedStringArray()
	lines.append("DATE FACTORY release test report")
	lines.append("mode=%s" % mode)
	lines.append("result=%s" % ("PASS" if overall_ok else "FAIL"))
	lines.append("started_unix=%d" % started_unix)
	lines.append("finished_unix=%d" % finished_unix)
	lines.append("duration_sec=%.3f" % duration_sec)
	lines.append("duration_ms=%d" % duration_ms)
	if not failed_step.is_empty():
		lines.append("failed_step=%s" % failed_step)
	lines.append("steps=%d" % steps.size())
	lines.append("---")
	for s in steps:
		var mark: String = "PASS" if bool(s.get("ok", false)) else "FAIL"
		var detail: String = str(s.get("detail", ""))
		if detail.is_empty():
			lines.append("[%s] %s" % [mark, str(s.get("id", ""))])
		else:
			lines.append("[%s] %s — %s" % [mark, str(s.get("id", "")), detail])
	if not notes.is_empty():
		lines.append("---")
		lines.append("notes:")
		for n in notes:
			lines.append("- %s" % n)
	lines.append("---")
	lines.append("visual_coverage=NONE (headless logical contracts only)")
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("RELEASE_TEST_REPORT_WRITE_FAIL path=%s err=%s" % [path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string("\n".join(lines) + "\n")
	print("RELEASE_TEST_REPORT path=%s" % ProjectSettings.globalize_path(path))
	return true
