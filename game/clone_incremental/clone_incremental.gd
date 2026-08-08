extends Node
## Clone Incremental owner (MODULE 18).
## Autoload name: CloneIncremental. Aggregate GameState counts/upgrades are source of truth.
## Real-time production + Money/dates rates. No GameDay simulation. No individual clone entities.

signal clone_produced(new_total: int)
signal assignment_changed(total: int, working: int, dating: int, free: int)
signal upgrade_purchased(upgrade_type: int, new_level: int)
signal automated_money_granted(amount: int)
signal automated_date_completed()
signal backlog_fulfilled_by_clone(request_id: int)
signal late_experience_granted(amount: int)

var _production_elapsed_seconds: float = 0.0
var _money_fraction: float = 0.0
var _date_fraction: float = 0.0
var _signals_connected: bool = false
var _updating_rates: bool = false
var _realtime_enabled: bool = true


func _ready() -> void:
	_connect_signals()
	recalculate_rates()
	DfLog.info("MODULE_18", "CloneIncremental ready")


func _process(delta: float) -> void:
	if not _realtime_enabled:
		return
	advance_simulation(delta)


## Headless tests disable realtime ticks and drive advance_simulation_for_test instead.
func set_realtime_simulation(enabled: bool) -> void:
	_realtime_enabled = enabled


func _connect_signals() -> void:
	if _signals_connected:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
		if gs.has_signal("clone_counts_changed") and not gs.is_connected("clone_counts_changed", _on_clone_counts_changed):
			gs.connect("clone_counts_changed", _on_clone_counts_changed)
		if gs.has_signal("clone_upgrade_changed") and not gs.is_connected("clone_upgrade_changed", _on_clone_upgrade_changed):
			gs.connect("clone_upgrade_changed", _on_clone_upgrade_changed)
	_signals_connected = true


func _on_state_reset() -> void:
	_production_elapsed_seconds = 0.0
	_money_fraction = 0.0
	_date_fraction = 0.0
	recalculate_rates()


func _on_clone_counts_changed(_total: int, _working: int, _dating: int, _free: int) -> void:
	recalculate_rates()


func _on_clone_upgrade_changed(_upgrade_type: int, _new_level: int, _previous_level: int) -> void:
	recalculate_rates()


func is_active() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	return int(gs.call("get_total_clones")) >= 1


func get_production_elapsed() -> float:
	return _production_elapsed_seconds


func get_production_interval() -> float:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return CloneIncrementalTypes.BASE_PRODUCTION_INTERVAL
	var level: int = int(gs.call("get_clone_production_upgrade_level"))
	var local_interval: float = CloneIncrementalTypes.production_interval(level)
	var mult: float = _external_production_multiplier()
	if mult <= 0.0:
		mult = 1.0
	return maxf(LateGameTypes.MIN_EFFECTIVE_PRODUCTION_INTERVAL, local_interval / mult)


func get_seconds_to_next_clone() -> float:
	if not is_active():
		return 0.0
	var interval: float = get_production_interval()
	return maxf(0.0, interval - _production_elapsed_seconds)


func get_status() -> CloneIncrementalStatus:
	return snapshot()


func snapshot() -> CloneIncrementalStatus:
	var status: CloneIncrementalStatus = CloneIncrementalStatus.new()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return status
	status.total = int(gs.call("get_total_clones"))
	status.working = int(gs.call("get_clones_working"))
	status.dating = int(gs.call("get_clones_dating"))
	status.free = int(gs.call("get_free_clones"))
	status.active = status.total >= 1
	status.production_level = int(gs.call("get_clone_production_upgrade_level"))
	status.work_level = int(gs.call("get_clone_work_upgrade_level"))
	status.dating_level = int(gs.call("get_clone_dating_upgrade_level"))
	status.production_interval = get_production_interval()
	status.production_elapsed = _production_elapsed_seconds
	if status.active:
		status.seconds_to_next_clone = maxf(0.0, status.production_interval - _production_elapsed_seconds)
	else:
		status.seconds_to_next_clone = 0.0
	status.money_per_minute = float(gs.call("get_money_per_minute"))
	status.dates_per_minute = float(gs.call("get_dates_per_minute"))
	var overload: Node = get_node_or_null("/root/DatingOverload")
	if overload != null and overload.has_method("get_backlog_count"):
		status.backlog_count = int(overload.call("get_backlog_count"))
	return status


