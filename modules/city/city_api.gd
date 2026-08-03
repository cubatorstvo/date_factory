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


func setup(_game: Node) -> void:
	ContentDB.ensure_loaded()
	reset()


func reset() -> void:
	snubs.clear()
	tutorial_target_id = ""
	outside_tip_shown = false
	_build_roster()
	city_changed.emit()


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
	# Unique anchors when stage allows (spawned by director if not yet contacted).
	roster.append(_unique_anchor("fitness", "gym_front", {"min_popularity": 8, "min_dates": 1, "stage": "stage_2"}))
	roster.append(_unique_anchor("goth", "night_bar", {"min_popularity": 12, "min_dates": 1, "stage": "stage_2"}))
	roster.append(_unique_anchor("streamer", "internet_cafe", {"min_popularity": 15, "min_dates": 2, "stage": "stage_2"}))
	roster.append(_unique_anchor("chef", "corner_shop", {"min_popularity": 35, "min_dates": 3, "stage": "stage_3"}))


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
	var p: Dictionary = get_profile(id)
	if p.is_empty():
		return false
	var w: Dictionary = p.get("worthiness", {})
	if Game.economy.get_value(&"popularity") < float(w.get("min_popularity", 0)):
		return false
	if Game.total_successful_dates < int(w.get("min_dates", 0)):
		return false
	var need_stage := str(w.get("stage", ""))
	if need_stage != "" and not _stage_reached(need_stage):
		return false
	if bool(p.get("unique", false)):
		var def: Dictionary = ContentDB.girl(StringName(id))
		if not _stage_reached(str(def.get("unlock_stage", "stage_1"))):
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
	var out: Array = []
	for g in roster:
		var id := str(g.get("id", ""))
		if has_contact(id) and bool(g.get("unique", false)):
			# Still can wander, but no need to force
			pass
		var w: Dictionary = g.get("worthiness", {})
		var need_stage := str(w.get("stage", "stage_1"))
		if need_stage != "" and not _stage_reached(need_stage if need_stage != "" else "stage_1"):
			# Allow stage_1 city girls always; unique anchors gated.
			if bool(g.get("unique", false)):
				continue
		out.append(g)
	return out


func to_dict() -> Dictionary:
	return {"snubs": snubs.duplicate(true), "tutorial_target_id": tutorial_target_id, "outside_tip_shown": outside_tip_shown}


func from_dict(data: Dictionary) -> void:
	snubs = data.get("snubs", {})
	tutorial_target_id = str(data.get("tutorial_target_id", ""))
	outside_tip_shown = bool(data.get("outside_tip_shown", false))
	_build_roster()
	city_changed.emit()
