class_name DateSchedule
extends RefCounted
## Scheduled dates, home table prep, punctuality and reminders.

const GRACE_EARLY_MIN: int = 5
const GRACE_LATE_MIN: int = 5
const WAIT_LEAVE_MIN: int = 30
const REMIND_30: int = 30
const REMIND_5: int = 5

var scheduled: Dictionary = {} ## active booking or {}
var homeware_level: int = 1
var table: Dictionary = {
	"food_id": "",
	"food_tier": 0,
	"drink_id": "",
	"drink_tier": 0,
	"ready": false,
}
var girl_at_door: bool = false
var girl_arrived: bool = false
var player_seated: bool = false
var date_started_abs: int = -1
var punctuality_score: float = 0.0
var punctuality_label: String = ""
var gift_given_id: String = ""
var awaiting_finish: bool = false
var _reminded_30: bool = false
var _reminded_5: bool = false
var _no_show_fired: bool = false


func reset() -> void:
	scheduled.clear()
	homeware_level = 1
	table = {"food_id": "", "food_tier": 0, "drink_id": "", "drink_tier": 0, "ready": false}
	girl_at_door = false
	girl_arrived = false
	player_seated = false
	date_started_abs = -1
	punctuality_score = 0.0
	punctuality_label = ""
	gift_given_id = ""
	awaiting_finish = false
	_reminded_30 = false
	_reminded_5 = false
	_no_show_fired = false


func has_booking() -> bool:
	return not scheduled.is_empty()


func place_id() -> String:
	return str(scheduled.get("place_id", ""))


func target_id() -> String:
	return str(scheduled.get("target_id", ""))


func is_home() -> bool:
	return place_id() == "home"


func is_restaurant() -> bool:
	return place_id() == "restaurant"


func book(target: String, place: String, day: int, minutes: int, unique: bool = true) -> bool:
	if has_booking():
		EventBus.toast("Свидание уже назначено. Сначала отмени текущее.", &"warn")
		return false
	if Game.girls.is_claimed(StringName(target)):
		EventBus.toast("Она уже твоя — свидания не нужны", &"info")
		return false
	var place_def: Dictionary = DatePlaces.place(place)
	if place_def.is_empty():
		EventBus.toast("Неизвестное место", &"warn")
		return false
	var cost: float = float(place_def.get("cost", 0))
	if place == "restaurant" and cost > 0.0:
		# Charge on start, not booking — just check affordability soft-warn.
		if Game.economy.get_value(&"money") < cost:
			EventBus.toast("На ресторан может не хватить денег (нужно ~%.0f$)" % cost, &"info")
	var outfit: String = str(Game.inventory.equipped_outfit)
	scheduled = {
		"target_id": target,
		"unique": unique,
		"place_id": place,
		"venue_id": str(place_def.get("venue_id", "kitchen_table")),
		"day": day,
		"minutes": minutes,
		"outfit_id": outfit,
		"gift_id": "",
		"cost": cost,
		"requires_prep": bool(place_def.get("requires_prep", false)),
	}
	_reminded_30 = false
	_reminded_5 = false
	_no_show_fired = false
	girl_at_door = false
	girl_arrived = false
	player_seated = false
	date_started_abs = -1
	punctuality_score = 0.0
	punctuality_label = ""
	gift_given_id = ""
	awaiting_finish = false
	if place == "home":
		_reset_table_keep_ware()
	EventBus.date_scheduled.emit(scheduled.duplicate(true))
	EventBus.toast("Свидание назначено: %s · %s" % [
		str(place_def.get("name", place)),
		Game.time.slot_label(day, minutes) if Game.time != null else "%d:%02d" % [minutes / 60, minutes % 60],
	], &"ok")
	return true


func cancel(reason: String = "cancelled") -> void:
	if not has_booking():
		return
	var payload: Dictionary = scheduled.duplicate(true)
	payload["reason"] = reason
	scheduled.clear()
	girl_at_door = false
	girl_arrived = false
	player_seated = false
	awaiting_finish = false
	EventBus.date_cancelled.emit(payload)
	EventBus.toast("Свидание отменено", &"info")


func clear_after_start() -> void:
	## Booking consumed when date UI opens; keep punctuality fields.
	scheduled.clear()
	girl_at_door = false


func minutes_until_date() -> int:
	if not has_booking() or Game.time == null:
		return 99999
	return Game.time.minutes_until(int(scheduled.get("day", 1)), int(scheduled.get("minutes", 0)))


