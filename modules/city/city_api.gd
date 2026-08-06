class_name CityAPI
extends Node
## City roster, worthiness, talk lines, contacts bridge to GirlsAPI.

signal city_changed
signal contact_gained(girl_id: String)

const REJECT_LINES := [
	"Отвали.",
	"Я даже с тобой говорить не хочу.",
	"Фу. Держись подальше.",
	"Ты вообще кто? Неинтересно.",
	"У тебя шансов ноль. Буквально.",
	"Не сейчас. И не потом.",
	"Извини... нет, не извини. Просто нет.",
	"Я занята. Вечно.",
	"Попробуй набрать популярности, чмо.",
	"Ты пахнешь одиночеством и долгами.",
	"Мой парень — это мои стандарты. Ты мимо.",
	"Ха. Нет.",
	"Не блокируй тротуар своим существованием.",
	"Позвони, когда станешь хоть кем-то. Шутка — не звони.",
]

const ACCEPT_LINES := [
	"Ок, ты забавный. Держи номер — и не сливай первое сообщение.",
	"Хм. Набери меня вечером, разберёмся.",
	"Вот мой номер. Если напишешь «привет» три раза — я заблокирую.",
	"Записала тебя. Не будь скучным в переписке.",
	"Ладно, контакт скинула в твой «корпоративный» телефон.",
	"Ты странный... в хорошем смысле. Пиши.",
	"Номер у тебя. Свидание ещё надо заслужить.",
	"Ого, ты не совсем безнадёжен. Держи.",
]

var roster: Array = [] ## city girl profiles
var snubs: Dictionary = {} ## id -> count
var tutorial_target_id: String = ""
var outside_tip_shown: bool = false
var unlocked_districts: Array[StringName] = []
var amenity_last_use: Dictionary = {} ## action_id -> abs minutes
var fitness_progress: float = 0.0
var gym_last_day: int = -1
var hero_style: Dictionary = {} ## hair / beard / style tags for barber + display
var profile_photos: Array = [] ## captured / published photo variants
var soft_candidate_bias: float = 0.0 ## from published profile photos
var photo_last_day: int = -1
var unlocked_apartments: Array[StringName] = [] ## themed apt ids (main apartment always available)
var apartment_assignments: Dictionary = {} ## apt_id -> {girl_id, lead}


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	snubs.clear()
	tutorial_target_id = ""
	outside_tip_shown = false
	amenity_last_use.clear()
	fitness_progress = 0.0
	gym_last_day = -1
	hero_style = {"hair": "short", "beard": "clean", "style_tags": ["casual"]}
	profile_photos.clear()
	soft_candidate_bias = 0.0
	photo_last_day = -1
	unlocked_apartments.clear()
	apartment_assignments.clear()
	unlocked_districts = CityDistricts.default_unlocked()
	_build_roster()
	city_changed.emit()


func is_district_unlocked(id: StringName) -> bool:
	return unlocked_districts.has(id)


func unlock_district(id: StringName, announce: bool = true) -> void:
	if unlocked_districts.has(id):
		return
	unlocked_districts.append(id)
	if id == CityDistricts.PARK_LEISURE and Game.facility != null:
		Game.facility.set_flag("district_park_leisure", true)
		if not Game.facility.is_venue_unlocked(&"park"):
			Game.facility.unlock_venue(&"park", false)
	if id == CityDistricts.AGENCY_ROW and Game.facility != null:
		Game.facility.set_flag("district_agency_row", true)
		if not Game.facility.is_venue_unlocked(&"photo_studio"):
			Game.facility.unlock_venue(&"photo_studio", false)
	city_changed.emit()
	if announce:
		if id == CityDistricts.AGENCY_ROW:
			EventBus.toast("Район открыт: агентство / фото / барбер", &"facility")
		elif id == CityDistricts.PARK_LEISURE:
			EventBus.toast("Район открыт: парк", &"facility")
		else:
			EventBus.toast("Район открыт: %s" % str(id), &"facility")


func try_unlock_park_from_progress() -> void:
	## stage_2 expansion or park venue unlock opens the gate.
	if is_district_unlocked(CityDistricts.PARK_LEISURE):
		return
	var stage_ok := false
	if Game != null:
		var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
		stage_ok = int(order.get(str(Game.stage_id), 1)) >= 2
	var venue_ok: bool = Game.facility != null and Game.facility.is_venue_unlocked(&"park")
	if stage_ok or venue_ok:
		unlock_district(CityDistricts.PARK_LEISURE, true)


