class_name DateSchedule
extends RefCounted
## Scheduled dates, home table prep, punctuality and reminders.

## Window: girl may arrive when until <= ARRIVE_EARLY_MIN (minutes_until: +future, -past).
const ARRIVE_EARLY_MIN: int = 10
## 0..NEUTRAL_LATE_MIN late counts as on-time (until in [-NEUTRAL_LATE_MIN, 0]).
const NEUTRAL_LATE_MIN: int = 10
const WAIT_LEAVE_MIN: int = 30
const REMIND_30: int = 30
const REMIND_5: int = 5
## Legacy aliases (restaurant / older callers).
const GRACE_EARLY_MIN: int = ARRIVE_EARLY_MIN
const GRACE_LATE_MIN: int = NEUTRAL_LATE_MIN

var scheduled: Dictionary = {} ## active booking or {}
## Shared place/time occupancy (player + clone leads). Key: place|day|minutes
var place_occupancy: Dictionary = {}
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
var late_soft_hit: bool = false ## true when started 10–30 min late (bond soft hit applied at start)
var gift_given_id: String = ""
var awaiting_finish: bool = false
var _reminded_30: bool = false
var _reminded_5: bool = false
var _no_show_fired: bool = false


func reset() -> void:
	scheduled.clear()
	place_occupancy.clear()
	homeware_level = 1
	table = {"food_id": "", "food_tier": 0, "drink_id": "", "drink_tier": 0, "ready": false}
	girl_at_door = false
	girl_arrived = false
	player_seated = false
	date_started_abs = -1
	punctuality_score = 0.0
	punctuality_label = ""
	late_soft_hit = false
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
	var p := place_id()
	return p == "home" or p.begins_with("apt_")


func is_cafe() -> bool:
	return place_id() == "cafe"


func is_restaurant() -> bool:
	return place_id() == "restaurant"


func is_park() -> bool:
	return place_id() == "park"


func is_cinema() -> bool:
	return place_id() == "cinema"


func is_arcade() -> bool:
	return place_id() == "arcade"


func is_no_prep() -> bool:
	## Cafe / park / restaurant / cinema / arcade: sit-start, no home table prep.
	return is_cafe() or is_park() or is_restaurant() or is_cinema() or is_arcade()


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
	if place.begins_with("apt_") and Game.city != null and Game.city.has_method("is_apartment_unlocked"):
		if not bool(Game.city.call("is_apartment_unlocked", StringName(place))):
			EventBus.toast("Эта квартира ещё не открыта", &"warn")
			return false
	var conflict: Dictionary = slot_conflict(place, day, minutes, "player")
	if not conflict.is_empty():
		EventBus.toast("Слот занят (%s · lead=%s) — конфликт вместимости" % [
			str(conflict.get("place", place)),
			str(conflict.get("lead", "?")),
		], &"warn")
		return false
	var cost: float = float(place_def.get("cost", 0))
	if place == "restaurant" and not DatePlaces.is_restaurant_bookable():
		EventBus.toast("Ресторан ещё закрыт — откроется с парком", &"warn")
		return false
	if place == "park" and not DatePlaces.is_park_bookable():
		EventBus.toast("Парк ещё закрыт", &"warn")
		return false
	if place == "cinema" and not DatePlaces.is_cinema_bookable():
		EventBus.toast("Кино ещё закрыто", &"warn")
		return false
	if place == "arcade" and not DatePlaces.is_arcade_bookable():
		EventBus.toast("Аркада ещё закрыта", &"warn")
		return false
	if (place == "restaurant" or place == "cafe" or place == "cinema" or place == "arcade") and cost > 0.0:
		# Charge on start, not booking — just check affordability soft-warn.
		if Game.economy.get_value(&"money") < cost:
			EventBus.toast("На это место может не хватить денег (нужно ~%.0f$)" % cost, &"info")
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
	late_soft_hit = false
	gift_given_id = ""
	awaiting_finish = false
	if place == "home" or place.begins_with("apt_"):
		_reset_table_keep_ware()
	overwrite_occupancy(place, day, minutes, "player", target)
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
	release_occupancy(str(scheduled.get("place_id", "")), int(scheduled.get("day", 1)), int(scheduled.get("minutes", 0)), "player")
	scheduled.clear()
	girl_at_door = false
	girl_arrived = false
	player_seated = false
	awaiting_finish = false
	EventBus.date_cancelled.emit(payload)
	EventBus.toast("Свидание отменено", &"info")


