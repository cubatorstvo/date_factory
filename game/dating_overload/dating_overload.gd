extends Node
## Dating Overload owner (MODULE 16).
## Autoload name: DatingOverload. Persistent state lives in GameState.
## No _process. No calendar. No Scientist / Lab / clones.

signal overload_started()
signal demand_added(request_id: int)
signal demand_fulfilled(request_id: int)
signal backlog_changed(backlog_count: int)
signal personal_capacity_changed()
signal feed_boost_used()
signal problem_recognized()
signal clone_solution_needed()

var _signals_connected: bool = false
var _recognition_emitted: bool = false


func _ready() -> void:
	_connect_signals()
	_ensure_started_from_media()
	DfLog.info("MODULE_16", "DatingOverload ready")


func _connect_signals() -> void:
	if _signals_connected:
		return
	var media: Node = get_node_or_null("/root/Media")
	if media != null and media.has_signal("overload_ready"):
		if not media.is_connected("overload_ready", _on_media_overload_ready):
			media.connect("overload_ready", _on_media_overload_ready)
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null and day.has_signal("day_advanced"):
		if not day.is_connected("day_advanced", _on_day_advanced):
			day.connect("day_advanced", _on_day_advanced)
	var rel: Node = get_node_or_null("/root/Relationships")
	if rel != null and rel.has_signal("date_result_applied"):
		if not rel.is_connected("date_result_applied", _on_date_result_applied):
			rel.connect("date_result_applied", _on_date_result_applied)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null and gs.has_signal("state_reset"):
		if not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	_signals_connected = true


func _on_state_reset() -> void:
	_recognition_emitted = false


func _on_media_overload_ready() -> void:
	_ensure_started_from_media()


func _on_day_advanced(_new_day: int) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if not bool(gs.call("is_dating_overload_started")):
		return
	if bool(gs.call("is_dating_overload_problem_recognized")):
		return
	_age_waiting_requests()
	_generate_daily_wave()
	_try_recognize_problem()


func _on_date_result_applied(result: RelationshipDateResult) -> void:
	if result == null or not result.ok:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if not bool(gs.call("is_dating_overload_started")):
		return
	var day: Node = get_node_or_null("/root/GameDay")
	if day == null:
		return
	var current_day: int = int(day.call("get_current_day"))
	gs.call("set_dating_overload_last_personal_date_day", current_day)
	gs.call("increment_dating_overload_personal_dates_completed")
	personal_capacity_changed.emit()
	var fulfilled_id: int = _fulfill_oldest_for_girl(result.girl_id, current_day)
	if fulfilled_id > 0:
		demand_fulfilled.emit(fulfilled_id)
		backlog_changed.emit(get_backlog_count())
	_try_recognize_problem()


func is_started() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("is_dating_overload_started"))


func is_problem_recognized() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return bool(gs.call("is_dating_overload_problem_recognized"))


func can_start_personal_date() -> bool:
	return get_personal_date_availability() == DatingOverloadTypes.PersonalDateAvailability.AVAILABLE


func get_personal_date_availability() -> DatingOverloadTypes.PersonalDateAvailability:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return DatingOverloadTypes.PersonalDateAvailability.AVAILABLE
	if not bool(gs.call("is_dating_overload_started")):
		return DatingOverloadTypes.PersonalDateAvailability.AVAILABLE
	var last_day: int = int(gs.call("get_dating_overload_last_personal_date_day"))
	var current_day: int = int(day.call("get_current_day"))
	if last_day == current_day:
		return DatingOverloadTypes.PersonalDateAvailability.BODY_CAPACITY_USED
	return DatingOverloadTypes.PersonalDateAvailability.AVAILABLE


func get_backlog_count() -> int:
	var n: int = 0
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e != null and e.is_backlog():
			n += 1
	return n


func get_overdue_count() -> int:
	var n: int = 0
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e != null and e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			n += 1
	return n


func get_fulfilled_count() -> int:
	var n: int = 0
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e != null and e.status == DatingOverloadTypes.DatingDemandStatus.FULFILLED:
			n += 1
	return n


func get_total_generated() -> int:
	return get_demand_entries().size()


func get_demand_count_for_girl(girl_id: StringName) -> int:
	if String(girl_id) == "":
		return 0
	var n: int = 0
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e != null and e.girl_id == girl_id and e.is_backlog():
			n += 1
	return n


func get_demand_entries() -> Array[DatingDemandEntry]:
	var out: Array[DatingDemandEntry] = []
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return out
	var raw: Array = gs.call("get_dating_demand_entries") as Array
	for item in raw:
		var e: DatingDemandEntry = item as DatingDemandEntry
		if e != null:
			out.append(e)
	return out


