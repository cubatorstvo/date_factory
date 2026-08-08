class_name CloneIncrementalTypes
extends RefCounted
## Shared Clone Incremental enums / constants (MODULE 18).


enum UpgradeType {
	PRODUCTION_SPEED = 0,
	WORK_EFFICIENCY = 1,
	DATING_EFFICIENCY = 2,
}


enum UpgradePurchaseError {
	OK = 0,
	LOCKED = 1,
	MAX_LEVEL = 2,
	NOT_ENOUGH_MONEY = 3,
	INVALID_UPGRADE = 4,
}


const MAX_LEVEL: int = 5
const BASE_PRODUCTION_INTERVAL: float = 30.0
const PRODUCTION_INTERVAL_STEP: float = 5.0
const BASE_MONEY_PER_CLONE: float = 20.0
const MONEY_PER_LEVEL: float = 10.0
const BASE_DATES_PER_CLONE: float = 0.50
const DATES_PER_LEVEL: float = 0.25
const UPGRADE_COST_BASE: int = 30
const UPGRADE_COST_FACTOR: int = 3

const TERMINAL_PROMPT: String = "Терминал клонов"
const TERMINAL_LOCKED_PROMPT: String = "Терминал ожидает первого клона"
const TERMINAL_TITLE: String = "КЛОН-ФАБРИКА"
const UPGRADE_PRODUCTION_TITLE: String = "ЛИНИЯ КОПИРОВАНИЯ"
const UPGRADE_WORK_TITLE: String = "РАБОЧАЯ МЕТОДИКА"
const UPGRADE_DATING_TITLE: String = "РОМАНТИЧЕСКИЙ КОНВЕЙЕР"


static func production_interval(level: int) -> float:
	var clamped: int = clampi(level, 0, MAX_LEVEL)
	return BASE_PRODUCTION_INTERVAL - PRODUCTION_INTERVAL_STEP * float(clamped)


static func money_per_minute_per_clone(work_level: int) -> float:
	var clamped: int = clampi(work_level, 0, MAX_LEVEL)
	return BASE_MONEY_PER_CLONE + MONEY_PER_LEVEL * float(clamped)


static func dates_per_minute_per_clone(dating_level: int) -> float:
	var clamped: int = clampi(dating_level, 0, MAX_LEVEL)
	return BASE_DATES_PER_CLONE + DATES_PER_LEVEL * float(clamped)


static func upgrade_cost(level: int) -> int:
	if level < 0 or level >= MAX_LEVEL:
		return -1
	return UPGRADE_COST_BASE * int(pow(float(UPGRADE_COST_FACTOR), float(level)))


static func format_money_rate(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.2f" % value


static func format_date_rate(value: float) -> String:
	return "%.2f" % value
