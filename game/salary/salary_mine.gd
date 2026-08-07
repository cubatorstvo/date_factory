extends Node
## Salary Mine service — periods, pending, advance, inertia (MODULE 13).
## Autoload name: SalaryMine. Persistent salary fields live in GameState.
## Event-driven — no _process.

signal salary_level_changed(new_level: int, old_level: int)
signal salary_period_opened(status: SalaryStatus)
signal salary_pending_changed(amount: int)
signal salary_claimed(amount: int, method: SalaryTypes.ClaimMethod)
signal passive_salary_paid(amount: int)
signal manual_salary_cycle_seen()

var _claim_busy: bool = false
var _last_known_level: int = 1
var _signals_connected: bool = false


func _ready() -> void:
	_connect_signals()
	_last_known_level = get_salary_level()
	_ensure_initial_period()
	DfLog.info("MODULE_13", "SalaryMine ready")


func get_salary_level(authority: int = -1) -> int:
	var auth: int = authority
	if auth < 0:
		var gs: Node = get_node_or_null("/root/GameState")
		if gs == null:
			return 1
		auth = int(gs.call("get_authority"))
	return 1 + auth / 3


func get_gross_salary(authority: int = -1) -> int:
	return 10 * get_salary_level(authority)


func is_salary_unlocked() -> bool:
	var story: Node = get_node_or_null("/root/Story")
	if story == null or not story.has_method("is_feature_unlocked"):
		return false
	return bool(story.call("is_feature_unlocked", StoryTypes.StoryFeature.SALARY_MINE))


func is_passive_enabled() -> bool:
	if not is_salary_unlocked():
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if not bool(gs.call("has_perk", PerkIds.CAPITAL_FINANCIAL_INERTIA)):
		return false
	return bool(gs.call("has_seen_manual_salary_cycle"))


func is_salary_advance_available() -> bool:
	if not is_salary_unlocked():
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return false
	if not bool(gs.call("has_perk", PerkIds.CAPITAL_SALARY_ADVANCE)):
		return false
	if int(gs.call("get_pending_salary")) <= 0:
		return false
	var used: int = int(gs.call("get_salary_advance_used_period"))
	var period: int = int(gs.call("get_salary_period_index"))
	return used != period


func get_status() -> SalaryStatus:
	_ensure_initial_period()
	var status: SalaryStatus = SalaryStatus.new()
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return status
	var unlocked: bool = is_salary_unlocked()
	var authority: int = int(gs.call("get_authority"))
	var level: int = get_salary_level(authority)
	var gross: int = get_gross_salary(authority)
	var passive_on: bool = is_passive_enabled()
	var passive_amount: int = 0
	if passive_on:
		passive_amount = int(floor(float(gross) * 0.25))
	status.unlocked = unlocked
	status.authority = authority
	status.salary_level = level
	status.gross_per_period = gross
	status.period_index = int(gs.call("get_salary_period_index"))
	status.pending_salary = int(gs.call("get_pending_salary"))
	status.manual_cycle_seen = bool(gs.call("has_seen_manual_salary_cycle"))
	status.passive_enabled = passive_on
	status.passive_per_period = passive_amount
	status.salary_advance_owned = bool(gs.call("has_perk", PerkIds.CAPITAL_SALARY_ADVANCE))
	status.salary_advance_used_this_period = (
		int(gs.call("get_salary_advance_used_period")) == status.period_index
		and status.period_index > 0
	)
	status.salary_advance_available = is_salary_advance_available()
	return status


## Station completion API — take all pending + money + mark manual seen if amount > 0.
func claim_manual_pending() -> SalaryClaimResult:
	var result: SalaryClaimResult = SalaryClaimResult.new()
	result.method = SalaryTypes.ClaimMethod.MANUAL_MINE
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		result.error = SalaryTypes.ClaimError.LOCKED
		return result
	result.period_index = int(gs.call("get_salary_period_index"))
	if not is_salary_unlocked():
		result.error = SalaryTypes.ClaimError.LOCKED
		result.pending_after = int(gs.call("get_pending_salary"))
		result.money_after = int(gs.call("get_money"))
		return result
	if _claim_busy:
		result.error = SalaryTypes.ClaimError.BUSY
		result.pending_after = int(gs.call("get_pending_salary"))
		result.money_after = int(gs.call("get_money"))
		return result
	var pending_before: int = int(gs.call("get_pending_salary"))
	if pending_before <= 0:
		result.error = SalaryTypes.ClaimError.NO_PENDING
		result.pending_after = 0
		result.money_after = int(gs.call("get_money"))
		return result
	_claim_busy = true
	var amount: int = int(gs.call("take_all_pending_salary"))
	if amount > 0:
		gs.call("add_money", amount)
		var first: bool = bool(gs.call("mark_manual_salary_cycle_seen"))
		result.manual_cycle_first_time = first
		if first:
			manual_salary_cycle_seen.emit()
	result.ok = true
	result.error = SalaryTypes.ClaimError.OK
	result.amount = amount
	result.pending_after = int(gs.call("get_pending_salary"))
	result.money_after = int(gs.call("get_money"))
	salary_pending_changed.emit(result.pending_after)
	salary_claimed.emit(amount, SalaryTypes.ClaimMethod.MANUAL_MINE)
	_claim_busy = false
	return result