func get_backlog_entries_sorted() -> Array[DatingDemandEntry]:
	var overdue: Array[DatingDemandEntry] = []
	var early: Array[DatingDemandEntry] = []
	var late: Array[DatingDemandEntry] = []
	var day: Node = get_node_or_null("/root/GameDay")
	var current_day: int = 1
	if day != null:
		current_day = int(day.call("get_current_day"))
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e == null or not e.is_backlog():
			continue
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			overdue.append(e)
		elif e.appointment_day == current_day and e.slot == DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING:
			early.append(e)
		elif e.appointment_day == current_day and e.slot == DatingOverloadTypes.DatingDemandSlot.LATE_EVENING:
			late.append(e)
		elif e.status == DatingOverloadTypes.DatingDemandStatus.WAITING:
			# Future / same-day without explicit slot bucket — keep after early by request_id via late bucket fallback.
			if e.slot == DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING:
				early.append(e)
			else:
				late.append(e)
	overdue.sort_custom(func(a: DatingDemandEntry, b: DatingDemandEntry) -> bool:
		return a.request_id < b.request_id
	)
	early.sort_custom(func(a: DatingDemandEntry, b: DatingDemandEntry) -> bool:
		return a.request_id < b.request_id
	)
	late.sort_custom(func(a: DatingDemandEntry, b: DatingDemandEntry) -> bool:
		return a.request_id < b.request_id
	)
	var out: Array[DatingDemandEntry] = []
	for e1 in overdue:
		out.append(e1)
	for e2 in early:
		out.append(e2)
	for e3 in late:
		out.append(e3)
	return out


func can_use_feed_boost() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return false
	if not bool(gs.call("is_dating_overload_started")):
		return false
	if bool(gs.call("is_dating_overload_problem_recognized")):
		return false
	var last: int = int(gs.call("get_dating_overload_last_feed_boost_day"))
	var current: int = int(day.call("get_current_day"))
	return last != current


func use_feed_boost() -> bool:
	if not can_use_feed_boost():
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return false
	var current: int = int(day.call("get_current_day"))
	gs.call("add_media_attention", DatingOverloadTypes.FEED_BOOST_ATTENTION)
	gs.call("set_dating_overload_boost_pending", true)
	gs.call("set_dating_overload_last_feed_boost_day", current)
	feed_boost_used.emit()
	return true


func get_status() -> DatingOverloadStatus:
	var status: DatingOverloadStatus = DatingOverloadStatus.new()
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return status
	var current_day: int = int(day.call("get_current_day"))
	status.active = bool(gs.call("is_dating_overload_started"))
	status.problem_recognized = bool(gs.call("is_dating_overload_problem_recognized"))
	status.current_day = current_day
	status.capacity_per_day = DatingOverloadTypes.PERSONAL_DATE_CAPACITY_PER_DAY
	var last_personal: int = int(gs.call("get_dating_overload_last_personal_date_day"))
	if status.active and last_personal == current_day:
		status.capacity_used_today = 1
	else:
		status.capacity_used_today = 0
	status.total_generated = get_total_generated()
	status.fulfilled_count = get_fulfilled_count()
	status.backlog_count = get_backlog_count()
	status.overdue_count = get_overdue_count()
	status.feed_boost_available = can_use_feed_boost()
	status.boost_pending = bool(gs.call("is_dating_overload_boost_pending"))
	return status


func _ensure_started_from_media() -> void:
	var media: Node = get_node_or_null("/root/Media")
	if media == null or not media.has_method("is_overload_ready"):
		return
	if not bool(media.call("is_overload_ready")):
		return
	_try_activate()


func _try_activate() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return
	if int(gs.call("get_stage")) != int(GameTypes.GameStage.STAGE_4):
		return
	if bool(gs.call("is_dating_overload_started")):
		return
	var current_day: int = int(day.call("get_current_day"))
	if not bool(gs.call("mark_dating_overload_started", current_day)):
		return
	overload_started.emit()
	var created: int = _generate_wave(
		DatingOverloadTypes.FIRST_WAVE_COUNT,
		[
			DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING,
			DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING,
			DatingOverloadTypes.DatingDemandSlot.LATE_EVENING,
		],
	)
	if created == 0:
		push_warning("[DatingOverload] activation with zero offers; will retry next GameDay")
	backlog_changed.emit(get_backlog_count())


func _generate_daily_wave() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var boost: bool = bool(gs.call("is_dating_overload_boost_pending"))
	if boost:
		gs.call("set_dating_overload_boost_pending", false)
		_generate_wave(
			DatingOverloadTypes.BOOST_WAVE_COUNT,
			[
				DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING,
				DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING,
				DatingOverloadTypes.DatingDemandSlot.LATE_EVENING,
			],
		)
	else:
		_generate_wave(
			DatingOverloadTypes.BASE_NEW_REQUESTS_PER_DAY,
			[
				DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING,
				DatingOverloadTypes.DatingDemandSlot.LATE_EVENING,
			],
		)
	backlog_changed.emit(get_backlog_count())