func try_unlock_agency_row_from_progress() -> void:
	## Clear hook: stage_3 expansion OR agency room unlock opens AgencyGate.
	if is_district_unlocked(CityDistricts.AGENCY_ROW):
		return
	var stage_ok := false
	if Game != null:
		var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
		stage_ok = int(order.get(str(Game.stage_id), 1)) >= 3
	var room_ok: bool = Game.facility != null and Game.facility.room_unlocked(&"agency")
	if stage_ok or room_ok:
		unlock_district(CityDistricts.AGENCY_ROW, true)


func amenity_multiplier(action_id: StringName, cooldown_min: int = 45) -> float:
	## Diminishing returns: full → half → quarter within cooldown window.
	if Game == null or Game.time == null:
		return 1.0
	var now: int = Game.time.absolute_minutes() if Game.time.has_method("absolute_minutes") else int(Game.time.get("total_minutes"))
	var last: int = int(amenity_last_use.get(str(action_id), -99999))
	var ago: int = now - last
	if ago < 0:
		return 1.0
	if ago >= cooldown_min:
		return 1.0
	if ago >= cooldown_min / 2:
		return 0.5
	return 0.25


func mark_amenity_used(action_id: StringName) -> void:
	if Game == null or Game.time == null:
		return
	var now: int = Game.time.absolute_minutes() if Game.time.has_method("absolute_minutes") else int(Game.time.get("total_minutes"))
	amenity_last_use[str(action_id)] = now


func can_use_gym_today() -> bool:
	if Game == null or Game.time == null:
		return true
	return int(Game.time.day) != gym_last_day


func gym_cooldown_hint() -> String:
	if can_use_gym_today():
		return ""
	return "Сегодня уже тренировался — приходи завтра"


func apply_gym_session(intensity: String, timing_score: float) -> Dictionary:
	## timing_score 0..1 from GymUI presses. Daily cooldown; advances game minutes.
	if not can_use_gym_today():
		EventBus.toast(gym_cooldown_hint(), &"warn")
		return {"ok": false, "reason": "cooldown"}
	var intens := intensity
	if intens != "light" and intens != "normal" and intens != "intense":
		intens = "normal"
	var base := 0.35
	var mins := 8
	match intens:
		"light":
			base = 0.25
			mins = 5
		"intense":
			base = 0.55
			mins = 15
		_:
			base = 0.4
			mins = 10
	var quality := clampf(timing_score, 0.0, 1.0)
	var gain := base * (0.45 + quality * 0.55)
	fitness_progress = minf(100.0, fitness_progress + gain * 10.0)
	if Game.time != null:
		gym_last_day = int(Game.time.day)
		Game.time.advance_minutes(float(mins))
	mark_amenity_used(&"city_workout")
	if Game.economy != null:
		Game.economy.add(&"attention", 0.35 + quality * 0.4, &"workout")
		Game.economy.add(&"popularity", 0.1 + quality * 0.25, &"workout")
		if intens == "intense" and quality < 0.35:
			Game.economy.add(&"attention", -0.3, &"overtrain")
	EventBus.toast("Тренировка (%s): фитнес %.0f · +%d мин" % [intens, fitness_progress, mins], &"ok")
	city_changed.emit()
	return {"ok": true, "fitness": fitness_progress, "minutes": mins, "quality": quality}


func hero_style_label() -> String:
	var hair := str(hero_style.get("hair", "short"))
	var beard := str(hero_style.get("beard", "clean"))
	var tags: Array = hero_style.get("style_tags", [])
	var tag_s := ", ".join(PackedStringArray(tags)) if not tags.is_empty() else "casual"
	return "%s / %s · %s" % [hair, beard, tag_s]


func apply_barber_style(hair: String, beard: String, style_tag: String = "") -> Dictionary:
	if not is_district_unlocked(CityDistricts.AGENCY_ROW):
		EventBus.toast("Барбер откроется с районом агентства", &"warn")
		return {"ok": false, "reason": "locked"}
	if not Game.economy.try_spend({"money": 25.0}, &"barber"):
		EventBus.toast("Стрижка стоит 25$", &"warn")
		return {"ok": false, "reason": "money"}
	hero_style["hair"] = hair if hair != "" else str(hero_style.get("hair", "short"))
	hero_style["beard"] = beard if beard != "" else str(hero_style.get("beard", "clean"))
	var tags: Array = hero_style.get("style_tags", [])
	if style_tag != "" and not tags.has(style_tag):
		tags.append(style_tag)
		while tags.size() > 3:
			tags.remove_at(0)
	hero_style["style_tags"] = tags
	if Game.time != null:
		Game.time.advance_minutes(20.0)
	Game.economy.add(&"attention", 0.25, &"barber")
	EventBus.toast("Новый стиль: %s" % hero_style_label(), &"ok")
	city_changed.emit()
	return {"ok": true, "style": hero_style.duplicate(true)}


