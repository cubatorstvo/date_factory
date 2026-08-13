extends Node
## Relationships autoload — apply DatingResult to persistent girl state (MODULE 10).
## Owns completion, date cooldown, event history cycle; GameState stores fields.

signal date_result_applied(result: RelationshipDateResult)
signal girl_completed(girl_id: StringName, relationship_result: RelationshipDateResult)
signal girl_date_available_again(girl_id: StringName)

const VENUE_HOME: StringName = &"apartment"
const VENUE_CAFE: StringName = &"cafe"
const CAFE_DATE_COST: int = 30
const DATE_INVITE_HOURS: Array[int] = [12, 15, 18, 21]
const DATE_DELTA_ABS_MAX: int = 20
const DATE_ARRIVAL_WINDOW_HOURS: int = 3

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _applied_date_ids: Dictionary = {}
var _auto_apply_enabled: bool = true
var _last_applied_result: RelationshipDateResult = null
var _pending_invite: Dictionary = {}


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
	if day == null:
		return
	if day.has_signal("day_advanced") and not day.is_connected("day_advanced", _on_game_day_advanced):
		day.connect("day_advanced", _on_game_day_advanced)
	if day.has_signal("hour_changed") and not day.is_connected("hour_changed", _on_game_hour_changed):
		day.connect("hour_changed", _on_game_hour_changed)


func _on_game_day_advanced(_new_day: int) -> void:
	notify_game_day_advanced()
	_expire_pending_if_missed()


func _on_game_hour_changed(_new_hour: int) -> void:
	_expire_pending_if_missed()


func _on_state_reset() -> void:
	_applied_date_ids.clear()
	_last_applied_result = null
	_pending_invite.clear()


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
	var span: int = _relationship_span_for(girl_id)
	var before: int = int(gs.call("get_girl_relationship", girl_id))
	var after: int = clampi(before + result.date_delta, -span, span)
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
	if after == span and not bool(gs.call("is_girl_conquered", girl_id)):
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
	if result.date_delta < -DATE_DELTA_ABS_MAX or result.date_delta > DATE_DELTA_ABS_MAX:
		return {"ok": false, "error": RelationshipTypes.ERR_INVALID_RESULT}
	if result.trait_delta != 0 and (result.trait_delta < -5 or result.trait_delta > 5):
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
		var avail_msg: String = str(avail.get("message", "")).strip_edges()
		if avail_msg == "":
			avail_msg = DatingTypes.user_message(status)
		out["message"] = avail_msg
		return out
	var dc: Node = get_node("/root/DatingCore")
	request.excluded_event_ids = get_event_exclusions_for_next_date(request.girl_id)
	var first: Dictionary = dc.call("start_date", request) as Dictionary
	if bool(first.get("ok", false)):
		return first
	var err: StringName = first.get("error", &"") as StringName
	first = _with_start_message(first)
	if err != DatingTypes.ERR_INSUFFICIENT_DATE_CONTENT:
		return first
	var hist: Array[StringName] = get_event_exclusions_for_next_date(request.girl_id)
	if hist.is_empty():
		return first
	var last_only: Array[StringName] = begin_new_event_cycle(request.girl_id)
	request.excluded_event_ids = last_only
	var second: Dictionary = dc.call("start_date", request) as Dictionary
	return _with_start_message(second)

func get_date_invite_venues() -> Array:
	var out: Array = []
	for row_v in DateVenueCatalog.list_invite_venues():
		var base: Dictionary = row_v as Dictionary
		var location_id: StringName = StringName(base.get("location_id", &""))
		out.append({
			"location_id": location_id,
			"label": str(base.get("label", "")),
			"cost": int(base.get("cost", 0)),
			"available": true,
			"reason": "",
		})
	return out


func get_date_invite_hours() -> Array:
	var out: Array = []
	for slot in DATE_INVITE_HOURS:
		var hour: int = int(slot)
		out.append({
			"hour": hour,
			"label": "%02d:00" % hour,
			"next_day": _invite_hour_is_next_day(hour),
		})
	return out