func tick_reminders() -> void:
	if not has_booking() or Game.time == null:
		return
	if not Game.run_started:
		return
	if not Game.dating.active_manual.is_empty():
		return
	var until: int = minutes_until_date()
	if until <= REMIND_30 and until > REMIND_5 and not _reminded_30:
		_reminded_30 = true
		EventBus.date_reminder.emit({"kind": "t30", "until": until, "scheduled": scheduled.duplicate(true)})
		EventBus.toast("Через 30 минут свидание", &"info")
	elif until <= REMIND_5 and until > -WAIT_LEAVE_MIN and not _reminded_5:
		_reminded_5 = true
		EventBus.date_reminder.emit({"kind": "t5", "until": until, "scheduled": scheduled.duplicate(true)})
		EventBus.toast("Свидание через 5 минут!", &"warn")
	if until < -WAIT_LEAVE_MIN and not _no_show_fired:
		_no_show_fired = true
		EventBus.toast("Она ушла — ты опоздал больше чем на 30 минут", &"warn")
		cancel("no_show")
		Game.economy.add(&"scandal", 1.5, &"date_noshow")


func table_state() -> Dictionary:
	var st: Dictionary = table.duplicate(true)
	st["homeware_level"] = homeware_level
	st["homeware_label"] = DatePlaces.homeware_label(homeware_level)
	st["ready"] = is_table_ready()
	return st


func is_table_ready() -> bool:
	return int(table.get("food_tier", 0)) > 0 and int(table.get("drink_tier", 0)) > 0


func _reset_table_keep_ware() -> void:
	table["food_id"] = ""
	table["food_tier"] = 0
	table["drink_id"] = ""
	table["drink_tier"] = 0
	table["ready"] = false
	EventBus.table_prep_changed.emit(table_state())


func set_homeware_level(level: int) -> void:
	homeware_level = clampi(level, 1, 4)
	EventBus.table_prep_changed.emit(table_state())
	EventBus.toast("Посуда: %s" % DatePlaces.homeware_label(homeware_level), &"info")


func upgrade_homeware() -> bool:
	if homeware_level >= 4:
		EventBus.toast("Посуда уже лучшая", &"info")
		return false
	var costs := [0, 25, 60, 120]
	var next := homeware_level + 1
	var price: float = float(costs[mini(next - 1, costs.size() - 1)])
	if price > 0.0 and not Game.economy.try_spend({"money": price}, &"homeware"):
		EventBus.toast("Не хватает денег на посуду", &"warn")
		return false
	homeware_level = next
	EventBus.table_prep_changed.emit(table_state())
	EventBus.toast("Посуда улучшена: %s" % DatePlaces.homeware_label(homeware_level), &"ok")
	return true


func place_food(food_id: String) -> bool:
	var opt: Dictionary = {}
	for f in DatePlaces.food_options():
		if str(f.get("id", "")) == food_id:
			opt = f
			break
	if opt.is_empty():
		return false
	table["food_id"] = food_id
	table["food_tier"] = int(opt.get("tier", 1))
	table["ready"] = is_table_ready()
	EventBus.table_prep_changed.emit(table_state())
	EventBus.toast("На стол: %s" % str(opt.get("name", food_id)), &"ok")
	return true


func place_drink(drink_id: String) -> bool:
	var opt: Dictionary = {}
	for d in DatePlaces.drink_options():
		if str(d.get("id", "")) == drink_id:
			opt = d
			break
	if opt.is_empty():
		return false
	table["drink_id"] = drink_id
	table["drink_tier"] = int(opt.get("tier", 1))
	table["ready"] = is_table_ready()
	EventBus.table_prep_changed.emit(table_state())
	EventBus.toast("На стол: %s" % str(opt.get("name", drink_id)), &"ok")
	return true


func can_start_home() -> bool:
	if not has_booking() or not is_home():
		return false
	if not is_table_ready():
		EventBus.toast("Положи на стол еду и напиток", &"warn")
		return false
	if not girl_arrived:
		if girl_at_door:
			EventBus.toast("Сначала открой дверь — она ждёт", &"warn")
		elif minutes_until_date() > GRACE_EARLY_MIN:
			EventBus.toast("Ещё рано — она придёт ближе к времени", &"info")
		else:
			EventBus.toast("Подожди звонка в дверь", &"info")
		return false
	return true