func can_shoot_photo_today() -> bool:
	if Game == null or Game.time == null:
		return true
	return int(Game.time.day) != photo_last_day


func store_profile_photo(meta: Dictionary, image: Image = null) -> Dictionary:
	## Saves capture path under user://profile_photos and keeps metadata in city save.
	if not is_district_unlocked(CityDistricts.AGENCY_ROW):
		return {"ok": false, "reason": "locked"}
	var dir := "user://profile_photos"
	DirAccess.make_dir_recursive_absolute(dir)
	var pid := "photo_%d_%d" % [Time.get_unix_time_from_system(), profile_photos.size()]
	var path := "%s/%s.png" % [dir, pid]
	if image != null:
		var err := image.save_png(path)
		if err != OK:
			EventBus.toast("Не удалось сохранить кадр", &"warn")
			return {"ok": false, "reason": "save"}
	var entry: Dictionary = {
		"id": pid,
		"path": path,
		"outfit": str(meta.get("outfit", "")),
		"backdrop": str(meta.get("backdrop", "neutral")),
		"pose": str(meta.get("pose", "idle")),
		"layout": "",
		"caption": "",
		"published": false,
	}
	profile_photos.append(entry)
	if Game.time != null:
		photo_last_day = int(Game.time.day)
		Game.time.advance_minutes(15.0)
	mark_amenity_used(&"photo_studio")
	city_changed.emit()
	return {"ok": true, "photo": entry.duplicate(true)}


func publish_profile_photo(photo_id: String, layout: String, caption: String) -> Dictionary:
	var entry: Dictionary = {}
	var idx := -1
	for i in range(profile_photos.size()):
		var p: Dictionary = profile_photos[i]
		if str(p.get("id", "")) == photo_id:
			entry = p
			idx = i
			break
	if idx < 0:
		EventBus.toast("Нет такого снимка", &"warn")
		return {"ok": false, "reason": "missing"}
	entry["layout"] = layout
	entry["caption"] = caption
	entry["published"] = true
	profile_photos[idx] = entry
	var pop := 1.2
	var att := 0.5
	match layout:
		"cover":
			pop = 2.0
			att = 0.8
		"side":
			pop = 0.9
			att = 0.35
		_:
			pop = 1.4
			att = 0.55
	match str(entry.get("backdrop", "neutral")):
		"romantic":
			pop += 0.3
		"business":
			att += 0.2
		"creative":
			pop += 0.2
			soft_candidate_bias = minf(3.0, soft_candidate_bias + 0.35)
		"sport":
			att += 0.15
			soft_candidate_bias = minf(3.0, soft_candidate_bias + 0.2)
		_:
			soft_candidate_bias = minf(3.0, soft_candidate_bias + 0.15)
	if Game.economy != null:
		Game.economy.add(&"popularity", pop, &"profile_photo")
		Game.economy.add(&"attention", att, &"profile_photo")
	if Game.girls != null and Game.girls.has_method("refresh_candidates"):
		Game.girls.refresh_candidates(true)
	EventBus.toast("Профиль опубликован (%s): +⭐ %.1f" % [layout, pop], &"ok")
	city_changed.emit()
	return {"ok": true, "photo": entry.duplicate(true), "popularity": pop}


const THEMED_APARTMENTS: Array = [
	{"id": "apt_cozy", "name": "Уют", "cost": 200.0, "blurb": "Тёплый свет, мягкая мебель"},
	{"id": "apt_modern", "name": "Модерн", "cost": 350.0, "blurb": "Холодный минимализм"},
	{"id": "apt_creative", "name": "Креатив", "cost": 280.0, "blurb": "Яркие акценты и холст"},
]


func themed_apartment_catalog() -> Array:
	return THEMED_APARTMENTS.duplicate(true)


func is_apartment_unlocked(id: StringName) -> bool:
	if id == &"apartment" or id == &"home":
		return true
	return unlocked_apartments.has(id)


func can_unlock_themed_apartments() -> bool:
	## After first clone OR stage_4+.
	var stage_ok := false
	if Game != null:
		var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
		stage_ok = int(order.get(str(Game.stage_id), 1)) >= 4
	var clone_ok := false
	if Game != null and Game.clones != null:
		clone_ok = Game.clones.clones.size() > 0 or not Game.clones.pending.is_empty()
		if not clone_ok and Game.facility != null:
			clone_ok = Game.facility.has_flag("stage_4a")
	return stage_ok or clone_ok