func confirm_date_invite(
	girl_id: StringName,
	location_id: StringName,
	hour: int,
	_prepare_apartment: bool = false,
) -> Dictionary:
	if String(girl_id) == "":
		return _date_invite_fail(DatingTypes.ERR_NO_GIRL, "Не выбрана девушка.")
	if girl_id == StoryIds.GIRL_FINAL_TARGET:
		return _date_invite_fail(DatingTypes.ERR_FINAL_TARGET, "Эту девушку нельзя пригласить.")
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or not bool(gs.call("has_girl_contact", girl_id)):
		return _date_invite_fail(DatingTypes.ERR_NO_CONTACT, "Сначала получи номер.")
	if not can_start_date(girl_id):
		var avail: Dictionary = get_date_availability(girl_id)
		var status: StringName = avail.get("status", RelationshipTypes.AVAIL_UNKNOWN_GIRL) as StringName
		var avail_msg: String = str(avail.get("message", ""))
		if avail_msg.strip_edges() == "":
			avail_msg = "Свидание сейчас недоступно."
		return _date_invite_fail(status, avail_msg)
	if not DATE_INVITE_HOURS.has(hour):
		return _date_invite_fail(DatingTypes.ERR_INVALID_HOUR, "Недопустимое время.")
	if not _pending_invite.is_empty():
		return _date_invite_fail(
			DatingTypes.ERR_INVITE_PENDING,
			"Сначала приди на уже назначенное свидание.",
		)
	if not DateVenueCatalog.is_invite_venue(location_id):
		return _date_invite_fail(DatingTypes.ERR_INVALID_LOCATION, "Недопустимое место.")
	var venue_row: Dictionary = {}
	var venues: Array = get_date_invite_venues()
	for row_v in venues:
		if not (row_v is Dictionary):
			continue
		var row: Dictionary = row_v as Dictionary
		if row.get("location_id", &"") == location_id:
			venue_row = row
			break
	if venue_row.is_empty():
		return _date_invite_fail(DatingTypes.ERR_INVALID_LOCATION, "Недопустимое место.")
	var venue_cost: int = int(venue_row.get("cost", DateVenueCatalog.invite_cost(location_id)))
	var charged: int = 0
	if venue_cost > 0:
		if not bool(gs.call("can_afford", venue_cost)):
			return _date_invite_fail(DatingTypes.ERR_CANNOT_AFFORD, "Не хватает денег.")
		if not bool(gs.call("spend_money", venue_cost)):
			return _date_invite_fail(DatingTypes.ERR_CANNOT_AFFORD, "Не хватает денег.")
		charged = venue_cost
	var db: Node = get_node_or_null("/root/ContentDB")
	var girl: GirlDefinition = null
	if db != null:
		var girl_v: Variant = db.call("get_girl", girl_id)
		girl = girl_v as GirlDefinition
	if girl == null:
		_refund_invite_charge(gs, charged)
		return _date_invite_fail(DatingTypes.ERR_NO_GIRL, "Не выбрана девушка.")
	var appointment_day: int = _appointment_day_for_hour(hour)
	var venue_label: String = str(venue_row.get("label", ""))
	if venue_label.strip_edges() == "":
		venue_label = String(location_id)
	_pending_invite = {
		"girl_id": girl_id,
		"location_id": location_id,
		"hour": hour,
		"day": appointment_day,
	}
	var message: String = "Свидание в %s в %02d:00. Приходи сам." % [venue_label, hour]
	return {
		"ok": true,
		"error": DatingTypes.ERR_OK,
		"message": message,
		"pending": true,
		"girl_id": girl_id,
		"location_id": location_id,
		"hour": hour,
		"day": appointment_day,
	}


func get_pending_date_invite() -> Dictionary:
	return _pending_invite.duplicate()


func export_pending_date_invite() -> Dictionary:
	return get_pending_date_invite()


func restore_pending_date_invite(data: Dictionary) -> void:
	_pending_invite.clear()
	if data.is_empty():
		return
	var girl_id: StringName = StringName(str(data.get("girl_id", "")))
	var location_id: StringName = StringName(str(data.get("location_id", "")))
	var hour: int = int(data.get("hour", -1))
	var day: int = int(data.get("day", 0))
	if String(girl_id) == "" or not DateVenueCatalog.is_invite_venue(location_id):
		return
	if not DATE_INVITE_HOURS.has(hour) or day < 1:
		return
	_pending_invite = {
		"girl_id": girl_id,
		"location_id": location_id,
		"hour": hour,
		"day": day,
	}


func peek_pending_date_status(location_id: StringName) -> Dictionary:
	_expire_pending_if_missed()
	if _pending_invite.is_empty():
		return {"has": false}
	var pending_loc: StringName = StringName(str(_pending_invite.get("location_id", "")))
	var hour: int = int(_pending_invite.get("hour", 0))
	var day: int = int(_pending_invite.get("day", 0))
	var girl_id: StringName = StringName(str(_pending_invite.get("girl_id", "")))
	var here: bool = pending_loc == location_id
	var ready: bool = here and _pending_is_ready()
	var too_early: bool = here and not ready and _pending_is_in_future()
	var message: String = ""
	if too_early:
		message = "Приходи к %02d:00." % hour
	elif here and ready:
		message = "Начать свидание"
	return {
		"has": true,
		"here": here,
		"ready": ready,
		"too_early": too_early,
		"girl_id": girl_id,
		"location_id": pending_loc,
		"hour": hour,
		"day": day,
		"message": message,
	}


