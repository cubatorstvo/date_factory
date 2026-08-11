extends Node
## Relationships autoload — apply DatingResult to persistent girl state (MODULE 10).
## Owns completion, date cooldown, event history cycle; GameState stores fields.

signal date_result_applied(result: RelationshipDateResult)
signal girl_completed(girl_id: StringName, relationship_result: RelationshipDateResult)
signal girl_date_available_again(girl_id: StringName)

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _applied_date_ids: Dictionary = {}
var _auto_apply_enabled: bool = true
var _last_applied_result: RelationshipDateResult = null


func _ready() -> void:
	_rng.randomize()
	var dc: Node = get_node_or_null("/root/DatingCore")
	if dc != null and dc.has_signal("date_finished"):
		if not dc.is_connected("date_finished", _on_date_finished):
			dc.connect("date_finished", _on_date_finished)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	_connect_gameday_signal()
	DfLog.info("MODULE_10", "Relationships ready")


func _connect_gameday_signal() -> void:
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null or not day.has_signal("day_advanced"):
		return
	if day.is_connected("day_advanced", _on_game_day_advanced):
		return
	day.connect("day_advanced", _on_game_day_advanced)


func _on_game_day_advanced(_new_day: int) -> void:
	notify_game_day_advanced()


func _on_state_reset() -> void:
	_applied_date_ids.clear()
	_last_applied_result = null


func _on_date_finished(result: DatingResult) -> void:
	if result != null and result.tutorial_mode:
		return
	if not _auto_apply_enabled:
		return
	apply_date_result(result)


func set_auto_apply_enabled(enabled: bool) -> void:
	_auto_apply_enabled = enabled


func is_auto_apply_enabled() -> bool:
	return _auto_apply_enabled


func set_rng(rng: RandomNumberGenerator) -> void:
	if rng != null:
		_rng = rng


func get_last_applied_result() -> RelationshipDateResult:
	return _last_applied_result


func clear_applied_date_ids() -> void:
	_applied_date_ids.clear()


func apply_date_result(result: DatingResult) -> RelationshipDateResult:
	var out := RelationshipDateResult.new()
	if result != null and result.tutorial_mode:
		out.ok = false
		out.error = RelationshipTypes.ERR_INVALID_RESULT
		out.girl_id = result.girl_id
		return out
	var validation: Dictionary = _validate_dating_result(result)
	if not bool(validation.get("ok", false)):
		out.ok = false
		out.error = validation.get("error", RelationshipTypes.ERR_INVALID_RESULT) as StringName
		if result != null:
			out.girl_id = result.girl_id
			out.date_delta = result.date_delta
		return out
	var date_id: int = result.date_id
	if _applied_date_ids.has(date_id):
		out.ok = false
		out.error = RelationshipTypes.ERR_ALREADY_APPLIED
		out.girl_id = result.girl_id
		out.date_delta = result.date_delta
		return out
	var gs: Node = get_node("/root/GameState")
	var girl_id: StringName = result.girl_id
	var before: int = int(gs.call("get_girl_relationship", girl_id))
	var after: int = clampi(before + result.date_delta, -5, 5)
	var applied_delta: int = after - before
	gs.call("set_girl_relationship", girl_id, after)
	var event_ids: Array[StringName] = []
	for eid in result.central_event_ids:
		event_ids.append(eid)
	gs.call("record_girl_played_dating_events", girl_id, event_ids)
	var cooldown_days: int = _rng.randi_range(1, 3)
	gs.call("set_girl_date_cooldown_days_remaining", girl_id, cooldown_days)
	var newly_conquered: bool = false
	var xp_gained: int = 0
	var up_gained: int = 0
	if after == 5 and not bool(gs.call("is_girl_conquered", girl_id)):
		if bool(gs.call("mark_girl_conquered", girl_id)):
			var xp_before: int = int(gs.call("get_experience"))
			var up_before: int = int(gs.call("get_upgrade_points"))
			gs.call("add_experience", 1)
			newly_conquered = true
			xp_gained = int(gs.call("get_experience")) - xp_before
			up_gained = int(gs.call("get_upgrade_points")) - up_before
	_applied_date_ids[date_id] = true
	out.ok = true
	out.error = RelationshipTypes.ERR_OK
	out.girl_id = girl_id
	out.date_delta = result.date_delta
	out.relationship_before = before
	out.relationship_after = after
	out.applied_delta = applied_delta
	out.newly_conquered = newly_conquered
	out.experience_gained = xp_gained
	out.upgrade_points_gained = up_gained
	out.repeat_cooldown_days = cooldown_days
	out.played_event_ids = event_ids
	_last_applied_result = out
	date_result_applied.emit(out)
	if newly_conquered:
		girl_completed.emit(girl_id, out)
	return out


func _validate_dating_result(result: DatingResult) -> Dictionary:
	if result == null:
		return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
	if String(result.girl_id) == "":
		return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
	if result.date_id <= 0:
		return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
	if result.date_delta < -5 or result.date_delta > 5:
		return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
	if result.central_event_ids.size() != 3:
		return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
	var seen: Dictionary = {}
	for eid in result.central_event_ids:
		if String(eid) == "":
			return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
		if seen.has(eid):
			return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
		seen[eid] = true
	if not _girl_exists(result.girl_id):
		return {"ok": false, "error": RelationshipTypes.ERR_UNKNOWN_GIRL}
	return {"ok": true, "error": RelationshipTypes.ERR_OK}