func buy_themed_apartment(id: StringName) -> bool:
	if is_apartment_unlocked(id):
		EventBus.toast("Квартира уже открыта", &"info")
		return false
	if not can_unlock_themed_apartments():
		EventBus.toast("Нужен первый клон или stage_4", &"warn")
		return false
	var cost := 0.0
	var label := str(id)
	for a in THEMED_APARTMENTS:
		if str(a.get("id", "")) == str(id):
			cost = float(a.get("cost", 0))
			label = str(a.get("name", id))
			break
	if cost <= 0.0:
		EventBus.toast("Неизвестная квартира", &"warn")
		return false
	if not Game.economy.try_spend({"money": cost}, &"apt_unlock"):
		EventBus.toast("Нужно %.0f$ на квартиру «%s»" % [cost, label], &"warn")
		return false
	unlocked_apartments.append(id)
	if Game.facility != null and not Game.facility.unlocked_rooms.has(id):
		Game.facility.unlocked_rooms.append(id)
		Game.facility.facility_changed.emit()
	EventBus.toast("Открыта квартира «%s»" % label, &"facility")
	city_changed.emit()
	return true


func assign_apartment(apt_id: StringName, girl_id: String, lead: String = "player") -> bool:
	if not is_apartment_unlocked(apt_id) and apt_id != &"apartment":
		EventBus.toast("Квартира закрыта", &"warn")
		return false
	var lead_s := lead if lead in ["player", "clone"] else "player"
	apartment_assignments[str(apt_id)] = {"girl_id": girl_id, "lead": lead_s}
	EventBus.toast("Назначение: %s → %s (lead=%s)" % [str(apt_id), girl_id if girl_id != "" else "—", lead_s], &"info")
	city_changed.emit()
	return true


func elevator_destinations() -> Array:
	var out: Array = [
		{"id": "apartment", "name": "Главная квартира", "unlocked": true},
		{"id": "lab", "name": "Лаборатория", "unlocked": true},
	]
	for a in THEMED_APARTMENTS:
		var aid := StringName(str(a.get("id", "")))
		out.append({
			"id": str(aid),
			"name": "Квартира «%s»" % str(a.get("name", aid)),
			"unlocked": is_apartment_unlocked(aid),
			"cost": float(a.get("cost", 0)),
		})
	return out


func try_elevator_wrong_girl() -> Dictionary:
	## Minimal sim: when clone date active, chance of wrong-girl elevator prompt.
	if Game == null or Game.dating == null:
		return {}
	if not Game.dating.has_method("has_active_clone_date") or not bool(Game.dating.call("has_active_clone_date")):
		return {}
	if randf() > 0.45:
		return {}
	return {
		"active": true,
		"prompt": "В лифте уже стоит «ты» с другой девушкой. Подождать следующий или ехать вместе?",
	}


func resolve_elevator_incident(choice: String) -> void:
	## safe wait vs risk ride-together.
	if choice == "wait":
		EventBus.toast("Подождал следующий лифт — безопасно", &"ok")
		return
	if choice != "ride":
		return
	Game.economy.add(&"scandal", 1.2, &"elevator_risk")
	if Game.economy.has_method("damage_legend"):
		Game.economy.damage_legend(1.5, &"elevator_risk")
	var girl_hit := ""
	if Game.dating != null and Game.dating.schedule != null and Game.dating.schedule.has_booking():
		girl_hit = Game.dating.schedule.target_id()
	if girl_hit != "" and Game.girls != null:
		Game.girls.add_bond(StringName(girl_hit), -4.0)
	EventBus.toast("Поехали вместе — подозрение растёт (скандал / бонд)", &"warn")