func recalculate_rates() -> void:
	if _updating_rates:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	_updating_rates = true
	var total: int = int(gs.call("get_total_clones"))
	if total < 1:
		gs.call("set_late_rates", 0.0, 0.0)
		_updating_rates = false
		return
	var working: int = int(gs.call("get_clones_working"))
	var dating: int = int(gs.call("get_clones_dating"))
	var work_level: int = int(gs.call("get_clone_work_upgrade_level"))
	var dating_level: int = int(gs.call("get_clone_dating_upgrade_level"))
	var mpm: float = (
		float(working)
		* CloneIncrementalTypes.money_per_minute_per_clone(work_level)
		* _external_work_multiplier()
	)
	var dpm: float = (
		float(dating)
		* CloneIncrementalTypes.dates_per_minute_per_clone(dating_level)
		* _external_dating_multiplier()
	)
	gs.call("set_late_rates", mpm, dpm)
	_updating_rates = false


## MODULE 20: recompute rates under global multipliers; preserve production elapsed.
func refresh_external_modifiers() -> void:
	recalculate_rates()
	_resolve_production_spawns()


func export_runtime_state() -> Dictionary:
	return {
		"production_elapsed_seconds": _production_elapsed_seconds,
		"money_fraction": _money_fraction,
		"date_fraction": _date_fraction,
	}


func normalize_runtime_state(data: Dictionary) -> Dictionary:
	## Pure validation/normalization. No mutation of live runtime.
	if data == null:
		return {"ok": false}
	if (
		not data.has("production_elapsed_seconds")
		or not data.has("money_fraction")
		or not data.has("date_fraction")
	):
		return {"ok": false}
	var elapsed: float = float(data["production_elapsed_seconds"])
	var money_f: float = float(data["money_fraction"])
	var date_f: float = float(data["date_fraction"])
	if not is_finite(elapsed) or not is_finite(money_f) or not is_finite(date_f):
		return {"ok": false}
	if elapsed < 0.0 or money_f < 0.0 or date_f < 0.0:
		return {"ok": false}
	# Normalize fractions into [0, 1).
	money_f = money_f - floorf(money_f)
	date_f = date_f - floorf(date_f)
	if money_f < 0.0 or money_f >= 1.0 or date_f < 0.0 or date_f >= 1.0:
		return {"ok": false}
	return {
		"ok": true,
		"production_elapsed_seconds": elapsed,
		"money_fraction": money_f,
		"date_fraction": date_f,
	}


func restore_runtime_state(data: Dictionary) -> bool:
	var normalized: Dictionary = normalize_runtime_state(data)
	if not bool(normalized.get("ok", false)):
		push_error("[CloneIncremental] restore_runtime_state rejected")
		return false
	_production_elapsed_seconds = float(normalized["production_elapsed_seconds"])
	_money_fraction = float(normalized["money_fraction"])
	_date_fraction = float(normalized["date_fraction"])
	recalculate_rates()
	_resolve_production_spawns()
	return true


func advance_simulation_for_test(seconds: float) -> void:
	if seconds <= 0.0:
		return
	advance_simulation(seconds)


func advance_simulation(delta: float) -> void:
	if delta <= 0.0:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if int(gs.call("get_total_clones")) < 1:
		_production_elapsed_seconds = 0.0
		return
	_advance_production(delta)
	_advance_money(delta)
	_advance_dates(delta)


func _advance_production(delta: float) -> void:
	_production_elapsed_seconds += delta
	_resolve_production_spawns()


