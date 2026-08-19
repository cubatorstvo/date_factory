class_name DateResult
extends RefCounted

const DEFAULT_DURATION_MINUTES: int = 120

var girl_id: StringName = &""
var relationship_delta: int = 0
var duration_minutes: int = DEFAULT_DURATION_MINUTES
var result_text: String = ""


static func from_run_result(run: DateRunResult) -> DateResult:
	var result := DateResult.new()
	if run == null or run.session == null:
		return result
	var session: DateSession = run.session
	result.girl_id = session.girl_id
	result.relationship_delta = session.relationship_after - session.relationship_before
	result.duration_minutes = DEFAULT_DURATION_MINUTES
	if result.relationship_delta >= 0:
		result.result_text = "Отношения +%d" % result.relationship_delta
	else:
		result.result_text = "Отношения %d" % result.relationship_delta
	return result