func schedule_board_entries() -> Array:
	## Upcoming dates for agency office overlay (player lead for now).
	var out: Array = []
	if Game == null or Game.dating == null:
		return out
	var sched: Dictionary = {}
	if Game.dating.schedule != null and Game.dating.schedule.has_booking():
		sched = Game.dating.schedule.scheduled.duplicate(true)
		var day := int(sched.get("day", 1))
		var mins := int(sched.get("minutes", 0))
		var place := str(sched.get("place_id", sched.get("place", "?")))
		var girl := str(sched.get("target_id", "?"))
		var name := girl
		if Game.girls != null:
			name = Game.girls.display_name(StringName(girl))
		out.append({
			"girl_id": girl,
			"girl_name": name,
			"day": day,
			"minutes": mins,
			"place": place,
			"lead": "player",
			"slot_key": "%d_%d" % [day, mins],
			"conflict": false,
		})
	if Game.clones != null:
		var free_slots: int = Game.clones.available_count() if Game.clones.has_method("available_count") else 0
		var max_slots: int = int(Game.clones.get("max_slots")) if Game.clones.get("max_slots") != null else 0
		var busy: Dictionary = Game.clones.get("busy") if Game.clones.get("busy") is Dictionary else {}
		out.append({
			"girl_id": "",
			"girl_name": "Клоны",
			"day": 0,
			"minutes": -1,
			"place": "slots %d/%d free" % [free_slots, max_slots],
			"lead": "clone_pool",
			"slot_key": "clones",
			"conflict": false,
			"clone_busy": busy.size(),
		})
		# Soft conflict: a clone marked busy while player also has a booking same day window.
		if not sched.is_empty() and not busy.is_empty():
			for e in out:
				if str(e.get("lead", "")) == "player":
					e["conflict"] = true
					e["conflict_note"] = "Клон занят в параллели — проверь слоты"
	# Occupancy dict (player + clone/manager autos) → board conflicts.
	if Game.dating.schedule != null and Game.dating.schedule.has_method("occupancy_entries"):
		for occ in Game.dating.schedule.occupancy_entries():
			var oplace := str(occ.get("place", ""))
			var oday := int(occ.get("day", 1))
			var omins := int(occ.get("minutes", -1))
			var olead := str(occ.get("lead", "?"))
			if olead == "player":
				continue
			var ogirl := str(occ.get("girl_id", ""))
			var oname := ogirl
			if Game.girls != null and ogirl != "":
				oname = Game.girls.display_name(StringName(ogirl))
			var row := {
				"girl_id": ogirl,
				"girl_name": oname if oname != "" else olead,
				"day": oday,
				"minutes": omins,
				"place": oplace,
				"lead": olead,
				"slot_key": "%s_%d_%d" % [oplace, oday, omins],
				"conflict": false,
			}
			if not sched.is_empty() and str(sched.get("place_id", "")) == oplace:
				var sday := int(sched.get("day", 1))
				var smins := int(sched.get("minutes", 0))
				if sday == oday and (omins < 0 or smins == omins):
					row["conflict"] = true
					row["conflict_note"] = "Конфликт вместимости: то же место/время"
					for e in out:
						if str(e.get("lead", "")) == "player":
							e["conflict"] = true
							e["conflict_note"] = "Конфликт вместимости с %s" % olead
			out.append(row)
	# Apartment assignments for agency board.
	for apt_id in apartment_assignments.keys():
		var asn: Dictionary = apartment_assignments[apt_id]
		var agirl := str(asn.get("girl_id", ""))
		var aname := agirl
		if Game.girls != null and agirl != "":
			aname = Game.girls.display_name(StringName(agirl))
		out.append({
			"girl_id": agirl,
			"girl_name": aname if aname != "" else "—",
			"day": 0,
			"minutes": -1,
			"place": str(apt_id),
			"lead": str(asn.get("lead", "player")),
			"slot_key": "assign_%s" % str(apt_id),
			"conflict": false,
			"assignment": true,
		})
	# Detect duplicate slot keys among player bookings (future multi-book).
	var seen: Dictionary = {}
	for e2 in out:
		var key := str(e2.get("slot_key", ""))
		if key == "" or key == "clones" or key.begins_with("assign_"):
			continue
		if seen.has(key):
			e2["conflict"] = true
			e2["conflict_note"] = "Два букинга в один слот"
			var prev: Dictionary = seen[key]
			prev["conflict"] = true
			prev["conflict_note"] = "Два букинга в один слот"
		else:
			seen[key] = e2
	return out


