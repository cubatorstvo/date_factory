extends Node

signal time_advanced(delta_minutes: int, previous_game_time: int, current_game_time: int)

const MINUTES_PER_HOUR: int = 60
const MINUTES_PER_DAY: int = 1440
const MORNING_HOUR: int = 8

var real_time_progression_enabled: bool = false:
	set(value):
		real_time_progression_enabled = value
		set_process(value)
		if not value:
			_real_time_remainder = 0.0

var game_minutes_per_real_second: float = 1.0

var _real_time_remainder: float = 0.0


func _ready() -> void:
	set_process(real_time_progression_enabled)


func _process(delta: float) -> void:
	_accumulate_real_time(delta)


func advance_time(delta_minutes: int) -> void:
	if delta_minutes <= 0:
		return
	var flow: FlowState = _flow()
	if flow == null:
		return
	var previous_game_time: int = flow.game_time_minutes
	flow.game_time_minutes = previous_game_time + delta_minutes
	time_advanced.emit(delta_minutes, previous_game_time, flow.game_time_minutes)


func apply_action(action: GameAction) -> void:
	if action == null:
		return
	advance_time(action.time_cost_minutes)


func get_game_time_minutes() -> int:
	var flow: FlowState = _flow()
	if flow == null:
		return 0
	return flow.game_time_minutes


func get_calendar_day_index() -> int:
	return int(get_game_time_minutes() / MINUTES_PER_DAY)


func get_day() -> int:
	return get_calendar_day_index() + 1


func get_hour() -> int:
	return int(_minute_of_day() / MINUTES_PER_HOUR)


func get_minute() -> int:
	return _minute_of_day() % MINUTES_PER_HOUR


func days_to_minutes(days: int) -> int:
	return days * MINUTES_PER_DAY


func hours_to_minutes(hours: int) -> int:
	return hours * MINUTES_PER_HOUR

func format_duration(minutes: int) -> String:
	var safe_minutes: int = maxi(0, minutes)
	var days: int = int(safe_minutes / MINUTES_PER_DAY)
	var hours: int = int((safe_minutes % MINUTES_PER_DAY) / MINUTES_PER_HOUR)
	if days > 0 and hours > 0:
		return "%d д. %d ч." % [days, hours]
	if days > 0:
		return "%d д." % days
	if hours > 0:
		return "%d ч." % hours
	return "1 ч."


func minutes_until_next_morning(game_time_minutes: int) -> int:
	var target_minute_of_day: int = MORNING_HOUR * MINUTES_PER_HOUR
	var minute_of_day: int = posmod(game_time_minutes, MINUTES_PER_DAY)
	if minute_of_day < target_minute_of_day:
		return target_minute_of_day - minute_of_day
	return MINUTES_PER_DAY - minute_of_day + target_minute_of_day


func on_playthrough_reset() -> void:
	_real_time_remainder = 0.0


func _accumulate_real_time(delta_seconds: float) -> void:
	if not real_time_progression_enabled:
		return
	_real_time_remainder += delta_seconds * game_minutes_per_real_second
	var whole_minutes: int = int(_real_time_remainder)
	if whole_minutes <= 0:
		return
	_real_time_remainder -= float(whole_minutes)
	advance_time(whole_minutes)


func _minute_of_day() -> int:
	return get_game_time_minutes() % MINUTES_PER_DAY


func _flow() -> FlowState:
	var node: Node = get_node_or_null("/root/GameState")
	if not is_instance_valid(node):
		push_error("GameState autoload missing")
		return null
	var gs: Variant = node
	return gs.flow as FlowState