func clear_after_start() -> void:
	## Booking consumed when date UI opens; keep punctuality fields.
	if has_booking():
		release_occupancy(place_id(), int(scheduled.get("day", 1)), int(scheduled.get("minutes", 0)), "player")
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
		fire_no_show()


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
	var until: int = minutes_until_date()
	if until < -WAIT_LEAVE_MIN:
		return false
	if until > ARRIVE_EARLY_MIN:
		EventBus.toast("Ещё рано — сядь за стол и подожди ближе к времени", &"info")
		return false
	if not player_seated:
		EventBus.toast("Сядь за стол — она придёт сама", &"info")
		return false
	return true


func can_start_restaurant() -> bool:
	## Legacy name: any no-prep sit venue (cafe / restaurant).
	if not has_booking() or not is_no_prep():
		return false
	var until: int = minutes_until_date()
	if until > ARRIVE_EARLY_MIN:
		EventBus.toast("Ещё рано садиться — подожди ближе к времени", &"info")
		return false
	if until < -WAIT_LEAVE_MIN:
		return false
	return true


func should_auto_arrive_home() -> bool:
	## Girl arrives only when seated + table ready + inside punctuality window.
	if not has_booking() or not is_home():
		return false
	if girl_arrived:
		return false
	if not is_table_ready() or not player_seated:
		return false
	var until: int = minutes_until_date()
	return until <= ARRIVE_EARLY_MIN and until >= -WAIT_LEAVE_MIN


func update_arrival_flags() -> void:
	if not has_booking() or Game.time == null:
		return
	var until: int = minutes_until_date()
	if until < -WAIT_LEAVE_MIN and not _no_show_fired:
		fire_no_show()
		return
	if is_home():
		girl_at_door = false
		if should_auto_arrive_home():
			girl_arrived = true
	elif is_no_prep():
		if until <= ARRIVE_EARLY_MIN and until >= -WAIT_LEAVE_MIN and player_seated:
			girl_arrived = true


func answer_doorbell() -> bool:
	## Doorbell removed for home dates — keep stub so old interacts do nothing harmful.
	EventBus.toast("Дверь не нужна — сядь за стол, она придёт сама", &"info")
	girl_at_door = false
	return false


func fire_no_show() -> void:
	if _no_show_fired or not has_booking():
		return
	_no_show_fired = true
	var tid := StringName(target_id())
	EventBus.toast("Она ушла — ты опоздал больше чем на 30 минут", &"warn")
	var bond_wrong: float = float(ContentDB.balance.get("bond_wrong", -12.0))
	if tid != &"" and Game.girls != null:
		Game.girls.add_bond(tid, bond_wrong * 3.0)
	Game.economy.add(&"scandal", 2.5, &"date_noshow")
	cancel("no_show")


func _target_likes_punctuality() -> bool:
	var tid := StringName(target_id())
	if tid == &"" or Game.girls == null:
		return false
	var primaries: Array = Game.girls.girl_primary_traits(tid)
	if primaries.has("punctual"):
		return true
	var traits: Array = Game.girls.girl_traits(tid)
	if traits.has("time") or traits.has("punctual"):
		return true
	var likes: Array = Game.girls.get_entry(tid).get("likes", [])
	return likes.has("order")