func _build_roster() -> void:
	roster.clear()
	# Tutorial-friendly cashier near plaza — worthy from the start after neighbor date.
	roster.append(_city_girl("city_cashier", "Кассирша из «Уголка»", "shop", Color(0.98, 0.78, 0.72),
		{"min_popularity": 0, "min_dates": 1}, "bob", Color(0.45, 0.25, 0.15),
		["sincere", "cheap", "calm"], ["luxury"], "street_plaza"))
	roster.append(_city_girl("city_barista", "Бариста", "cafe", Color(0.85, 0.65, 0.55),
		{"min_popularity": 3, "min_dates": 1}, "pony", Color(0.15, 0.08, 0.05),
		["tasty", "media"], ["sport"], "internet_cafe"))
	roster.append(_city_girl("city_jogger", "Бегунья", "sport", Color(0.55, 0.9, 0.7),
		{"min_popularity": 4, "min_dates": 1}, "short", Color(0.35, 0.2, 0.1),
		["sport", "active"], ["cheap"], "park"))
	roster.append(_city_girl("city_librarian", "Библиотекарша", "calm", Color(0.9, 0.82, 0.75),
		{"min_popularity": 2, "min_dates": 1}, "bun", Color(0.25, 0.15, 0.12),
		["sincere", "calm"], ["scandal"], "park"))
	roster.append(_city_girl("city_clerk", "Офис-менеджер", "business", Color(0.75, 0.7, 0.68),
		{"min_popularity": 8, "min_dates": 2}, "bob", Color(0.1, 0.08, 0.08),
		["business", "order"], ["chaos"], "street_plaza"))
	roster.append(_city_girl("city_artist", "Уличная художница", "art", Color(0.95, 0.7, 0.85),
		{"min_popularity": 6, "min_dates": 1}, "long", Color(0.55, 0.15, 0.45),
		["weird", "fashion"], ["business"], "street_plaza"))
	roster.append(_city_girl("city_gamer", "Киберспортсменка", "media", Color(0.7, 0.85, 1.0),
		{"min_popularity": 5, "min_dates": 1}, "short", Color(0.05, 0.6, 0.7),
		["media", "tech"], ["calm"], "internet_cafe"))
	roster.append(_city_girl("city_florist", "Флористка", "cute", Color(0.95, 0.8, 0.78),
		{"min_popularity": 1, "min_dates": 1}, "bob", Color(0.6, 0.35, 0.2),
		["sincere", "tasty"], ["dark"], "corner_shop"))
	roster.append(_city_girl("city_biker", "Мотоциклистка", "chaos", Color(0.65, 0.55, 0.6),
		{"min_popularity": 10, "min_dates": 2}, "pony", Color(0.05, 0.05, 0.08),
		["chaos", "sport"], ["luxury"], "bus_stop"))
	roster.append(_city_girl("city_student", "Студентка", "young", Color(0.92, 0.76, 0.7),
		{"min_popularity": 0, "min_dates": 1}, "long", Color(0.3, 0.18, 0.1),
		["cheap", "sincere"], ["luxury"], "bus_stop"))
	roster.append(_city_girl("city_dj", "Диджейша", "party", Color(0.85, 0.55, 0.9),
		{"min_popularity": 12, "min_dates": 2}, "short", Color(0.7, 0.1, 0.5),
		["media", "scandal"], ["calm"], "night_bar"))
	roster.append(_city_girl("city_nurse", "Медсестра", "care", Color(0.95, 0.85, 0.82),
		{"min_popularity": 7, "min_dates": 2}, "bun", Color(0.4, 0.25, 0.15),
		["sincere", "useful"], ["chaos"], "street_plaza"))
	roster.append(_city_girl("city_coach", "Тренерша", "sport", Color(0.45, 0.85, 0.55),
		{"min_popularity": 9, "min_dates": 2}, "pony", Color(0.2, 0.12, 0.08),
		["sport", "active"], ["cheap"], "gym_front"))
	roster.append(_city_girl("city_critic", "Кинокритик", "media", Color(0.8, 0.75, 0.7),
		{"min_popularity": 14, "min_dates": 3}, "bob", Color(0.15, 0.1, 0.1),
		["media", "luxury"], ["cheap"], "night_bar"))
	roster.append(_city_girl("city_tourist", "Туристка", "travel", Color(0.98, 0.88, 0.75),
		{"min_popularity": 3, "min_dates": 1}, "long", Color(0.85, 0.7, 0.4),
		["weird", "luxury"], ["order"], "park"))
	# Unique anchors (stage + popularity from ContentDB). Neighbor = phone contact; algorithm = finale-only.
	roster.append(_unique_roster_anchor("fitness", "gym_front", 1))
	roster.append(_unique_roster_anchor("goth", "night_bar", 1))
	roster.append(_unique_roster_anchor("streamer", "internet_cafe", 2))
	roster.append(_unique_roster_anchor("chef", "corner_shop", 3))
	roster.append(_unique_roster_anchor("business", "bus_stop", 3))
	roster.append(_unique_roster_anchor("fashionista", "street_plaza", 3))
	roster.append(_unique_roster_anchor("scientist", "internet_cafe", 3))
	roster.append(_unique_roster_anchor("lawyer", "bus_stop", 4))
	roster.append(_unique_roster_anchor("star", "night_bar", 5))
	roster.append(_unique_roster_anchor("alien", "park", 5))