func _generate_wave(count: int, slot_pattern: Array) -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	var media: Node = get_node_or_null("/root/Media")
	if gs == null or day == null or media == null:
		return 0
	var offers: Array[StringName] = []
	var raw_offers: Array = media.call("get_incoming_offer_girl_ids") as Array
	for oid in raw_offers:
		offers.append(oid as StringName)
	if offers.is_empty():
		push_warning("[DatingOverload] no incoming offers for demand wave")
		return 0
	var current_day: int = int(day.call("get_current_day"))
	var created: int = 0
	for i in range(count):
		var cursor: int = int(gs.call("get_dating_overload_candidate_cursor"))
		var girl_id: StringName = offers[cursor % offers.size()]
		gs.call("set_dating_overload_candidate_cursor", cursor + 1)
		var request_id: int = int(gs.call("allocate_dating_demand_request_id"))
		var slot: DatingOverloadTypes.DatingDemandSlot = DatingOverloadTypes.DatingDemandSlot.EARLY_EVENING
		if i < slot_pattern.size():
			slot = slot_pattern[i] as DatingOverloadTypes.DatingDemandSlot
		var entry: DatingDemandEntry = DatingDemandEntry.new()
		entry.request_id = request_id
		entry.girl_id = girl_id
		entry.created_day = current_day
		entry.appointment_day = current_day
		entry.slot = slot
		entry.status = DatingOverloadTypes.DatingDemandStatus.WAITING
		entry.fulfilled_day = -1
		if bool(gs.call("append_dating_demand", entry)):
			created += 1
			demand_added.emit(request_id)
	return created


func _age_waiting_requests() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return
	var current_day: int = int(day.call("get_current_day"))
	var changed: bool = false
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e == null:
			continue
		if e.status != DatingOverloadTypes.DatingDemandStatus.WAITING:
			continue
		if e.appointment_day < current_day:
			if bool(gs.call("set_dating_demand_status", e.request_id, int(DatingOverloadTypes.DatingDemandStatus.OVERDUE))):
				changed = true
	if changed:
		backlog_changed.emit(get_backlog_count())


func _fulfill_oldest_for_girl(girl_id: StringName, current_day: int) -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null or String(girl_id) == "":
		return -1
	var overdue: Array[DatingDemandEntry] = []
	var waiting: Array[DatingDemandEntry] = []
	for entry in get_demand_entries():
		var e: DatingDemandEntry = entry as DatingDemandEntry
		if e == null or e.girl_id != girl_id:
			continue
		if e.status == DatingOverloadTypes.DatingDemandStatus.OVERDUE:
			overdue.append(e)
		elif e.status == DatingOverloadTypes.DatingDemandStatus.WAITING:
			waiting.append(e)
	overdue.sort_custom(func(a: DatingDemandEntry, b: DatingDemandEntry) -> bool:
		return a.request_id < b.request_id
	)
	waiting.sort_custom(func(a: DatingDemandEntry, b: DatingDemandEntry) -> bool:
		return a.request_id < b.request_id
	)
	var target: DatingDemandEntry = null
	if not overdue.is_empty():
		target = overdue[0]
	elif not waiting.is_empty():
		target = waiting[0]
	if target == null:
		return -1
	if bool(gs.call("mark_dating_demand_fulfilled", target.request_id, current_day)):
		return target.request_id
	return -1


func _try_recognize_problem() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var day: Node = get_node_or_null("/root/GameDay")
	if gs == null or day == null:
		return
	if not bool(gs.call("is_dating_overload_started")):
		return
	if bool(gs.call("is_dating_overload_problem_recognized")):
		return
	var start_day: int = int(gs.call("get_dating_overload_start_day"))
	var current_day: int = int(day.call("get_current_day"))
	if current_day < start_day + DatingOverloadTypes.RECOGNITION_MIN_DAYS:
		return
	if get_total_generated() < DatingOverloadTypes.RECOGNITION_MIN_GENERATED:
		return
	if get_backlog_count() < DatingOverloadTypes.RECOGNITION_MIN_BACKLOG:
		return
	var personal: int = int(gs.call("get_dating_overload_personal_dates_completed"))
	if personal < DatingOverloadTypes.RECOGNITION_MIN_PERSONAL_DATES:
		return
	if not bool(gs.call("mark_dating_overload_problem_recognized")):
		return
	if _recognition_emitted:
		return
	_recognition_emitted = true
	problem_recognized.emit()
	clone_solution_needed.emit()