func _resolve_production_spawns() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if int(gs.call("get_total_clones")) < 1:
		return
	if not is_finite(_production_elapsed_seconds) or _production_elapsed_seconds < 0.0:
		_production_elapsed_seconds = 0.0
		return
	var interval: float = get_production_interval()
	if not is_finite(interval) or interval <= 0.0:
		return
	while _production_elapsed_seconds >= interval:
		_production_elapsed_seconds -= interval
		var total: int = int(gs.call("get_total_clones"))
		var working: int = int(gs.call("get_clones_working"))
		var dating: int = int(gs.call("get_clones_dating"))
		var ok: bool = bool(gs.call("set_clone_counts", total + 1, working, dating))
		if not ok:
			break
		clone_produced.emit(total + 1)
		interval = get_production_interval()


func _advance_money(delta: float) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var mpm: float = float(gs.call("get_money_per_minute"))
	if mpm <= 0.0:
		return
	_money_fraction += mpm * delta / 60.0
	if _money_fraction < 1.0:
		return
	var whole: int = int(floor(_money_fraction))
	_money_fraction -= float(whole)
	gs.call("add_money", whole)
	automated_money_granted.emit(whole)


func _advance_dates(delta: float) -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	var dpm: float = float(gs.call("get_dates_per_minute"))
	if dpm <= 0.0:
		return
	_date_fraction += dpm * delta / 60.0
	while _date_fraction >= 1.0:
		_date_fraction -= 1.0
		_process_one_automated_date()


func _process_one_automated_date() -> void:
	var overload: Node = get_node_or_null("/root/DatingOverload")
	var backlog: int = 0
	if overload != null and overload.has_method("get_backlog_count"):
		backlog = int(overload.call("get_backlog_count"))
	if backlog > 0 and overload != null and overload.has_method("fulfill_oldest_demand_by_clone"):
		var fulfilled_box: Array = [-1]
		if overload.has_signal("demand_fulfilled"):
			var on_fulfilled: Callable = func(request_id: int) -> void:
				fulfilled_box[0] = request_id
			overload.connect("demand_fulfilled", on_fulfilled, CONNECT_ONE_SHOT)
		var fulfilled: bool = bool(overload.call("fulfill_oldest_demand_by_clone"))
		if fulfilled:
			automated_date_completed.emit()
			var fulfilled_id: int = int(fulfilled_box[0])
			if fulfilled_id > 0:
				backlog_fulfilled_by_clone.emit(fulfilled_id)
			return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	gs.call("add_experience", 1)
	automated_date_completed.emit()
	late_experience_granted.emit(1)


func assign_one_to_work() -> bool:
	return _assign_delta(1, 0)


func assign_one_to_dating() -> bool:
	return _assign_delta(0, 1)


func unassign_one_from_work() -> bool:
	return _assign_delta(-1, 0)


func unassign_one_from_dating() -> bool:
	return _assign_delta(0, -1)


func assign_all_free_to_work() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var free: int = int(gs.call("get_free_clones"))
	if free <= 0:
		return false
	return _assign_delta(free, 0)


func assign_all_free_to_dating() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var free: int = int(gs.call("get_free_clones"))
	if free <= 0:
		return false
	return _assign_delta(0, free)


func _assign_delta(work_delta: int, dating_delta: int) -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	var total: int = int(gs.call("get_total_clones"))
	if total < 1:
		return false
	var working: int = int(gs.call("get_clones_working"))
	var dating: int = int(gs.call("get_clones_dating"))
	var next_working: int = working + work_delta
	var next_dating: int = dating + dating_delta
	if next_working < 0 or next_dating < 0:
		return false
	if next_working + next_dating > total:
		return false
	if next_working == working and next_dating == dating:
		return false
	var ok: bool = bool(gs.call("set_clone_counts", total, next_working, next_dating))
	if not ok:
		return false
	assignment_changed.emit(total, next_working, next_dating, total - next_working - next_dating)
	return true


func get_upgrade_cost(upgrade_type: int) -> int:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return -1
	var level: int = _get_upgrade_level(gs, upgrade_type)
	if level < 0:
		return -1
	return CloneIncrementalTypes.upgrade_cost(level)