func _city_girl(id: String, name: String, archetype: String, skin: Color, worth: Dictionary, hair: String, hair_c: Color, likes: Array, dislikes: Array, home: String) -> Dictionary:
	var pack: Dictionary = {}
	if Game.trait_influence != null and not Game.trait_influence.get_search_targets().is_empty():
		pack = Game.trait_influence.roll_search_profile(likes)
	else:
		pack = TraitsContent.pack_for_profile({"id": id, "likes": likes})
	var derived_likes: Array = likes.duplicate()
	for tid in pack.get("traits", []):
		for tag in TraitsContent.TRAIT_PREP_TAGS.get(str(tid), []):
			if not derived_likes.has(tag):
				derived_likes.append(tag)
	return {
		"id": id,
		"kind": "city",
		"name": name,
		"archetype": archetype,
		"color": [skin.r, skin.g, skin.b],
		"hair_style": hair,
		"hair_color": [hair_c.r, hair_c.g, hair_c.b],
		"eye_color": [0.25, 0.4, 0.55],
		"worthiness": worth,
		"likes": derived_likes,
		"dislikes": dislikes,
		"home_spot": home,
		"unique": false,
		"tier": "simple",
		"primary_traits": pack.get("primary_traits", []),
		"traits": pack.get("traits", []),
		"quirk": str(pack.get("quirk", "")),
		"soft_signal": str(pack.get("soft_signal", "")),
	}


func _unique_roster_anchor(id: String, home: String, min_dates: int) -> Dictionary:
	## Worthiness stage/popularity come from ContentDB so routes stay aligned with unlock_stage.
	var def: Dictionary = ContentDB.girl(StringName(id))
	var worth: Dictionary = {
		"min_popularity": float(def.get("popularity_need", 0.0)),
		"min_dates": min_dates,
		"stage": str(def.get("unlock_stage", "stage_1")),
	}
	return _unique_anchor(id, home, worth)


func _unique_anchor(id: String, home: String, worth: Dictionary) -> Dictionary:
	var def: Dictionary = ContentDB.girl(StringName(id))
	var col: Array = def.get("color", [0.9, 0.7, 0.7])
	return {
		"id": id,
		"kind": "unique",
		"name": str(def.get("archetype", id)),
		"archetype": str(def.get("archetype", id)),
		"color": col,
		"hair_style": str(def.get("hair_style", "bob")),
		"worthiness": worth,
		"likes": def.get("likes", []),
		"dislikes": def.get("dislikes", []),
		"home_spot": home,
		"unique": true,
		"tier": str(def.get("tier", "simple")),
		"primary_traits": def.get("primary_traits", []),
		"traits": def.get("traits", []),
		"quirk": str(def.get("quirk", "")),
	}


func get_profile(id: String) -> Dictionary:
	for g in roster:
		if str(g.get("id", "")) == id:
			return g
	if ContentDB.girls.has(id):
		return _unique_anchor(id, "street_plaza", {"min_popularity": float(ContentDB.girl(StringName(id)).get("popularity_need", 0)), "min_dates": 0})
	return {}


func is_worthy(id: String) -> bool:
	if id == "neighbor":
		return true
	if id == "algorithm":
		return false
	var p: Dictionary = get_profile(id)
	if p.is_empty():
		return false
	var w: Dictionary = p.get("worthiness", {})
	if Game.economy.get_value(&"popularity") < float(w.get("min_popularity", 0)):
		return false
	if Game.total_successful_dates < int(w.get("min_dates", 0)):
		return false
	var need_stage: String = str(w.get("stage", ""))
	if need_stage != "" and not _stage_reached(need_stage):
		return false
	if bool(p.get("unique", false)) or ContentDB.girls.has(id):
		var def: Dictionary = ContentDB.girl(StringName(id))
		if not _stage_reached(str(def.get("unlock_stage", "stage_1"))):
			return false
		if Game.girls != null:
			Game.girls.try_unlock_by_progress()
			if Game.girls.has_method("is_discovered") and not bool(Game.girls.is_discovered(StringName(id))):
				return false
	return true


func _stage_reached(need: String) -> bool:
	var order: Dictionary = {"stage_1": 1, "stage_2": 2, "stage_3": 3, "stage_4": 4, "stage_5": 5, "stage_6": 6}
	return int(order.get(str(Game.stage_id), 1)) >= int(order.get(need, 1))


func has_contact(id: String) -> bool:
	return Game.girls.has_contact(StringName(id))


func talk(id: String) -> Dictionary:
	## Returns {ok:bool, line:String}
	if id == "neighbor":
		var lines: Array = ContentDB.girl(&"neighbor").get("lines", ["Привет, сосед."])
		return {"ok": true, "line": str(lines[0]), "already": true}
	if id == "algorithm":
		return {"ok": false, "line": "Её нельзя встретить на улице.", "already": false}
	if has_contact(id):
		return {"ok": true, "line": "Мы уже на связи. Пиши в телефон.", "already": true}
	if not is_worthy(id):
		snubs[id] = int(snubs.get(id, 0)) + 1
		var line: String = REJECT_LINES[randi() % REJECT_LINES.size()]
		var girl_node_hint: Dictionary = get_profile(id)
		if not girl_node_hint.is_empty():
			# emotion hint via event
			EventBus.notify.emit("CITY_REJECT:%s" % id, &"city")
		Sfx.play_ui(&"deny")
		return {"ok": false, "line": line, "already": false}
	Game.girls.add_contact(StringName(id), get_profile(id))
	var accept: String = ACCEPT_LINES[randi() % ACCEPT_LINES.size()]
	contact_gained.emit(id)
	tutorial_target_id = ""
	Game.quests.complete("s1_contact")
	Sfx.play_ui(&"confirm")
	EventBus.toast("Новый контакт: %s" % str(get_profile(id).get("name", id)), &"girl")
	city_changed.emit()
	return {"ok": true, "line": accept, "already": false}


