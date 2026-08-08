class_name LateGameTypes
extends RefCounted
## Shared Late Game Expansion enums / constants (MODULE 20).


enum GlobalUpgradeType {
	GLOBAL_PRODUCTION = 0,
	GLOBAL_WORK = 1,
	GLOBAL_DATING = 2,
}


enum GlobalUpgradePurchaseError {
	OK = 0,
	LOCKED = 1,
	MAX_LEVEL = 2,
	NOT_ENOUGH_MONEY = 3,
	INVALID_UPGRADE = 4,
}


enum OptionalEvent {
	CUSTOMS = 0,
	WORLD_ROUTE = 1,
	LAST_CONTINENT = 2,
}


const MAX_LEVEL: int = 3
const WORLD_REACH_MIN: int = 0
const WORLD_REACH_MAX: int = 100
const REACH_PER_LATE_XP: int = 2
const OPTIONAL_EVENT_REACH: int = 10
const UPGRADE_COST_BASE: int = 1000
const UPGRADE_COST_FACTOR: int = 5
const MIN_EFFECTIVE_PRODUCTION_INTERVAL: float = 0.5

const FLAG_EVENT_CUSTOMS: StringName = &"late_event_customs_stamp"
const FLAG_EVENT_WORLD_ROUTE: StringName = &"late_event_world_route"
const FLAG_EVENT_LAST_CONTINENT: StringName = &"late_event_last_continent"

const EVENT_CUSTOMS_MIN_REACH: int = 20
const EVENT_WORLD_ROUTE_MIN_REACH: int = 50
const EVENT_LAST_CONTINENT_MIN_REACH: int = 80

const TERMINAL_PROMPT: String = "Глобальный терминал"
const TERMINAL_LOCKED_PROMPT: String = "Глобальный терминал недоступен"
const TERMINAL_TITLE: String = "ГЛОБАЛЬНОЕ РАСШИРЕНИЕ"

const UPGRADE_PRODUCTION_TITLE: String = "ГЛОБАЛЬНАЯ ЛИНИЯ КЛОНИРОВАНИЯ"
const UPGRADE_WORK_TITLE: String = "ГОСУДАРСТВЕННЫЕ КОНТРАКТЫ"
const UPGRADE_DATING_TITLE: String = "МЕЖДУНАРОДНАЯ СЕТЬ СВИДАНИЙ"

const EVENT_CUSTOMS_PROMPT: String = "Поставить экспортную печать"
const EVENT_WORLD_ROUTE_PROMPT: String = "Перевести маршрут в режим «МИР»"
const EVENT_LAST_CONTINENT_PROMPT: String = "Отметить последний свободный континент"


static func multiplier_for_level(level: int) -> float:
	var clamped: int = clampi(level, 0, MAX_LEVEL)
	return pow(2.0, float(clamped))


static func upgrade_cost(level: int) -> int:
	if level < 0 or level >= MAX_LEVEL:
		return -1
	return UPGRADE_COST_BASE * int(pow(float(UPGRADE_COST_FACTOR), float(level)))


static func event_flag(event: int) -> StringName:
	match event:
		int(OptionalEvent.CUSTOMS):
			return FLAG_EVENT_CUSTOMS
		int(OptionalEvent.WORLD_ROUTE):
			return FLAG_EVENT_WORLD_ROUTE
		int(OptionalEvent.LAST_CONTINENT):
			return FLAG_EVENT_LAST_CONTINENT
	return &""


static func event_min_reach(event: int) -> int:
	match event:
		int(OptionalEvent.CUSTOMS):
			return EVENT_CUSTOMS_MIN_REACH
		int(OptionalEvent.WORLD_ROUTE):
			return EVENT_WORLD_ROUTE_MIN_REACH
		int(OptionalEvent.LAST_CONTINENT):
			return EVENT_LAST_CONTINENT_MIN_REACH
	return 999


static func event_prompt(event: int) -> String:
	match event:
		int(OptionalEvent.CUSTOMS):
			return EVENT_CUSTOMS_PROMPT
		int(OptionalEvent.WORLD_ROUTE):
			return EVENT_WORLD_ROUTE_PROMPT
		int(OptionalEvent.LAST_CONTINENT):
			return EVENT_LAST_CONTINENT_PROMPT
	return ""


static func format_multiplier(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.2f" % value