func can_start_date(girl_id: StringName) -> bool:
	var avail: Dictionary = get_date_availability(girl_id)
	return avail.get("status", RelationshipTypes.AVAIL_UNKNOWN_GIRL) == RelationshipTypes.AVAIL_AVAILABLE


func get_date_availability(girl_id: StringName) -> Dictionary:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return {"status": RelationshipTypes.AVAIL_UNKNOWN_GIRL, "cooldown_days": 0}
	if String(girl_id) == "" or not _girl_exists(girl_id):
		return {"status": RelationshipTypes.AVAIL_UNKNOWN_GIRL, "cooldown_days": 0}
	var db: Node = get_node_or_null("/root/ContentDB")
	var girl: GirlDefinition = null
	if db != null:
		girl = db.call("get_girl", girl_id) as GirlDefinition
	if girl != null and not girl.romance_available:
		return {
			"status": RelationshipTypes.AVAIL_NOT_ROMANCEABLE,
			"cooldown_days": 0,
		}
	if not bool(gs.call("has_girl_contact", girl_id)):
		return {"status": RelationshipTypes.AVAIL_NO_CONTACT, "cooldown_days": 0}
	var cd: int = int(gs.call("get_girl_date_cooldown_days_remaining", girl_id))
	if cd > 0:
		return {"status": RelationshipTypes.AVAIL_COOLDOWN, "cooldown_days": cd}
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_method("can_start_personal_date"):
		if not bool(overload.call("can_start_personal_date")):
			return {
				"status": DatingOverloadTypes.AVAIL_BODY_CAPACITY_USED,
				"cooldown_days": 0,
				"message": DatingOverloadTypes.BODY_CAPACITY_USED_MESSAGE,
			}
	return {"status": RelationshipTypes.AVAIL_AVAILABLE, "cooldown_days": 0}


func get_event_exclusions_for_next_date(girl_id: StringName) -> Array[StringName]:
	var gs: Node = get_node("/root/GameState")
	var out: Array[StringName] = []
	var hist: Array = gs.call("get_girl_played_dating_event_ids", girl_id) as Array
	for eid in hist:
		out.append(eid as StringName)
	return out


func begin_new_event_cycle(girl_id: StringName) -> Array[StringName]:
	var gs: Node = get_node("/root/GameState")
	var last: Array[StringName] = []
	var stored: Array = gs.call("get_girl_last_date_event_ids", girl_id) as Array
	for eid in stored:
		last.append(eid as StringName)
	gs.call("clear_girl_played_dating_event_history", girl_id)
	return last


## Fills exclusions and retries once with cycle reset on INSUFFICIENT_DATE_CONTENT.
func start_date_with_history(request: DatingStartRequest) -> Dictionary:
	if request == null:
		return {"ok": false, "error": RelationshipTypes.ERR_UNKNOWN_GIRL}
	var avail: Dictionary = get_date_availability(request.girl_id)
	var status: StringName = avail.get("status", RelationshipTypes.AVAIL_UNKNOWN_GIRL) as StringName
	if status != RelationshipTypes.AVAIL_AVAILABLE:
		var out: Dictionary = {"ok": false, "error": status, "availability": avail}
		if status == DatingOverloadTypes.AVAIL_BODY_CAPACITY_USED:
			out["message"] = DatingOverloadTypes.BODY_CAPACITY_USED_MESSAGE
		return out
	var dc: Node = get_node("/root/DatingCore")
	request.excluded_event_ids = get_event_exclusions_for_next_date(request.girl_id)
	var first: Dictionary = dc.call("start_date", request) as Dictionary
	if bool(first.get("ok", false)):
		return first
	var err: StringName = first.get("error", &"") as StringName
	if err != DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT:
		return first
	var hist: Array[StringName] = get_event_exclusions_for_next_date(request.girl_id)
	if hist.is_empty():
		return first
	var last_only: Array[StringName] = begin_new_event_cycle(request.girl_id)
	request.excluded_event_ids = last_only
	var second: Dictionary = dc.call("start_date", request) as Dictionary
	return second


func _girl_exists(girl_id: StringName) -> bool:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null or String(girl_id) == "":
		return false
	if db.has_method("has_girl"):
		return bool(db.call("has_girl", girl_id))
	# Avoid ContentDB.get_girl push_error for unknown IDs in availability checks.
	var overrides: Variant = db.get("_girl_overrides")
	if overrides is Dictionary and (overrides as Dictionary).has(girl_id):
		return true
	var by_id: Variant = db.get("_girls_by_id")
	if by_id is Dictionary and (by_id as Dictionary).has(girl_id):
		return true
	return false


func notify_game_day_advanced() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var ids: Array = gs.call("get_girl_ids_with_date_cooldown") as Array
	for entry in ids:
		var gid: StringName = entry as StringName
		var before: int = int(gs.call("get_girl_date_cooldown_days_remaining", gid))
		if before <= 0:
			continue
		var after: int = maxi(0, before - 1)
		gs.call("set_girl_date_cooldown_days_remaining", gid, after)
		if before == 1 and after == 0:
			girl_date_available_again.emit(gid)