func pick_tutorial_target() -> String:
	## Legacy: step 6 accepts any girl — no forced marked target.
	tutorial_target_id = ""
	city_changed.emit()
	return tutorial_target_id


func profiles_for_spawn() -> Array:
	## Prefer unique meet-paths so stage anchors are not crowded out by city filler.
	if Game.girls != null and Game.girls.has_method("try_unlock_by_progress"):
		Game.girls.try_unlock_by_progress()
	var uniques: Array = []
	var city_girls: Array = []
	var seen: Dictionary = {}
	for g in roster:
		var id: String = str(g.get("id", ""))
		if id == "" or seen.has(id):
			continue
		var is_unique: bool = bool(g.get("unique", false))
		var w: Dictionary = g.get("worthiness", {})
		var need_stage: String = str(w.get("stage", "stage_1"))
		if need_stage != "" and not _stage_reached(need_stage):
			if is_unique:
				continue
		if is_unique:
			var discovered_ok: bool = true
			if Game.girls != null and Game.girls.has_method("is_discovered"):
				discovered_ok = bool(Game.girls.call("is_discovered", StringName(id)))
			elif Game.girls != null:
				var disc: Array = Game.girls.discovered_unique
				discovered_ok = disc.has(StringName(id))
			if not discovered_ok:
				continue
			seen[id] = true
			uniques.append(g)
		else:
			seen[id] = true
			city_girls.append(g)
	var out: Array = []
	out.append_array(uniques)
	out.append_array(city_girls)
	return out


func to_dict() -> Dictionary:
	var districts: Array = []
	for d in unlocked_districts:
		districts.append(str(d))
	var apts: Array = []
	for a in unlocked_apartments:
		apts.append(str(a))
	return {
		"snubs": snubs.duplicate(true),
		"tutorial_target_id": tutorial_target_id,
		"outside_tip_shown": outside_tip_shown,
		"unlocked_districts": districts,
		"amenity_last_use": amenity_last_use.duplicate(true),
		"fitness_progress": fitness_progress,
		"gym_last_day": gym_last_day,
		"hero_style": hero_style.duplicate(true),
		"profile_photos": profile_photos.duplicate(true),
		"soft_candidate_bias": soft_candidate_bias,
		"photo_last_day": photo_last_day,
		"unlocked_apartments": apts,
		"apartment_assignments": apartment_assignments.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	snubs = data.get("snubs", {})
	tutorial_target_id = str(data.get("tutorial_target_id", ""))
	outside_tip_shown = bool(data.get("outside_tip_shown", false))
	amenity_last_use = data.get("amenity_last_use", {})
	fitness_progress = float(data.get("fitness_progress", 0.0))
	gym_last_day = int(data.get("gym_last_day", -1))
	hero_style = data.get("hero_style", {"hair": "short", "beard": "clean", "style_tags": ["casual"]})
	if hero_style.is_empty():
		hero_style = {"hair": "short", "beard": "clean", "style_tags": ["casual"]}
	profile_photos = data.get("profile_photos", [])
	soft_candidate_bias = float(data.get("soft_candidate_bias", 0.0))
	photo_last_day = int(data.get("photo_last_day", -1))
	unlocked_apartments.clear()
	for a in data.get("unlocked_apartments", []):
		var aid := StringName(str(a))
		if not unlocked_apartments.has(aid):
			unlocked_apartments.append(aid)
	apartment_assignments = data.get("apartment_assignments", {})
	if apartment_assignments == null:
		apartment_assignments = {}
	unlocked_districts.clear()
	var raw_d: Array = data.get("unlocked_districts", [])
	if raw_d.is_empty():
		unlocked_districts = CityDistricts.default_unlocked()
	else:
		for d in raw_d:
			var sid := StringName(str(d))
			if not unlocked_districts.has(sid):
				unlocked_districts.append(sid)
	if not unlocked_districts.has(CityDistricts.MAIN_STREET):
		unlocked_districts.insert(0, CityDistricts.MAIN_STREET)
	_build_roster()
	try_unlock_park_from_progress()
	try_unlock_agency_row_from_progress()
	city_changed.emit()