func compute_punctuality(player_ready_abs: int) -> void:
	late_soft_hit = false
	if Game.time == null or not has_booking():
		punctuality_score = 1.0
		punctuality_label = "вовремя"
		return
	var target_abs: int = (int(scheduled.get("day", 1)) - 1) * TimeAPI.MINUTES_PER_DAY + int(scheduled.get("minutes", 0))
	var delta: int = player_ready_abs - target_abs
	# delta = ready - scheduled (neg = early)
	if delta < 0:
		# Early (including beyond ARRIVE_EARLY_MIN if somehow started early).
		var early_t: float = clampf(float(-delta) / float(ARRIVE_EARLY_MIN), 0.0, 1.0)
		if _target_likes_punctuality():
			punctuality_score = lerpf(1.0, 1.2, early_t)
		else:
			punctuality_score = lerpf(0.5, 0.7, early_t)
		punctuality_label = "рано"
	elif delta >= 0 and delta <= NEUTRAL_LATE_MIN:
		punctuality_score = 1.0
		punctuality_label = "вовремя"
	elif delta > NEUTRAL_LATE_MIN and delta <= WAIT_LEAVE_MIN:
		var t: float = clampf(float(delta - NEUTRAL_LATE_MIN) / float(WAIT_LEAVE_MIN - NEUTRAL_LATE_MIN), 0.0, 1.0)
		punctuality_score = lerpf(-0.6, -1.0, t)
		punctuality_label = "опоздание"
		late_soft_hit = true
	else:
		# Beyond wait window (should usually cancel before start).
		punctuality_score = -1.2
		punctuality_label = "опоздание"
		late_soft_hit = true
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
		"late_soft_hit": late_soft_hit,
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


static func is_shared_capacity_place(place: String) -> bool:
	return place in ["home", "cafe", "park", "restaurant"] or place.begins_with("apt_")


static func venue_to_place(venue_id: String) -> String:
	match venue_id:
		"kitchen_table":
			return "home"
		"cheap_cafe":
			return "cafe"
		"park":
			return "park"
		"restaurant", "luxury_hall":
			return "restaurant"
		_:
			if venue_id.begins_with("apt_"):
				return venue_id
			return ""


static func occupancy_key(place: String, day: int, minutes: int) -> String:
	return "%s|%d|%d" % [place, day, minutes]


func slot_conflict(place: String, day: int, minutes: int, exclude_lead: String = "") -> Dictionary:
	## Returns first conflicting occupancy entry, or {}.
	if not is_shared_capacity_place(place):
		return {}
	var key := occupancy_key(place, day, minutes)
	if place_occupancy.has(key):
		var e: Dictionary = place_occupancy[key]
		if exclude_lead == "" or str(e.get("lead", "")) != exclude_lead:
			return e.duplicate(true)
	# Active clone autos at this place (coarse "now" bucket minutes=-1) conflict with any booking same day.
	var live_key := occupancy_key(place, day, -1)
	if place_occupancy.has(live_key):
		var live: Dictionary = place_occupancy[live_key]
		if exclude_lead == "" or str(live.get("lead", "")) != exclude_lead:
			return live.duplicate(true)
	return {}


func overwrite_occupancy(place: String, day: int, minutes: int, lead: String, girl_id: String) -> void:
	if not is_shared_capacity_place(place):
		return
	var key := occupancy_key(place, day, minutes)
	place_occupancy[key] = {
		"place": place,
		"day": day,
		"minutes": minutes,
		"lead": lead,
		"girl_id": girl_id,
	}


func release_occupancy(place: String, day: int, minutes: int, lead: String = "") -> void:
	var key := occupancy_key(place, day, minutes)
	if not place_occupancy.has(key):
		return
	if lead != "" and str(place_occupancy[key].get("lead", "")) != lead:
		return
	place_occupancy.erase(key)


func occupancy_entries() -> Array:
	var out: Array = []
	for k in place_occupancy.keys():
		var e: Dictionary = place_occupancy[k]
		out.append(e.duplicate(true))
	return out


func to_dict() -> Dictionary:
	return {
		"scheduled": scheduled.duplicate(true),
		"place_occupancy": place_occupancy.duplicate(true),
		"homeware_level": homeware_level,
		"table": table.duplicate(true),
		"gift_given_id": gift_given_id,
	}


func from_dict(data: Dictionary) -> void:
	scheduled = data.get("scheduled", {})
	place_occupancy = data.get("place_occupancy", {})
	if place_occupancy == null:
		place_occupancy = {}
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