func claim_salary_advance() -> SalaryClaimResult:
	var result: SalaryClaimResult = SalaryClaimResult.new()
	result.method = SalaryTypes.ClaimMethod.SALARY_ADVANCE
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		result.error = SalaryTypes.ClaimError.LOCKED
		return result
	result.period_index = int(gs.call("get_salary_period_index"))
	if not is_salary_unlocked():
		result.error = SalaryTypes.ClaimError.LOCKED
		result.pending_after = int(gs.call("get_pending_salary"))
		result.money_after = int(gs.call("get_money"))
		return result
	if _claim_busy:
		result.error = SalaryTypes.ClaimError.BUSY
		result.pending_after = int(gs.call("get_pending_salary"))
		result.money_after = int(gs.call("get_money"))
		return result
	if not bool(gs.call("has_perk", PerkIds.CAPITAL_SALARY_ADVANCE)):
		result.error = SalaryTypes.ClaimError.PERK_REQUIRED
		result.pending_after = int(gs.call("get_pending_salary"))
		result.money_after = int(gs.call("get_money"))
		return result
	var period: int = int(gs.call("get_salary_period_index"))
	var used: int = int(gs.call("get_salary_advance_used_period"))
	if used == period:
		result.error = SalaryTypes.ClaimError.ADVANCE_ALREADY_USED
		result.pending_after = int(gs.call("get_pending_salary"))
		result.money_after = int(gs.call("get_money"))
		return result
	var pending_before: int = int(gs.call("get_pending_salary"))
	if pending_before <= 0:
		result.error = SalaryTypes.ClaimError.NO_PENDING
		result.pending_after = 0
		result.money_after = int(gs.call("get_money"))
		return result
	_claim_busy = true
	var amount: int = int(gs.call("take_all_pending_salary"))
	gs.call("add_money", amount)
	gs.call("set_salary_advance_used_period", period)
	result.ok = true
	result.error = SalaryTypes.ClaimError.OK
	result.amount = amount
	result.period_index = period
	result.pending_after = int(gs.call("get_pending_salary"))
	result.money_after = int(gs.call("get_money"))
	salary_pending_changed.emit(result.pending_after)
	salary_claimed.emit(amount, SalaryTypes.ClaimMethod.SALARY_ADVANCE)
	_claim_busy = false
	return result


func _connect_signals() -> void:
	if _signals_connected:
		return
	var day: Node = get_node_or_null("/root/GameDay")
	if day != null and day.has_signal("day_advanced"):
		if not day.is_connected("day_advanced", _on_day_advanced):
			day.connect("day_advanced", _on_day_advanced)
	var story: Node = get_node_or_null("/root/Story")
	if story != null and story.has_signal("feature_unlocked"):
		if not story.is_connected("feature_unlocked", _on_feature_unlocked):
			story.connect("feature_unlocked", _on_feature_unlocked)
	var gs: Node = get_node_or_null("/root/GameState")
	if gs != null:
		if gs.has_signal("authority_changed") and not gs.is_connected("authority_changed", _on_authority_changed):
			gs.connect("authority_changed", _on_authority_changed)
		if gs.has_signal("state_reset") and not gs.is_connected("state_reset", _on_state_reset):
			gs.connect("state_reset", _on_state_reset)
	_signals_connected = true


func _on_day_advanced(_new_day: int) -> void:
	if not is_salary_unlocked():
		return
	_open_salary_period()


func _on_feature_unlocked(feature: StoryTypes.StoryFeature) -> void:
	if feature != StoryTypes.StoryFeature.SALARY_MINE:
		return
	_ensure_initial_period()


func _on_authority_changed(_new_value: int, _delta: int) -> void:
	var new_level: int = get_salary_level()
	if new_level == _last_known_level:
		return
	var old_level: int = _last_known_level
	_last_known_level = new_level
	salary_level_changed.emit(new_level, old_level)


func _on_state_reset() -> void:
	_claim_busy = false
	_last_known_level = get_salary_level()


func _ensure_initial_period() -> void:
	if not is_salary_unlocked():
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if bool(gs.call("is_salary_initialized")):
		return
	_open_salary_period()


func _open_salary_period() -> void:
	if not is_salary_unlocked():
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if not bool(gs.call("is_salary_initialized")):
		gs.call("mark_salary_initialized")
	var period: int = int(gs.call("advance_salary_period_index"))
	var authority: int = int(gs.call("get_authority"))
	var level: int = get_salary_level(authority)
	var gross: int = get_gross_salary(authority)
	var passive_amount: int = 0
	if is_passive_enabled():
		passive_amount = int(floor(float(gross) * 0.25))
	var manual_amount: int = gross - passive_amount
	if passive_amount > 0:
		gs.call("add_money", passive_amount)
		passive_salary_paid.emit(passive_amount)
	if manual_amount > 0:
		gs.call("add_pending_salary", manual_amount)
	var pending: int = int(gs.call("get_pending_salary"))
	salary_pending_changed.emit(pending)
	var status: SalaryStatus = SalaryStatus.new()
	status.unlocked = true
	status.authority = authority
	status.salary_level = level
	status.gross_per_period = gross
	status.period_index = period
	status.pending_salary = pending
	status.manual_cycle_seen = bool(gs.call("has_seen_manual_salary_cycle"))
	status.passive_enabled = is_passive_enabled()
	if status.passive_enabled:
		status.passive_per_period = passive_amount
	status.salary_advance_owned = bool(gs.call("has_perk", PerkIds.CAPITAL_SALARY_ADVANCE))
	status.salary_advance_used_this_period = (
		int(gs.call("get_salary_advance_used_period")) == period
	)
	status.salary_advance_available = is_salary_advance_available()
	salary_period_opened.emit(status)