func can_start_restaurant() -> bool:
	if not has_booking() or not is_restaurant():
		return false
	var until: int = minutes_until_date()
	if until > GRACE_EARLY_MIN:
		EventBus.toast("Ещё рано садиться — подожди ближе к времени", &"info")
		return false
	if until < -WAIT_LEAVE_MIN:
		return false
	return true


func update_arrival_flags() -> void:
	if not has_booking() or Game.time == null:
		return
	var until: int = minutes_until_date()
	if is_home():
		if until <= 0 and not girl_arrived and not girl_at_door:
			girl_at_door = true
			EventBus.toast("Звонок в дверь — она пришла!", &"ok")
			EventBus.notify.emit("DOORBELL", &"date")
	elif is_restaurant():
		if until <= 0 and not girl_arrived:
			girl_arrived = true


func answer_doorbell() -> bool:
	if not girl_at_door:
		EventBus.toast("Никого у двери", &"info")
		return false
	girl_at_door = false
	girl_arrived = true
	EventBus.toast("Ты открыл дверь — она вошла", &"ok")
	return true


func compute_punctuality(player_ready_abs: int) -> void:
	if Game.time == null or not has_booking():
		punctuality_score = 0.0
		punctuality_label = "вовремя"
		return
	var target_abs: int = (int(scheduled.get("day", 1)) - 1) * TimeAPI.MINUTES_PER_DAY + int(scheduled.get("minutes", 0))
	var delta: int = player_ready_abs - target_abs
	if delta < -GRACE_EARLY_MIN:
		punctuality_score = 0.4
		punctuality_label = "рано"
	elif delta <= GRACE_LATE_MIN:
		punctuality_score = 1.0
		punctuality_label = "вовремя"
	elif delta <= 15:
		punctuality_score = 0.2
		punctuality_label = "небольшой опоздание"
	elif delta <= WAIT_LEAVE_MIN:
		punctuality_score = -0.5
		punctuality_label = "опоздание"
	else:
		punctuality_score = -1.2
		punctuality_label = "сильное опоздание"
	date_started_abs = player_ready_abs


func build_prep_from_booking() -> Dictionary:
	var place: String = place_id()
	var place_def: Dictionary = DatePlaces.place(place)
	var venue_id: String = str(scheduled.get("venue_id", place_def.get("venue_id", "kitchen_table")))
	var quality: float = float(place_def.get("base_quality", 1.0))
	if place == "home":
		quality = DatePlaces.home_quality(homeware_level, int(table.get("food_tier", 0)), int(table.get("drink_tier", 0)))
	return {
		"gift_id": gift_given_id,
		"venue_id": venue_id,
		"outfit_id": str(scheduled.get("outfit_id", Game.inventory.equipped_outfit)),
		"extra": "",
		"place_id": place,
		"place_quality": quality,
		"homeware_level": homeware_level,
		"food_id": str(table.get("food_id", "")),
		"drink_id": str(table.get("drink_id", "")),
		"punctuality_score": punctuality_score,
		"punctuality_label": punctuality_label,
		"scheduled_day": int(scheduled.get("day", 1)),
		"scheduled_minutes": int(scheduled.get("minutes", 0)),
	}


func hud_line() -> String:
	if not has_booking() or Game.time == null:
		return ""
	var until: int = minutes_until_date()
	var place_def: Dictionary = DatePlaces.place(place_id())
	var name: String = str(place_def.get("name", place_id()))
	if until > 0:
		return "До свидания (%s): %d мин" % [name, until]
	if until >= -WAIT_LEAVE_MIN:
		return "Свидание сейчас (%s) · опоздание %d мин" % [name, -until] if until < 0 else "Свидание сейчас (%s)" % name
	return ""


func to_dict() -> Dictionary:
	return {
		"scheduled": scheduled.duplicate(true),
		"homeware_level": homeware_level,
		"table": table.duplicate(true),
		"gift_given_id": gift_given_id,
	}


func from_dict(data: Dictionary) -> void:
	scheduled = data.get("scheduled", {})
	homeware_level = int(data.get("homeware_level", 1))
	table = data.get("table", table)
	gift_given_id = str(data.get("gift_given_id", ""))
	girl_at_door = false
	girl_arrived = false
	player_seated = false
	awaiting_finish = false
	_reminded_30 = false
	_reminded_5 = false
	_no_show_fired = false