func buy_upgrade(upgrade_type: int) -> CloneUpgradePurchaseResult:
	var result: CloneUpgradePurchaseResult = CloneUpgradePurchaseResult.new()
	result.upgrade_type = upgrade_type as CloneIncrementalTypes.UpgradeType
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		result.error = CloneIncrementalTypes.UpgradePurchaseError.INVALID_UPGRADE
		return result
	if not is_active():
		result.error = CloneIncrementalTypes.UpgradePurchaseError.LOCKED
		return result
	if (
		upgrade_type != int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED)
		and upgrade_type != int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY)
		and upgrade_type != int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY)
	):
		result.error = CloneIncrementalTypes.UpgradePurchaseError.INVALID_UPGRADE
		return result
	var level: int = _get_upgrade_level(gs, upgrade_type)
	if level >= CloneIncrementalTypes.MAX_LEVEL:
		result.error = CloneIncrementalTypes.UpgradePurchaseError.MAX_LEVEL
		result.new_level = level
		return result
	var cost: int = CloneIncrementalTypes.upgrade_cost(level)
	if cost < 0:
		result.error = CloneIncrementalTypes.UpgradePurchaseError.MAX_LEVEL
		result.new_level = level
		return result
	if not bool(gs.call("can_afford", cost)):
		result.error = CloneIncrementalTypes.UpgradePurchaseError.NOT_ENOUGH_MONEY
		result.new_level = level
		return result
	if not bool(gs.call("spend_money", cost)):
		result.error = CloneIncrementalTypes.UpgradePurchaseError.NOT_ENOUGH_MONEY
		result.new_level = level
		return result
	var next_level: int = level + 1
	var set_ok: bool = _set_upgrade_level(gs, upgrade_type, next_level)
	if not set_ok:
		# Refund on unexpected failure.
		gs.call("add_money", cost)
		result.error = CloneIncrementalTypes.UpgradePurchaseError.INVALID_UPGRADE
		result.new_level = level
		return result
	result.ok = true
	result.error = CloneIncrementalTypes.UpgradePurchaseError.OK
	result.new_level = next_level
	result.money_spent = cost
	result.money_after = int(gs.call("get_money"))
	if upgrade_type == int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED):
		# Keep elapsed progress; may immediately spawn with remainder (spec §19).
		_resolve_production_spawns()
	upgrade_purchased.emit(upgrade_type, next_level)
	return result


func _external_production_multiplier() -> float:
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge == null or not lge.has_method("get_production_multiplier"):
		return 1.0
	var mult: float = float(lge.call("get_production_multiplier"))
	if mult <= 0.0:
		return 1.0
	return mult


func _external_work_multiplier() -> float:
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge == null or not lge.has_method("get_work_multiplier"):
		return 1.0
	var mult: float = float(lge.call("get_work_multiplier"))
	if mult <= 0.0:
		return 1.0
	return mult


func _external_dating_multiplier() -> float:
	var lge: Node = get_node_or_null("/root/LateGameExpansion")
	if lge == null or not lge.has_method("get_dating_multiplier"):
		return 1.0
	var mult: float = float(lge.call("get_dating_multiplier"))
	if mult <= 0.0:
		return 1.0
	return mult


func _get_upgrade_level(gs: Node, upgrade_type: int) -> int:
	match upgrade_type:
		int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED):
			return int(gs.call("get_clone_production_upgrade_level"))
		int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY):
			return int(gs.call("get_clone_work_upgrade_level"))
		int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY):
			return int(gs.call("get_clone_dating_upgrade_level"))
	return -1


func _set_upgrade_level(gs: Node, upgrade_type: int, level: int) -> bool:
	match upgrade_type:
		int(CloneIncrementalTypes.UpgradeType.PRODUCTION_SPEED):
			return bool(gs.call("set_clone_production_upgrade_level", level))
		int(CloneIncrementalTypes.UpgradeType.WORK_EFFICIENCY):
			return bool(gs.call("set_clone_work_upgrade_level", level))
		int(CloneIncrementalTypes.UpgradeType.DATING_EFFICIENCY):
			return bool(gs.call("set_clone_dating_upgrade_level", level))
	return false