func try_start_pending_date_at(location_id: StringName) -> Dictionary:
	_expire_pending_if_missed()
	if _pending_invite.is_empty():
		return _date_invite_fail(DatingTypes.ERR_NO_PENDING, "Нет назначенного свидания.")
	var pending_loc: StringName = StringName(str(_pending_invite.get("location_id", "")))
	if pending_loc != location_id:
		return _date_invite_fail(DatingTypes.ERR_WRONG_VENUE, "Свидание в другом месте.")
	if _pending_is_in_future():
		var hour: int = int(_pending_invite.get("hour", 0))
		return _date_invite_fail(DatingTypes.ERR_DATE_TOO_EARLY, "Приходи к %02d:00." % hour)
	if not _pending_is_ready():
		_pending_invite.clear()
		return _date_invite_fail(DatingTypes.ERR_DATE_MISSED, "Она уже ушла.")
	var girl_id: StringName = StringName(str(_pending_invite.get("girl_id", "")))
	var db: Node = get_node_or_null("/root/ContentDB")
	var girl: GirlDefinition = null
	if db != null:
		girl = db.call("get_girl", girl_id) as GirlDefinition
	if girl == null:
		_pending_invite.clear()
		return _date_invite_fail(DatingTypes.ERR_NO_GIRL, "Не выбрана девушка.")
	var request: DatingStartRequest = DatingStartRequest.new()
	request.girl_id = girl_id
	request.location_id = location_id
	var greetings: Array[StringName] = []
	for gid in girl.dating_greeting_ids:
		greetings.append(gid)
	request.greeting_ids = greetings
	request.farewell_id = girl.dating_farewell_id
	var started: Dictionary = start_date_with_history(request)
	if bool(started.get("ok", false)):
		_pending_invite.clear()
	return _with_start_message(started)


func _appointment_day_for_hour(hour: int) -> int:
	var now_day: int = 1
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null and day.has_method("get_current_day"):
		now_day = int(day.call("get_current_day"))
	if _invite_hour_is_next_day(hour):
		return now_day + 1
	return now_day


func _invite_hour_is_next_day(hour: int) -> bool:
	var now_m: int = _minutes_into_day()
	var end_m: int = hour * 60 + DATE_ARRIVAL_WINDOW_HOURS * 60
	return now_m >= end_m


func _minutes_into_day() -> int:
	var now_hour: int = 8
	var now_minute: int = 0
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null:
		if day.has_method("get_current_hour"):
			now_hour = int(day.call("get_current_hour"))
		if day.has_method("get_current_minute"):
			now_minute = int(day.call("get_current_minute"))
	return now_hour * 60 + now_minute


func _with_start_message(started: Dictionary) -> Dictionary:
	var msg: String = str(started.get("message", "")).strip_edges()
	if msg != "":
		return started
	var code: StringName = started.get("error", &"") as StringName
	started["message"] = DatingTypes.user_message(code)
	return started


func _pending_now_minutes() -> int:
	var now_day: int = 1
	var now_hour: int = 8
	var now_minute: int = 0
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null:
		if day.has_method("get_current_day"):
			now_day = int(day.call("get_current_day"))
		if day.has_method("get_current_hour"):
			now_hour = int(day.call("get_current_hour"))
		if day.has_method("get_current_minute"):
			now_minute = int(day.call("get_current_minute"))
	return now_day * 24 * 60 + now_hour * 60 + now_minute


func _pending_start_minutes() -> int:
	var day: int = int(_pending_invite.get("day", 0))
	var hour: int = int(_pending_invite.get("hour", 0))
	return day * 24 * 60 + hour * 60


func _pending_is_in_future() -> bool:
	if _pending_invite.is_empty():
		return false
	return _pending_now_minutes() < _pending_start_minutes()


func _pending_is_ready() -> bool:
	if _pending_invite.is_empty():
		return false
	var now_m: int = _pending_now_minutes()
	var start_m: int = _pending_start_minutes()
	var end_m: int = start_m + DATE_ARRIVAL_WINDOW_HOURS * 60
	return now_m >= start_m and now_m < end_m


func _expire_pending_if_missed() -> void:
	if _pending_invite.is_empty():
		return
	if _pending_is_in_future() or _pending_is_ready():
		return
	_pending_invite.clear()


func _clear_apartment_prep_if(gs: Node, do_prepare: bool) -> void:
	if not do_prepare or gs == null or not gs.has_method("set_story_flag"):
		return
	gs.call("set_story_flag", DateVenueCatalog.PREPARED_FLAG, false)


func _relationship_span_for(girl_id: StringName) -> int:
	var db: Node = get_node_or_null("/root/ContentDB")
	if db == null:
		return 5
	var girl: GirlDefinition = db.call("get_girl", girl_id) as GirlDefinition
	if girl == null:
		return 5
	var span: int = int(girl.relationship_span)
	if span != 5 and span != 10:
		return 5
	return span


func _date_invite_fail(error: StringName, message: String) -> Dictionary:
	return {"ok": false, "error": error, "message": message}


func _refund_invite_charge(gs: Node, charged: int) -> void:
	if gs == null or charged <= 0:
		return
	if gs.has_method("add_money"):
		gs.call("add_money", charged)


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
