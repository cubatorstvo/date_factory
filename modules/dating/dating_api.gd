class_name DatingAPI
extends Node
## Manual and automated dating pipeline.

signal date_ui_open(payload: Dictionary)
signal date_ui_close
signal date_phase(phase_index: int, options: Array)
signal auto_date_tick(active_count: int)

enum Grade { CATASTROPHE, FAIL, OK, SUCCESS, PERFECT }

var prepared: Dictionary = {} ## girl/candidate prep
var active_manual: Dictionary = {}
var auto_queue: Array = []
var active_autos: Array = []
var stats: Dictionary = {"total": 0, "success": 0, "perfect": 0, "fail": 0}
var last_result: Dictionary = {}
var automation_level: int = 0 ## 0 manual launch, 1 manager prep, 2 clone, 3 full line
var auto_risk_mode: String = "standard" ## careful | standard | risk
var parallel_runs: int = 0 ## successful player+double overlaps resolved
var last_collision: Dictionary = {}
var schedule: DateSchedule = DateSchedule.new()


func setup(_game: Node) -> void:
	reset()


func reset() -> void:
	prepared.clear()
	active_manual.clear()
	auto_queue.clear()
	active_autos.clear()
	stats = {"total": 0, "success": 0, "perfect": 0, "fail": 0}
	last_result.clear()
	automation_level = 0
	auto_risk_mode = "standard"
	parallel_runs = 0
	last_collision.clear()
	if schedule == null:
		schedule = DateSchedule.new()
	schedule.reset()


func set_prep(target_id: String, gift_id: StringName, venue_id: StringName, outfit_id: StringName, extra: StringName = &"") -> void:
	prepared[target_id] = {
		"gift_id": str(gift_id),
		"venue_id": str(venue_id),
		"outfit_id": str(outfit_id),
		"extra": str(extra),
	}


func get_prep(target_id: String) -> Dictionary:
	return prepared.get(target_id, {}).duplicate(true)


func book_date(target_id: String, place_id: String, day: int, minutes: int, is_unique: bool = true) -> bool:
	return schedule.book(target_id, place_id, day, minutes, is_unique)


func cancel_date(reason: String = "cancelled") -> void:
	schedule.cancel(reason)


func has_scheduled_date() -> bool:
	return schedule.has_booking()


func scheduled_summary() -> Dictionary:
	if not schedule.has_booking():
		return {}
	return schedule.scheduled.duplicate(true)


func can_start_manual(target_id: String) -> bool:
	if not active_manual.is_empty():
		return false
	if Game.girls.is_claimed(StringName(target_id)):
		EventBus.toast("Она уже твоя — свидания не нужны", &"info")
		return false
	if Game.economy.get_value(&"attention") < 1.0:
		EventBus.bottleneck.emit(&"attention", "Не хватает внимания")
		return false
	if schedule.has_booking() and schedule.target_id() != target_id:
		EventBus.toast("Назначено свидание с другой девушкой", &"warn")
		return false
	if schedule.has_booking():
		if schedule.is_home() and not schedule.can_start_home():
			return false
		if schedule.is_no_prep() and not schedule.can_start_restaurant():
			return false
	else:
		var prep: Dictionary = get_prep(target_id)
		if prep.is_empty():
			EventBus.toast("Сначала назначь свидание в телефоне", &"warn")
			return false
	var venue_key: String = "kitchen_table"
	if schedule.has_booking():
		venue_key = str(schedule.scheduled.get("venue_id", "kitchen_table"))
	else:
		venue_key = str(get_prep(target_id).get("venue_id", "kitchen_table"))
	var venue_id: StringName = StringName(venue_key)
	if not Game.facility.is_venue_unlocked(venue_id):
		EventBus.toast("Место ещё не открыто", &"warn")
		return false
	if not Game.facility.reserve_venue(venue_id):
		EventBus.bottleneck.emit(&"venue", "Место занято")
		return false
	return true


func start_manual(target_id: String, is_unique: bool = true) -> bool:
	if not can_start_manual(target_id):
		return false
	var prep: Dictionary = {}
	if schedule.has_booking():
		var abs_now: int = Game.time.absolute_minutes() if Game.time != null else 0
		schedule.compute_punctuality(abs_now)
		prep = schedule.build_prep_from_booking()
		is_unique = bool(schedule.scheduled.get("unique", is_unique))
		# Soft bond hit for late arrival (cooler mood at date start).
		if bool(prep.get("late_soft_hit", false)) or schedule.late_soft_hit:
			var bond_wrong: float = float(ContentDB.balance.get("bond_wrong", -12.0))
			Game.girls.add_bond(StringName(target_id), bond_wrong * 0.35)
			EventBus.toast("Опоздание: она чуть холоднее", &"warn")
		prepared[target_id] = prep.duplicate(true)
	else:
		prep = get_prep(target_id)
	var venue_id: StringName = StringName(str(prep.get("venue_id", "kitchen_table")))
	var venue_cost: float = float(prep.get("cost", ContentDB.venue(venue_id).get("cost", 0)))
	if schedule.has_booking():
		venue_cost = float(schedule.scheduled.get("cost", venue_cost))
	venue_cost *= Game.upgrades.effect_value("venue_cost_mult", 1.0)
	var effects: Dictionary = Game.girls.active_effects()
	venue_cost *= float(effects.get("date_cost_mult", 1.0))
	if venue_cost > 0.0 and not Game.economy.try_spend({"money": venue_cost}, &"venue"):
		Game.facility.release_venue(venue_id)
		EventBus.toast("Не хватает денег на место", &"warn")
		return false
	Game.economy.add(&"attention", -1.0, &"manual_date")
	# Gift is optional — only consumed if already set on prep (mid-date give uses give_date_gift).
	var gift_id: StringName = StringName(str(prep.get("gift_id", "")))
	var prep_gift_applied: bool = false
	if gift_id != &"" and schedule.gift_given_id.is_empty():
		if Game.inventory.carried_item == gift_id:
			Game.inventory.consume_carried()
			prep_gift_applied = true
		elif Game.inventory.gift_count(gift_id) > 0:
			Game.inventory.gift_counts[str(gift_id)] = Game.inventory.gift_count(gift_id) - 1
			Game.inventory.inventory_changed.emit()
			prep_gift_applied = true
		else:
			prep["gift_id"] = ""

	var place_id_start := str(prep.get("place_id", ""))
	active_manual = {
		"target_id": target_id,
		"unique": is_unique,
		"prep": prep,
		"gift_given": prep_gift_applied,
		"phase": 0,
		"score": 0.0,
		"choices": [],
		"bond_delta": 0.0,
		"used_traits": [],
		"used_dialogs": [],
		"correct": 0,
		"wrong": 0,
		"neutral": 0,
		"phases_done": false,
		"park_flow": place_id_start == "park",
		"cinema_flow": place_id_start == "cinema",
		"arcade_flow": place_id_start == "arcade",
		"cinema_genre": "",
		"arcade_done": false,
		"weather": DatePlaces.current_weather() if place_id_start == "park" else "",
	}
	schedule.awaiting_finish = false
	if schedule.has_booking():
		schedule.clear_after_start()
	_sync_parallel_risk(str(prep.get("venue_id", "kitchen_table")), "player")
	Game.girls.mark_met(StringName(target_id))
	date_ui_open.emit(_manual_payload())
	_emit_phase()
	return true


func _manual_payload() -> Dictionary:
	var tid := str(active_manual.get("target_id", ""))
	var unique := bool(active_manual.get("unique", true))
	var prep: Dictionary = active_manual.get("prep", {})
	return {
		"target_id": tid,
		"unique": unique,
		"gift_id": str(prep.get("gift_id", "")),
		"prep": prep,
		"title": _target_title(tid, unique),
		"phase": int(active_manual.get("phase", 0)),
		"hints": profile_hints(tid, unique),
		"prompt": str(active_manual.get("prompt", "")),
		"emotion": str(active_manual.get("emotion", "neutral")),
		"bond": float(Game.girls.get_entry(StringName(tid)).get("bond", 0.0)),
		"phases_done": bool(active_manual.get("phases_done", false)),
		"gift_given": bool(active_manual.get("gift_given", false)),
		"can_gift": can_give_date_gift(),
		"awaiting_finish": bool(active_manual.get("phases_done", false)),
		"place_id": str(prep.get("place_id", "")),
	}


func _target_title(id: String, unique: bool) -> String:
	if unique or Game.girls.unlocked.has(id):
		return Game.girls.display_name(StringName(id))
	return id


func _emit_phase() -> void:
	var phase := int(active_manual.get("phase", 0))
	var target_id := str(active_manual.get("target_id", ""))
	var unique := bool(active_manual.get("unique", true))
	var options: Array = []
	var prep_now: Dictionary = active_manual.get("prep", {})
	if bool(active_manual.get("park_flow", false)) and str(prep_now.get("place_id", "")) == "park":
		options = _build_park_beat_options(phase)
	elif bool(active_manual.get("cinema_flow", false)) and str(prep_now.get("place_id", "")) == "cinema":
		options = _build_cinema_beat_options(phase)
	elif bool(active_manual.get("arcade_flow", false)) and str(prep_now.get("place_id", "")) == "arcade":
		options = _build_arcade_beat_options(phase)
	else:
		options = _build_phase_options(phase, target_id, unique)
	active_manual["options"] = options
	date_phase.emit(phase, options)


func _build_phase_options(_phase: int, target_id: String, _unique: bool) -> Array:
	var traits: Array = Game.girls.girl_traits(StringName(target_id))
	if traits.is_empty():
		traits = ["attention", "peace", "humor"]
	var used_traits: Array = active_manual.get("used_traits", []).duplicate()
	var used_dialogs: Array = active_manual.get("used_dialogs", []).duplicate()
	var revealed: Array = Game.girls.revealed_traits(StringName(target_id))
	# Prefer unrevealed traits still available this date.
	var pick_trait := ""
	var pool_unseen: Array = []
	var pool_any: Array = []
	for t in traits:
		var tid := str(t)
		if used_traits.has(tid):
			continue
		pool_any.append(tid)
		if not revealed.has(tid):
			pool_unseen.append(tid)
	if not pool_unseen.is_empty():
		pick_trait = str(pool_unseen[randi() % pool_unseen.size()])
	elif not pool_any.is_empty():
		pick_trait = str(pool_any[randi() % pool_any.size()])
	else:
		pick_trait = str(traits[randi() % traits.size()])
	used_traits.append(pick_trait)
	active_manual["used_traits"] = used_traits

	var cards: Array = TraitsContent.dialogues_for(pick_trait)
	var card: Dictionary = {}
	var fresh: Array = []
	for c in cards:
		if not used_dialogs.has(str(c.get("id", ""))):
			fresh.append(c)
	if fresh.is_empty():
		fresh = cards
	if fresh.is_empty():
		card = {
			"id": "fallback_%s" % pick_trait,
			"trait": pick_trait,
			"prompt": "Она смотрит на тебя и ждёт реакции.",
			"correct": {"id": "fb_c", "label": "Ответить мягко и по делу", "polarity": "correct"},
			"wrong": {"id": "fb_w", "label": "Отмахнуться", "polarity": "wrong"},
			"neutral": {"id": "fb_n", "label": "Промолчать пару секунд", "polarity": "neutral"},
		}
	else:
		card = fresh[randi() % fresh.size()].duplicate(true)
	used_dialogs.append(str(card.get("id", "")))
	active_manual["used_dialogs"] = used_dialogs
	var observation: String = str(card.get("observation", card.get("prompt", "")))
	active_manual["prompt"] = observation
	active_manual["observation"] = observation
	active_manual["phase_trait"] = pick_trait
	active_manual["card_id"] = str(card.get("id", ""))
	Game.girls.add_observation(StringName(target_id), str(card.get("id", "")), observation, pick_trait, "date")

	var options: Array = []
	if card.has("options") and card.get("options", []) is Array and not card.get("options", []).is_empty():
		for raw in card.get("options", []):
			options.append(_option_from_interpret(card, raw))
	else:
		options = [
			_option_from_polarity(card, "correct"),
			_option_from_polarity(card, "neutral"),
			_option_from_polarity(card, "wrong"),
		]
	options.shuffle()
	return options


func _option_from_interpret(card: Dictionary, raw: Dictionary) -> Dictionary:
	var quality: String = str(raw.get("quality", "ok"))
	var bal: Dictionary = ContentDB.balance
	var score: float = float(bal.get("date_score_neutral", 0.75))
	var bond: float = float(bal.get("bond_neutral", 3.0))
	match quality:
		"good":
			score = float(bal.get("date_score_correct", 1.6))
			bond = float(bal.get("bond_correct", 14.0))
		"bad":
			score = float(bal.get("date_score_wrong", 0.15))
			bond = float(bal.get("bond_wrong", -12.0))
	return {
		"id": str(raw.get("id", "%s_x" % card.get("id", "x"))),
		"label": str(raw.get("label", "...")),
		"interpret": str(raw.get("interpret", "")),
		"quality": quality,
		"trait": str(card.get("trait", "")),
		"base_score": score,
		"bond": bond,
		"prompt": str(card.get("observation", card.get("prompt", ""))),
	}


func _option_from_polarity(card: Dictionary, polarity: String) -> Dictionary:
	var src: Dictionary = card.get(polarity, {})
	var quality: String = str(src.get("quality", "ok"))
	if quality == "ok":
		match polarity:
			"correct":
				quality = "good"
			"wrong":
				quality = "bad"
			_:
				quality = "ok"
	var merged: Dictionary = src.duplicate(true)
	merged["quality"] = quality
	if not merged.has("interpret"):
		if polarity == "correct":
			merged["interpret"] = str(card.get("trait", ""))
		elif polarity == "wrong":
			merged["interpret"] = TraitsContent._alt_interpret(str(card.get("trait", "")))
		else:
			merged["interpret"] = ""
	return _option_from_interpret(card, merged)


func _knowledge_label(band: String) -> String:
	match band:
		"full":
			return "полное"
		"high":
			return "высокое"
		"medium":
			return "среднее"
		_:
			return "низкое"


func profile_hints(target_id: String, _unique: bool) -> PackedStringArray:
	var hints: PackedStringArray = PackedStringArray()
	var e: Dictionary = Game.girls.get_entry(StringName(target_id))
	var tier: String = Game.girls.girl_tier(StringName(target_id))
	hints.append("Тир: %s · связь %.0f%%" % [Loc.tier_name(tier), float(e.get("bond", 0.0))])
	hints.append("Знание: %s (%.0f%%)" % [
		_knowledge_label(Game.girls.knowledge_band(StringName(target_id))),
		Game.girls.automation_confidence(StringName(target_id)) * 100.0,
	])
	hints.append("Черты: %s" % Game.girls.known_traits_summary(StringName(target_id)))
	var quirk: String = Game.girls.girl_quirk(StringName(target_id))
	if not quirk.is_empty():
		hints.append("Особенность: %s" % TraitsContent.quirk_label(quirk))
	if ContentDB.girls.has(target_id):
		var author := str(ContentDB.girl(StringName(target_id)).get("bonus_desc", ""))
		if not author.is_empty():
			hints.append(author)
	return hints


func choose_manual(option_id: String) -> void:
	if active_manual.is_empty():
		return
	var options: Array = active_manual.get("options", [])
	var picked: Dictionary = {}
	for o in options:
		if str(o.get("id", "")) == option_id:
			picked = o
			break
	if picked.is_empty():
		return
	var quality: String = str(picked.get("quality", "ok"))
	var interpret: String = str(picked.get("interpret", ""))
	var trait_id: String = str(picked.get("trait", active_manual.get("phase_trait", "")))
	var observation_id: String = str(active_manual.get("card_id", picked.get("id", "")))
	var add: float = float(picked.get("base_score", 0.75))
	var bond_add: float = float(picked.get("bond", 0.0))
	if Game.upgrades.has_effect("bad_choice_mult") and quality == "bad":
		bond_add *= Game.upgrades.effect_value("bad_choice_mult", 1.0)
	var interp: Dictionary = Game.girls.apply_interpretation(
		StringName(str(active_manual.get("target_id", ""))),
		observation_id,
		interpret,
		trait_id,
		quality
	)
	active_manual["score"] = float(active_manual.get("score", 0)) + add
	active_manual["bond_delta"] = float(active_manual.get("bond_delta", 0)) + bond_add
	var bucket: String = "neutral"
	match quality:
		"good":
			bucket = "correct"
		"bad":
			bucket = "wrong"
	active_manual[bucket] = int(active_manual.get(bucket, 0)) + 1
	var emotion: StringName = &"happy"
	if quality == "good":
		emotion = &"delighted"
	elif quality == "bad":
		emotion = &"annoyed"
	active_manual["emotion"] = str(emotion)
	var choices: Array = active_manual.get("choices", [])
	choices.append({
		"choice_id": option_id,
		"quality": quality,
		"interpret": interpret,
		"trait": trait_id,
		"score": add,
		"bond_delta": bond_add,
		"hypothesis": bool(interp.get("hypothesis", false)),
		"confirmed": bool(interp.get("confirmed", false)),
		"rejected": bool(interp.get("rejected", false)),
		"status": str(interp.get("status", "")),
	})
	active_manual["choices"] = choices
	EventBus.notify.emit("DATE_EMOTION:%s" % str(emotion), &"date_fx")
	EventBus.notify.emit("DATE_CHOICE_DONE", &"date_fx")
	# Park beat side-effects (pay / rain handoff) before advancing phase.
	if bool(picked.get("park_beat", false)):
		_apply_park_beat_side_effects(picked)
		if bool(picked.get("handoff_restaurant", false)):
			handoff_active_place("restaurant")
			return
	if bool(picked.get("cinema_beat", false)):
		var genre := str(picked.get("genre", ""))
		if genre != "":
			active_manual["cinema_genre"] = genre
	if bool(picked.get("launch_arcade", false)):
		EventBus.notify.emit("ARCADE_OPEN_DATE:%s" % str(active_manual.get("target_id", "")), &"ui")
		return
	active_manual["phase"] = int(active_manual.get("phase", 0)) + 1
	var max_phases: int = _manual_max_phases()
	if int(active_manual["phase"]) >= max_phases:
		active_manual["phases_done"] = true
		schedule.awaiting_finish = true
		date_ui_open.emit(_manual_payload())
		EventBus.toast("Диалоги закончены — можно завершить свидание", &"info")
	else:
		_emit_phase()


func _manual_max_phases() -> int:
	var prep_m: Dictionary = active_manual.get("prep", {})
	if bool(active_manual.get("park_flow", false)) and str(prep_m.get("place_id", "")) == "park":
		return 4
	if bool(active_manual.get("cinema_flow", false)) and str(prep_m.get("place_id", "")) == "cinema":
		return 3
	if bool(active_manual.get("arcade_flow", false)) and str(prep_m.get("place_id", "")) == "arcade":
		return 2
	return 2 if Game.upgrades.has_effect("fast_manual") else 3


func handoff_active_place(new_place_id: String) -> void:
	## Switch venue mid-date without resetting phases / score / choices.
	if active_manual.is_empty():
		return
	var place_def: Dictionary = DatePlaces.place(new_place_id)
	if place_def.is_empty():
		return
	var prep: Dictionary = active_manual.get("prep", {}).duplicate(true)
	prep["place_id"] = new_place_id
	prep["venue_id"] = str(place_def.get("venue_id", new_place_id))
	prep["place_quality"] = float(place_def.get("base_quality", prep.get("place_quality", 1.0)))
	var extra_cost: float = float(place_def.get("cost", 0))
	if extra_cost > 0.0:
		if not Game.economy.try_spend({"money": extra_cost}, &"venue_handoff"):
			EventBus.toast("Не хватает денег на ресторан — остаёмся в парке", &"warn")
			active_manual["phase"] = int(active_manual.get("phase", 0)) + 1
			if int(active_manual["phase"]) >= _manual_max_phases():
				active_manual["phases_done"] = true
				schedule.awaiting_finish = true
				date_ui_open.emit(_manual_payload())
			else:
				_emit_phase()
			return
	active_manual["prep"] = prep
	active_manual["park_flow"] = false
	active_manual["phase"] = int(active_manual.get("phase", 0)) + 1
	# Backdrop swap only — do not emit date_ui_open (would rebuild DateStage).
	EventBus.notify.emit("DATE_PLACE_HANDOFF:%s" % new_place_id, &"date_fx")
	EventBus.toast("Дождь! Уходим в ресторан — свидание продолжается", &"story")
	if int(active_manual["phase"]) >= _manual_max_phases():
		active_manual["phases_done"] = true
		schedule.awaiting_finish = true
		EventBus.toast("Диалоги закончены — можно завершить свидание", &"info")
	else:
		_emit_phase()


func _apply_park_beat_side_effects(picked: Dictionary) -> void:
	var cost: float = float(picked.get("money_cost", 0))
	if cost > 0.0:
		if not Game.economy.try_spend({"money": cost}, &"park_date"):
			EventBus.toast("Не хватило мелочи — жест скромнее", &"warn")
			active_manual["score"] = float(active_manual.get("score", 0)) - 0.2
		else:
			EventBus.toast(str(picked.get("pay_toast", "Оплачено")), &"money")
	var comfort: float = float(picked.get("comfort", 0))
	if comfort != 0.0:
		active_manual["score"] = float(active_manual.get("score", 0)) + comfort


func _build_park_beat_options(phase: int) -> Array:
	var weather := str(active_manual.get("weather", DatePlaces.current_weather()))
	var bal: Dictionary = ContentDB.balance
	var good_s: float = float(bal.get("date_score_correct", 1.6))
	var ok_s: float = float(bal.get("date_score_neutral", 0.75))
	var bad_s: float = float(bal.get("date_score_wrong", 0.15))
	var good_b: float = float(bal.get("bond_correct", 14.0))
	var ok_b: float = float(bal.get("bond_neutral", 3.0))
	var bad_b: float = float(bal.get("bond_wrong", -12.0))
	match phase:
		0:
			active_manual["prompt"] = "У пруда крякают утки. Она ждёт, бросишь ли ты крошки."
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "park_ducks"
			return [
				{"id": "park_duck_feed", "label": "Покормить уток рядом с ней", "quality": "good", "base_score": good_s, "bond": good_b, "park_beat": true, "interpret": "attention", "trait": "attention"},
				{"id": "park_duck_watch", "label": "Просто посмотреть вместе", "quality": "ok", "base_score": ok_s, "bond": ok_b, "park_beat": true, "interpret": "", "trait": "peace"},
				{"id": "park_duck_ignore", "label": "Увлечься телефоном", "quality": "bad", "base_score": bad_s, "bond": bad_b, "park_beat": true, "interpret": "", "trait": "attention"},
			]
		1:
			var treat := "кофе" if weather != "warm" else "мороженое"
			var cost := 8.0 if weather != "warm" else 10.0
			active_manual["prompt"] = "Киоск пахнет %s. Можно угостить — или пройти мимо." % treat
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "park_kiosk"
			return [
				{"id": "park_kiosk_buy", "label": "Купить ей %s (−%.0f$)" % [treat, cost], "quality": "good", "base_score": good_s, "bond": good_b, "park_beat": true, "money_cost": cost, "pay_toast": "Киоск: %s" % treat, "interpret": "gift", "trait": "attention"},
				{"id": "park_kiosk_share", "label": "Взять одно на двоих (−%.0f$)" % (cost * 0.5), "quality": "ok", "base_score": ok_s, "bond": ok_b, "park_beat": true, "money_cost": cost * 0.5, "pay_toast": "Поделились угощением", "interpret": "", "trait": "peace"},
				{"id": "park_kiosk_skip", "label": "Пройти мимо киоска", "quality": "ok", "base_score": ok_s * 0.7, "bond": ok_b * 0.5, "park_beat": true, "interpret": "", "trait": "thrift"},
			]
		2:
			active_manual["prompt"] = "У киоска сдают пледы. На траве будет уютнее — если не жадничать."
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "park_blanket"
			return [
				{"id": "park_blanket_rent", "label": "Арендовать плед (−12$)", "quality": "good", "base_score": good_s, "bond": good_b, "park_beat": true, "money_cost": 12.0, "comfort": 0.35, "pay_toast": "Плед в аренде", "interpret": "care", "trait": "care"},
				{"id": "park_blanket_jacket", "label": "Предложить свою куртку", "quality": "ok", "base_score": ok_s, "bond": ok_b + 2.0, "park_beat": true, "comfort": 0.15, "interpret": "", "trait": "sincere"},
				{"id": "park_blanket_skip", "label": "Сесть на траву как есть", "quality": "ok", "base_score": ok_s * 0.8, "bond": ok_b * 0.6, "park_beat": true, "interpret": "", "trait": "cheap"},
			]
		_:
			var raining := weather == "rain" or (int(Game.time.day) + int(active_manual.get("score", 0))) % 3 == 0
			if raining:
				active_manual["prompt"] = "Небо темнеет. Капли уже на ладони — можно уйти в ресторан у парка."
				active_manual["observation"] = str(active_manual["prompt"])
				active_manual["card_id"] = "park_rain"
				return [
					{"id": "park_rain_restaurant", "label": "Укрыться в ресторане (−90$)", "quality": "good", "base_score": good_s, "bond": good_b, "park_beat": true, "handoff_restaurant": true, "interpret": "care", "trait": "care"},
					{"id": "park_rain_tree", "label": "Переждать под деревом", "quality": "ok", "base_score": ok_s, "bond": ok_b, "park_beat": true, "interpret": "", "trait": "adventure"},
					{"id": "park_rain_run", "label": "Бежать домой под дождём", "quality": "bad", "base_score": bad_s, "bond": bad_b, "park_beat": true, "interpret": "", "trait": "chaos"},
				]
			active_manual["prompt"] = "Вечер в парке тихий. Можно закончить на тёплой ноте."
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "park_wrap"
			return [
				{"id": "park_wrap_sunset", "label": "Посмотреть на закат вместе", "quality": "good", "base_score": good_s, "bond": good_b, "park_beat": true, "interpret": "romance", "trait": "romance"},
				{"id": "park_wrap_chat", "label": "Поболтать ещё немного", "quality": "ok", "base_score": ok_s, "bond": ok_b, "park_beat": true, "interpret": "", "trait": "humor"},
				{"id": "park_wrap_end", "label": "Предложить закончить прогулку", "quality": "ok", "base_score": ok_s * 0.9, "bond": ok_b * 0.8, "park_beat": true, "interpret": "", "trait": "peace"},
			]


func resume_after_arcade() -> void:
	## Called when Pair Overload finishes during an arcade date.
	if active_manual.is_empty():
		return
	if not bool(active_manual.get("arcade_flow", false)):
		return
	active_manual["arcade_done"] = true
	active_manual["phase"] = int(active_manual.get("phase", 0)) + 1
	if int(active_manual["phase"]) >= _manual_max_phases():
		active_manual["phases_done"] = true
		schedule.awaiting_finish = true
		date_ui_open.emit(_manual_payload())
		EventBus.toast("Диалоги закончены — можно завершить свидание", &"info")
	else:
		_emit_phase()


func note_bookstore_browse(girl_id: String = "") -> void:
	## Observation hook when browsing bookstore during / near a date.
	var gid := girl_id
	if gid.is_empty() and not active_manual.is_empty():
		gid = str(active_manual.get("target_id", ""))
	if gid.is_empty() or Game.girls == null:
		return
	var sections := ["фантастика", "поэзия", "биографии", "комиксы"]
	var section := str(sections[randi() % sections.size()])
	var text := "В книжном она застряла у полки «%s» и листала медленно." % section
	Game.girls.add_observation(StringName(gid), "bookstore_%s" % section, text, "calm", "city")
	if not active_manual.is_empty():
		active_manual["score"] = float(active_manual.get("score", 0.0)) + 0.25
		active_manual["bond_delta"] = float(active_manual.get("bond_delta", 0.0)) + 2.0
	EventBus.toast("Заметка: любит раздел «%s»" % section, &"girl")


func _build_cinema_beat_options(phase: int) -> Array:
	var bal: Dictionary = ContentDB.balance
	var good_s: float = float(bal.get("date_score_correct", 1.6))
	var ok_s: float = float(bal.get("date_score_neutral", 0.75))
	var bad_s: float = float(bal.get("date_score_wrong", 0.15))
	var good_b: float = float(bal.get("bond_correct", 14.0))
	var ok_b: float = float(bal.get("bond_neutral", 3.0))
	var bad_b: float = float(bal.get("bond_wrong", -12.0))
	var genre := str(active_manual.get("cinema_genre", "romance"))
	match phase:
		0:
			active_manual["prompt"] = "Касса кино. Какой жанр возьмёте на сеанс?"
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "cinema_genre"
			return [
				{"id": "cine_romance", "label": "Романтика", "quality": "good", "base_score": good_s, "bond": good_b, "cinema_beat": true, "genre": "romance", "interpret": "romance", "trait": "romance"},
				{"id": "cine_comedy", "label": "Комедия", "quality": "ok", "base_score": ok_s, "bond": ok_b, "cinema_beat": true, "genre": "comedy", "interpret": "humor", "trait": "humor"},
				{"id": "cine_action", "label": "Экшен", "quality": "ok", "base_score": ok_s, "bond": ok_b * 0.9, "cinema_beat": true, "genre": "action", "interpret": "", "trait": "daring"},
				{"id": "cine_horror", "label": "Ужасы", "quality": "ok", "base_score": ok_s * 0.85, "bond": ok_b, "cinema_beat": true, "genre": "horror", "interpret": "", "trait": "chaos"},
			]
		1:
			active_manual["prompt"] = "Сеанс (%s). Она реагирует на экран — что делаешь?" % genre
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "cinema_watch_%s" % genre
			return [
				{"id": "cine_react_sync", "label": "Шепнуть реакцию в такт сцене", "quality": "good", "base_score": good_s, "bond": good_b, "cinema_beat": true, "interpret": "attention", "trait": "attention"},
				{"id": "cine_react_hold", "label": "Тихо держать руку", "quality": "ok", "base_score": ok_s, "bond": ok_b, "cinema_beat": true, "interpret": "romance", "trait": "romance"},
				{"id": "cine_react_phone", "label": "Проверить телефон", "quality": "bad", "base_score": bad_s, "bond": bad_b, "cinema_beat": true, "interpret": "", "trait": "attention"},
			]
		_:
			active_manual["prompt"] = "После титров — короткий разговор у выхода."
			active_manual["observation"] = str(active_manual["prompt"])
			active_manual["card_id"] = "cinema_talk"
			return [
				{"id": "cine_talk_scene", "label": "Обсудить любимую сцену", "quality": "good", "base_score": good_s, "bond": good_b, "cinema_beat": true, "interpret": "media", "trait": "media"},
				{"id": "cine_talk_joke", "label": "Пошутить про трейлер", "quality": "ok", "base_score": ok_s, "bond": ok_b, "cinema_beat": true, "interpret": "humor", "trait": "humor"},
				{"id": "cine_talk_rush", "label": "Торопить домой", "quality": "bad", "base_score": bad_s, "bond": bad_b, "cinema_beat": true, "interpret": "", "trait": "peace"},
			]


func _build_arcade_beat_options(phase: int) -> Array:
	var bal: Dictionary = ContentDB.balance
	var good_s: float = float(bal.get("date_score_correct", 1.6))
	var ok_s: float = float(bal.get("date_score_neutral", 0.75))
	var bad_s: float = float(bal.get("date_score_wrong", 0.15))
	var good_b: float = float(bal.get("bond_correct", 14.0))
	var ok_b: float = float(bal.get("bond_neutral", 3.0))
	var bad_b: float = float(bal.get("bond_wrong", -12.0))
	if phase <= 0 and not bool(active_manual.get("arcade_done", false)):
		active_manual["prompt"] = "Автомат «Парный перегруз» мигает. Сыграете вместе?"
		active_manual["observation"] = str(active_manual["prompt"])
		active_manual["card_id"] = "arcade_launch"
		return [
			{"id": "arcade_play", "label": "Запустить Парный перегруз", "quality": "good", "base_score": good_s * 0.5, "bond": good_b * 0.4, "launch_arcade": true, "interpret": "attention", "trait": "attention"},
			{"id": "arcade_watch", "label": "Пусть она играет, а ты болеешь", "quality": "ok", "base_score": ok_s, "bond": ok_b, "interpret": "", "trait": "peace"},
			{"id": "arcade_skip", "label": "Пройти мимо автомата", "quality": "bad", "base_score": bad_s, "bond": bad_b, "interpret": "", "trait": "media"},
		]
	active_manual["prompt"] = "После автомата — короткий разговор у выхода из аркады."
	active_manual["observation"] = str(active_manual["prompt"])
	active_manual["card_id"] = "arcade_talk"
	return [
		{"id": "arcade_talk_high", "label": "Похвалить её реакцию", "quality": "good", "base_score": good_s, "bond": good_b, "interpret": "attention", "trait": "attention"},
		{"id": "arcade_talk_rematch", "label": "Предложить реванш как-нибудь", "quality": "ok", "base_score": ok_s, "bond": ok_b, "interpret": "", "trait": "daring"},
		{"id": "arcade_talk_brag", "label": "Хвастаться своим счётом", "quality": "bad", "base_score": bad_s, "bond": bad_b, "interpret": "", "trait": "humor"},
	]


func can_give_date_gift() -> bool:
	if active_manual.is_empty():
		return false
	if bool(active_manual.get("gift_given", false)):
		return false
	return _has_giftable_inventory()


func _has_giftable_inventory() -> bool:
	for gid in Game.inventory.gift_counts.keys():
		if int(Game.inventory.gift_counts[gid]) > 0:
			return true
	var carried := str(Game.inventory.carried_item)
	if carried != "" and not carried.begins_with("food:") and not carried.begins_with("drink:"):
		return true
	return false


func give_date_gift(gift_id: StringName) -> bool:
	if not can_give_date_gift():
		EventBus.toast("Подарок уже вручён", &"info")
		return false
	if gift_id == &"":
		return false
	if not _consume_owned_gift(gift_id):
		return false
	var prep: Dictionary = active_manual.get("prep", {})
	prep["gift_id"] = str(gift_id)
	active_manual["prep"] = prep
	active_manual["gift_given"] = true
	schedule.gift_given_id = str(gift_id)
	EventBus.toast("Ты подарил: %s" % str(ContentDB.gift(gift_id).get("name", gift_id)), &"ok")
	date_ui_open.emit(_manual_payload())
	return true


func can_give_result_gift() -> bool:
	if last_result.is_empty():
		return false
	if bool(last_result.get("gift_given", false)):
		return false
	return _has_giftable_inventory()


func give_result_gift(gift_id: StringName) -> bool:
	## Post-date gift from the result panel (session already cleared).
	if not can_give_result_gift():
		EventBus.toast("Подарок уже вручён или недоступен", &"info")
		return false
	if gift_id == &"":
		return false
	if not _consume_owned_gift(gift_id):
		return false
	var target_id: String = str(last_result.get("target_id", ""))
	var gift_def: Dictionary = ContentDB.gift(gift_id)
	var bond_bonus: float = float(gift_def.get("quality", 1.0)) * 2.0
	if target_id != "" and not Game.girls.is_claimed(StringName(target_id)):
		Game.girls.add_bond(StringName(target_id), bond_bonus)
	last_result["gift_given"] = true
	last_result["gift_id"] = str(gift_id)
	var factors: Dictionary = last_result.get("factors", {})
	var gift_factor: Dictionary = factors.get("gift", {})
	gift_factor["id"] = str(gift_id)
	gift_factor["given"] = true
	gift_factor["label"] = str(gift_def.get("name", gift_id))
	gift_factor["score"] = float(gift_def.get("quality", 0.0))
	factors["gift"] = gift_factor
	last_result["factors"] = factors
	last_result["bond"] = float(last_result.get("bond", 0.0)) + bond_bonus
	EventBus.toast("Ты подарил: %s" % str(gift_def.get("name", gift_id)), &"ok")
	return true


func _consume_owned_gift(gift_id: StringName) -> bool:
	if Game.inventory.carried_item == gift_id:
		Game.inventory.consume_carried()
		return true
	if Game.inventory.gift_count(gift_id) > 0:
		Game.inventory.gift_counts[str(gift_id)] = Game.inventory.gift_count(gift_id) - 1
		Game.inventory.inventory_changed.emit()
		return true
	EventBus.toast("Нет такого подарка в инвентаре", &"warn")
	return false


func finish_manual() -> void:
	if active_manual.is_empty():
		return
	_finish_manual()


func _finish_manual() -> void:
	var prep: Dictionary = active_manual.get("prep", {})
	var target_id := str(active_manual.get("target_id", ""))
	var unique := bool(active_manual.get("unique", true))
	var base := float(active_manual.get("score", 0))
	base += _prep_score(target_id, unique, prep)
	base += Game.upgrades.effect_value("manual_quality")
	var grade: int = _grade_from_score(base)
	var bond_delta: float = float(active_manual.get("bond_delta", 0.0))
	var emotion: String = str(active_manual.get("emotion", "neutral"))
	var gift_already: bool = bool(active_manual.get("gift_given", false)) or str(prep.get("gift_id", "")) != ""
	var result: Dictionary = _apply_result(target_id, unique, prep, grade, true, bond_delta)
	result["factors"] = _result_factors(target_id, unique, prep, active_manual)
	result["punctuality"] = str(prep.get("punctuality_label", ""))
	result["place_id"] = str(prep.get("place_id", ""))
	result["emotion"] = emotion
	result["mood"] = emotion
	result["gift_given"] = gift_already
	result["gift_id"] = str(prep.get("gift_id", ""))
	result["correct"] = int(active_manual.get("correct", 0))
	result["wrong"] = int(active_manual.get("wrong", 0))
	result["neutral"] = int(active_manual.get("neutral", 0))
	var entry: Dictionary = Game.girls.get_entry(StringName(target_id))
	result["bond_total"] = float(entry.get("bond", 0.0))
	Game.facility.release_venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
	active_manual.clear()
	schedule.awaiting_finish = false
	schedule.gift_given_id = ""
	schedule._reset_table_keep_ware()
	date_ui_close.emit()
	last_result = result
	EventBus.date_finished.emit(result)
	_toast_factor_breakdown(result)


func _result_factors(target_id: String, unique: bool, prep: Dictionary, session: Dictionary) -> Dictionary:
	var total_choices: int = int(session.get("correct", 0)) + int(session.get("wrong", 0)) + int(session.get("neutral", 0))
	var dialog_ratio: float = 0.0
	if total_choices > 0:
		dialog_ratio = float(session.get("correct", 0)) / float(total_choices)
	var outfit_id := str(prep.get("outfit_id", "casual"))
	var outfit_def: Dictionary = ContentDB.outfit(StringName(outfit_id))
	var gift_id := str(prep.get("gift_id", ""))
	var gift_def: Dictionary = ContentDB.gift(StringName(gift_id)) if gift_id != "" else {}
	return {
		"dialogues": {
			"weight": 0.6,
			"correct": int(session.get("correct", 0)),
			"wrong": int(session.get("wrong", 0)),
			"neutral": int(session.get("neutral", 0)),
			"ratio": dialog_ratio,
			"label": "%d/%d удачных" % [
				int(session.get("correct", 0)),
				int(session.get("correct", 0)) + int(session.get("wrong", 0)) + int(session.get("neutral", 0)),
			],
		},
		"place": {
			"id": str(prep.get("place_id", "")),
			"quality": float(prep.get("place_quality", 0.0)),
			"homeware": int(prep.get("homeware_level", 0)),
			"label": str(DatePlaces.place(str(prep.get("place_id", ""))).get("name", prep.get("place_id", "?"))),
		},
		"punctuality": {
			"label": str(prep.get("punctuality_label", "—")),
			"score": float(prep.get("punctuality_score", 0.0)),
		},
		"outfit": {
			"id": outfit_id if outfit_id != "" else "casual",
			"label": str(outfit_def.get("name", outfit_id if outfit_id != "" else "casual")),
			"score": float(outfit_def.get("quality", 1.0)),
		},
		"gift": {
			"id": gift_id,
			"optional": true,
			"given": gift_id != "",
			"label": str(gift_def.get("name", "без подарка")) if gift_id != "" else "без подарка (ок)",
			"score": float(gift_def.get("quality", 0.0)) if gift_id != "" else 0.0,
		},
	}


func _toast_factor_breakdown(result: Dictionary) -> void:
	var factors: Dictionary = result.get("factors", {})
	if factors.is_empty():
		return
	var dlg: Dictionary = factors.get("dialogues", {})
	var place: Dictionary = factors.get("place", {})
	var punct: Dictionary = factors.get("punctuality", {})
	var gift: Dictionary = factors.get("gift", {})
	var outfit_v: Variant = factors.get("outfit", {})
	var outfit_label := "casual"
	if outfit_v is Dictionary:
		outfit_label = str((outfit_v as Dictionary).get("label", (outfit_v as Dictionary).get("id", "casual")))
	else:
		outfit_label = str(outfit_v) if str(outfit_v) != "" else "casual"
	var gift_line := str(gift.get("label", "без подарка (ок)"))
	var place_name := str(place.get("label", DatePlaces.place(str(place.get("id", ""))).get("name", place.get("id", "?"))))
	EventBus.toast("Факторы: диалоги %s · место %s · %s · образ %s · подарок: %s" % [
		str(dlg.get("label", "%d/%d" % [int(dlg.get("correct", 0)), int(dlg.get("correct", 0)) + int(dlg.get("wrong", 0)) + int(dlg.get("neutral", 0))])),
		place_name,
		str(punct.get("label", "?")),
		outfit_label,
		gift_line,
	], &"date")


func _prep_score(target_id: String, unique: bool, prep: Dictionary) -> float:
	var score := 0.0
	var gift_id: String = str(prep.get("gift_id", ""))
	var gift: Dictionary = ContentDB.gift(StringName(gift_id)) if gift_id != "" else {}
	var outfit: Dictionary = ContentDB.outfit(StringName(str(prep.get("outfit_id", "casual"))))
	var venue: Dictionary = ContentDB.venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
	# Dialogues already in base score; factors: place, punctuality, outfit, optional gift.
	var place_q: float = float(prep.get("place_quality", venue.get("quality", 1.0)))
	score += place_q * 0.35
	score += float(prep.get("punctuality_score", 0.5))
	score += float(outfit.get("quality", 1)) * 0.3
	if gift_id != "":
		score += float(gift.get("quality", 1)) * 0.4
		score += Game.upgrades.effect_value("gift_quality") * 0.2
	score += Game.upgrades.effect_value("venue_quality_all") * 0.2
	if Game.trait_influence != null:
		if gift_id != "":
			score += Game.trait_influence.prep_gift_score_mod(StringName(target_id), gift)
		score += Game.trait_influence.punctual_prep_bonus(StringName(target_id), venue)
		score += float(Game.trait_influence.branch_passive_effects().get("gift_quality_bonus", 0.0))
	var likes: Array = []
	var dislikes: Array = []
	if ContentDB.girls.has(target_id):
		var def: Dictionary = ContentDB.girl(StringName(target_id))
		likes = def.get("likes", [])
		dislikes = def.get("dislikes", [])
		if str(def.get("special_rule", "")) == "hate_cheap_outfit" and str(outfit.get("style", "")) in ["casual", "cheap"]:
			score -= 1.5
		if str(def.get("special_rule", "")) == "no_repeat_outfit" and str(prep.get("outfit_id", "")) == str(Game.inventory.last_outfit):
			score -= 1.0 * Game.upgrades.effect_value("repeat_penalty_mult", 1.0)
	else:
		var e: Dictionary = Game.girls.get_entry(StringName(target_id))
		likes = e.get("likes", [])
		dislikes = e.get("dislikes", [])
		for tid in Game.girls.girl_traits(StringName(target_id)):
			for tag in TraitsContent.TRAIT_PREP_TAGS.get(str(tid), []):
				if not likes.has(tag):
					likes.append(tag)
	var gift_tags: Array = gift.get("tags", []) if not gift.is_empty() else []
	var venue_tags: Array = venue.get("tags", [])
	for t in likes:
		if gift_tags.has(t) or venue_tags.has(t) or str(outfit.get("style", "")) == str(t):
			score += 0.8
	for t in dislikes:
		if gift_tags.has(t) or venue_tags.has(t):
			score -= 0.8
	score *= float(Game.girls.active_effects().get("outfit_mult", 1.0))
	return score


func _grade_from_score(score: float) -> int:
	if score < 1.5:
		return Grade.CATASTROPHE
	if score < 2.5:
		return Grade.FAIL
	if score < 3.8:
		return Grade.OK
	if score < 5.2:
		return Grade.SUCCESS
	return Grade.PERFECT


func _apply_result(target_id: String, unique: bool, prep: Dictionary, grade: int, manual: bool, bond_delta: float = 0.0) -> Dictionary:
	stats["total"] = int(stats.get("total", 0)) + 1
	var money := 0.0
	var pop := 0.0
	var rel := bond_delta
	var scandal := 0.0
	match grade:
		Grade.CATASTROPHE:
			stats["fail"] = int(stats["fail"]) + 1
			money = 2.0
			pop = 0.0
			scandal = 4.0
			if manual:
				rel -= 4.0
		Grade.FAIL:
			stats["fail"] = int(stats["fail"]) + 1
			money = 5.0
			pop = 0.5
			scandal = 2.0
		Grade.OK:
			money = 12.0
			pop = 1.5
			scandal = 0.0
		Grade.SUCCESS:
			stats["success"] = int(stats["success"]) + 1
			Game.total_successful_dates += 1
			money = 22.0
			pop = 3.0
			scandal = 0.0
		Grade.PERFECT:
			stats["perfect"] = int(stats["perfect"]) + 1
			stats["success"] = int(stats["success"]) + 1
			Game.total_successful_dates += 1
			money = 35.0
			pop = 5.0
			scandal = 0.0
	var tier_mult: float = Game.girls.reward_mult(StringName(target_id))
	money *= tier_mult
	pop *= tier_mult
	var effects: Dictionary = Game.girls.active_effects()
	money *= float(effects.get("money_mult", 1.0))
	pop *= float(effects.get("event_pop_mult", 1.0))
	if manual:
		pop += Game.upgrades.effect_value("first_date_pop")
	# special rules
	if unique:
		var rule := str(ContentDB.girl(StringName(target_id)).get("special_rule", ""))
		if rule == "fail_can_pop" and grade <= Grade.FAIL:
			pop += 6.0
			EventBus.toast("Провал стал контентом!", &"media")
		if rule == "big_scandal_on_fail" and grade <= Grade.FAIL:
			scandal += 6.0
		if rule == "needs_imperfection" and grade == Grade.PERFECT:
			rel *= 0.5
		if float(effects.get("scandal_to_pop", 0)) > 0.0 and scandal > 0.0:
			pop += scandal * float(effects.get("scandal_to_pop", 0))
	if str(ContentDB.venue(StringName(str(prep.get("venue_id", "")))).get("id", "")) == "photo_studio":
		pop += 2.0
		scandal += 1.0
	if Game.trait_influence != null:
		money = Game.trait_influence.on_date_money_earned(money)
	Game.economy.add(&"money", money, &"date")
	Game.economy.add(&"popularity", pop, &"date")
	var scandal_mult: float = Game.upgrades.effect_value("scandal_penalty_mult", 1.0) * float(effects.get("scandal_penalty_mult", 1.0))
	if Game.trait_influence != null:
		scandal_mult *= Game.trait_influence.scandal_mult_for_date(StringName(target_id))
	Game.economy.add(&"scandal", scandal * scandal_mult, &"date")
	# Thrift branch C: partial gift value refund on fail.
	if grade <= Grade.FAIL and Game.trait_influence != null:
		var refund_ratio: float = float(Game.trait_influence.branch_passive_effects().get("fail_resource_refund", 0.0))
		if refund_ratio > 0.0:
			var gift_price: float = float(ContentDB.gift(StringName(str(prep.get("gift_id", "")))).get("price", 0.0))
			var back: float = gift_price * refund_ratio
			if back > 0.0:
				Game.economy.add(&"money", back, &"thrift_branch_c")
				EventBus.toast("Экономность C: возврат %.0f$ за подарок" % back, &"ok")
	if not Game.girls.is_claimed(StringName(target_id)):
		if not manual and rel == 0.0:
			rel = _auto_bond_from_knowledge(StringName(target_id))
		Game.girls.add_bond(StringName(target_id), rel)
	var grade_name: String = str(["катастрофа", "неудача", "нормально", "успешно", "идеально"][grade])
	var result: Dictionary = {
		"target_id": target_id,
		"unique": unique,
		"grade": grade,
		"grade_name": grade_name,
		"money": money,
		"popularity": pop,
		"relation": rel,
		"bond": rel,
		"scandal": scandal,
		"manual": manual,
		"tier_mult": tier_mult,
	}
	EventBus.toast("Свидание: %s (+%d$ / +%.1f pop / связь %+.0f)" % [grade_name, int(money), pop, rel], &"date")
	Game.girls.refresh_candidates()
	Game.quests.on_date_finished(result)
	Game.events.maybe_trigger_after_date(result)
	Game.facility.check_stage_gates()
	return result


func enqueue_auto(target: Dictionary, prep: Dictionary) -> void:
	auto_queue.append({"target": target, "prep": prep, "wait": float(ContentDB.balance.get("auto_date_seconds", 12))})


func _process(delta: float) -> void:
	if not Game.run_started:
		return
	if schedule != null:
		schedule.update_arrival_flags()
		schedule.tick_reminders()
		# Home: once seated in the arrive window, kick vignette (no doorbell).
		if (
			active_manual.is_empty()
			and schedule.has_booking()
			and schedule.is_home()
			and schedule.girl_arrived
			and schedule.player_seated
		):
			InteractionRouter.try_auto_start_seated_home_date()
	_process_autos(delta)
	_staff_automation(delta)
	# attention regen
	var regen: float = 0.05 * delta + float(Game.girls.active_effects().get("attention_regen", 0.0)) * delta
	if Game.economy.get_value(&"attention") < Game.economy.max_attention:
		Game.economy.add(&"attention", regen, &"regen")
	# scandal passive decay from PR
	var decay: float = Game.upgrades.effect_value("scandal_decay") * delta
	if decay > 0.0 and Game.economy.get_value(&"scandal") > 0.0:
		Game.economy.add(&"scandal", -decay, &"pr")
		var convert: float = Game.upgrades.effect_value("scandal_to_pop") + float(Game.girls.active_effects().get("scandal_to_pop", 0))
		if convert > 0.0:
			Game.economy.add(&"popularity", decay * convert, &"pr")


var _auto_timer: float = 0.0


func _staff_automation(delta: float) -> void:
	_auto_timer += delta
	if _auto_timer < 2.0:
		return
	_auto_timer = 0.0
	if Game.staff.has_effect("auto_buy_gifts") or Game.upgrades.has_effect("auto_buy_gifts"):
		_auto_buy_basic_gift()
	if automation_level >= 1 and Game.staff.has_effect("auto_assign_dates"):
		_auto_schedule()
	elif automation_level >= 3 or Game.upgrades.has_effect("full_auto_dates"):
		_auto_schedule()


func _auto_buy_basic_gift() -> void:
	if Game.inventory.gift_count(&"flower") + Game.inventory.gift_count(&"candy") >= 4:
		return
	if Game.inventory.can_buy_gift(&"flower"):
		Game.inventory.buy_gift(&"flower")


func _auto_schedule() -> void:
	if active_autos.size() >= 1 + int(Game.upgrades.effect_value("extra_lines")) + int(Game.upgrades.effect_value("global_capacity")):
		return
	Game.girls.refresh_candidates()
	for c in Game.girls.candidates:
		if str(c.get("kind", "")) != "proc" and bool(Game.girls.get_entry(StringName(str(c.get("id", "")))).get("met", false)) == false:
			continue
		# only repeats for unique
		if str(c.get("kind", "")) == "unique":
			var e: Dictionary = Game.girls.get_entry(StringName(str(c.get("id", ""))))
			if not bool(e.get("met", false)):
				continue
		var tid_c := StringName(str(c.get("id", "")))
		if not Game.girls.allows_auto_date(tid_c):
			continue
		if auto_risk_mode == "careful" and Game.girls.automation_confidence(tid_c) < 0.35:
			continue
		var gift_id: StringName = _pick_gift_for(c)
		if gift_id == &"":
			EventBus.bottleneck.emit(&"gifts", "Нет подарков для автолинии")
			return
		var venue_id: StringName = _pick_venue()
		var outfit_id: StringName = Game.inventory.equipped_outfit
		if Game.staff.has_effect("auto_outfit") or Game.upgrades.has_effect("auto_outfit"):
			outfit_id = Game.inventory.auto_pick_outfit_for(c.get("likes", []))
		var prep: Dictionary = {"gift_id": str(gift_id), "venue_id": str(venue_id), "outfit_id": str(outfit_id), "extra": ""}
		if Game.inventory.gift_count(gift_id) <= 0:
			continue
		Game.inventory.gift_counts[str(gift_id)] = Game.inventory.gift_count(gift_id) - 1
		var wait: float = float(ContentDB.balance.get("auto_date_seconds", 12)) * Game.upgrades.effect_value("date_time_mult", 1.0)
		if Game.trait_influence != null:
			wait *= float(Game.trait_influence.branch_passive_effects().get("auto_date_time_mult", 1.0))
		var actor := "manager"
		if automation_level >= 2 and Game.clones.available_count() > 0:
			actor = Game.clones.assign_to_date()
		if not Game.facility.reserve_venue(venue_id):
			# Slot taken mid-pick — try next candidate cycle.
			if actor.begins_with("clone"):
				Game.clones.finish_date(actor)
			Game.inventory.gift_counts[str(gift_id)] = Game.inventory.gift_count(gift_id) + 1
			continue
		var entry := {"target": c, "prep": prep, "wait": wait, "actor": actor, "venue_id": str(venue_id)}
		active_autos.append(entry)
		_mark_auto_occupancy(entry, true)
		if actor.begins_with("clone"):
			_sync_parallel_risk(str(venue_id), actor)
		break
	auto_date_tick.emit(active_autos.size())


func _pick_gift_for(c: Dictionary) -> StringName:
	var likes: Array = c.get("likes", [])
	var tid := StringName(str(c.get("id", "")))
	if str(c.get("kind", "")) == "unique":
		likes = ContentDB.girl(tid).get("likes", [])
	if Game.trait_influence != null and Game.trait_influence.has_active_synergy("precise_gift"):
		var precise: StringName = Game.trait_influence.pick_precise_gift(likes)
		if precise != &"":
			return precise
	var avoid_luxury: bool = Game.trait_influence != null and Game.trait_influence.auto_avoid_empty_luxury()
	var thrift_target: bool = Game.trait_influence != null and Game.trait_influence.girl_has_primary(tid, "thrift")
	# 1) Exact like match (skip empty luxury when thrift@3).
	for gid in Game.inventory.gift_counts.keys():
		if int(Game.inventory.gift_counts[gid]) <= 0:
			continue
		var gdef: Dictionary = ContentDB.gift(StringName(str(gid)))
		if avoid_luxury and thrift_target and Game.trait_influence.is_empty_luxury_gift(gdef, likes):
			continue
		var tags: Array = gdef.get("tags", [])
		for t in likes:
			if tags.has(t):
				return StringName(str(gid))
	# 2) Value-oriented fallback for thrift orbit rule.
	if avoid_luxury and thrift_target:
		for gid2 in Game.inventory.gift_counts.keys():
			if int(Game.inventory.gift_counts[gid2]) <= 0:
				continue
			var g2: Dictionary = ContentDB.gift(StringName(str(gid2)))
			if Game.trait_influence.is_empty_luxury_gift(g2, likes):
				continue
			if Game.trait_influence.gift_matches_value(g2, likes):
				return StringName(str(gid2))
	for gid3 in Game.inventory.gift_counts.keys():
		if int(Game.inventory.gift_counts[gid3]) <= 0:
			continue
		var g3: Dictionary = ContentDB.gift(StringName(str(gid3)))
		if avoid_luxury and thrift_target and Game.trait_influence.is_empty_luxury_gift(g3, likes):
			continue
		return StringName(str(gid3))
	return &""


func _pick_venue() -> StringName:
	var unlocked: Array = Game.facility.unlocked_venues
	# prefer higher capacity unlocked
	var best := &"kitchen_table"
	var best_cap := 0
	for v in unlocked:
		var def: Dictionary = ContentDB.venue(v)
		var cap: int = int(def.get("capacity", 1))
		if Game.facility.venue_used(v) < cap and cap >= best_cap:
			best = v
			best_cap = cap
	return best


func _process_autos(delta: float) -> void:
	if active_autos.is_empty():
		return
	var remain: Array = []
	for a in active_autos:
		a["wait"] = float(a.get("wait", 1)) - delta
		if float(a["wait"]) > 0.0:
			remain.append(a)
			continue
		_finish_auto(a)
	active_autos = remain
	auto_date_tick.emit(active_autos.size())


func _finish_auto(a: Dictionary) -> void:
	var target: Dictionary = a.get("target", {})
	var prep: Dictionary = a.get("prep", {})
	var unique := str(target.get("kind", "")) == "unique"
	var target_id := str(target.get("id", ""))
	if Game.girls.is_claimed(StringName(target_id)):
		return
	var conf: float = Game.girls.automation_confidence(StringName(target_id))
	if Game.trait_influence != null:
		conf = clampf(conf + Game.trait_influence.auto_confidence_bonus(StringName(target_id)), 0.05, 1.0)
	var score := 1.6 + _prep_score(target_id, unique, prep) + conf * 2.2
	match auto_risk_mode:
		"careful":
			score += conf * 0.4
			if conf < 0.35:
				score -= 0.8
		"risk":
			score += lerpf(-0.6, 0.9, conf)
		_:
			pass
	score += Game.upgrades.effect_value("clone_quality")
	var actor := str(a.get("actor", "manager"))
	if actor.begins_with("clone"):
		var err: StringName = Game.clones.roll_error()
		if err != &"":
			score -= 1.5
			Game.economy.add(&"scandal", 1.5 * Game.upgrades.effect_value("clone_error_mult", 1.0), &"clone_err")
			# Clone slip hits legend integrity separately from scandal noise.
			Game.economy.damage_legend(2.5 * Game.upgrades.effect_value("clone_error_mult", 1.0), &"clone_err")
			EventBus.toast("Дубль ошибся: %s" % str(err), &"warn")
		Game.clones.finish_date(actor)
	var grade: int = _grade_from_score(score)
	_apply_result(target_id, unique, prep, grade, false, 0.0)
	var vid := StringName(str(a.get("venue_id", prep.get("venue_id", "kitchen_table"))))
	_mark_auto_occupancy(a, false)
	Game.facility.release_venue(vid)


func _mark_auto_occupancy(entry: Dictionary, occupy: bool) -> void:
	if schedule == null:
		return
	var venue := str(entry.get("venue_id", entry.get("prep", {}).get("venue_id", "")))
	var place := DateSchedule.venue_to_place(venue)
	if place == "":
		return
	var day := 1
	if Game.time != null:
		day = int(Game.time.day)
	var lead := "clone" if str(entry.get("actor", "")).begins_with("clone") else "manager"
	var girl_id := str(entry.get("target", {}).get("id", ""))
	if occupy:
		var conflict: Dictionary = schedule.slot_conflict(place, day, -1, lead)
		if not conflict.is_empty() and str(conflict.get("lead", "")) == "player":
			EventBus.toast("Автолиния: конфликт с бронью игрока @ %s" % place, &"warn")
		schedule.overwrite_occupancy(place, day, -1, lead, girl_id)
	else:
		schedule.release_occupancy(place, day, -1, lead)


func has_active_clone_date() -> bool:
	for a in active_autos:
		if str(a.get("actor", "")).begins_with("clone"):
			return true
	return false


func raise_automation(level: int) -> void:
	automation_level = maxi(automation_level, level)


func _mark_parallel_done() -> void:
	parallel_runs += 1
	Game.quests.complete("s4_parallel")
	Game.facility.set_flag("stage_4c", true)


func venue_route(venue_id: String) -> String:
	return str(ContentDB.venue(StringName(venue_id)).get("route", "home"))


func _find_clone_overlap(venue_id: String) -> Dictionary:
	## Returns first overlapping clone auto (same venue or same route), else {}.
	var route: String = venue_route(venue_id)
	for a in active_autos:
		var actor := str(a.get("actor", ""))
		if not actor.begins_with("clone"):
			continue
		var av := str(a.get("venue_id", a.get("prep", {}).get("venue_id", "")))
		if av == venue_id:
			return {"kind": "venue", "auto": a, "venue_id": av, "route": venue_route(av)}
		if venue_route(av) == route and route != "":
			return {"kind": "route", "auto": a, "venue_id": av, "route": route}
	# Player manual vs this auto's venue (when spawning clone line).
	if not active_manual.is_empty():
		var mv := str(active_manual.get("prep", {}).get("venue_id", ""))
		if mv == venue_id:
			return {"kind": "venue", "auto": {}, "venue_id": mv, "route": venue_route(mv), "with_player": true}
		if venue_route(mv) == route and route != "":
			return {"kind": "route", "auto": {}, "venue_id": mv, "route": route, "with_player": true}
	return {}


func _sync_parallel_risk(venue_id: String, actor: String) -> void:
	## Player+double or double+double on same hall/route → managed collision.
	var hit: Dictionary = {}
	if actor == "player":
		hit = _find_clone_overlap(venue_id)
	elif actor.begins_with("clone"):
		# Check against other clone autos + player.
		hit = _find_clone_overlap(venue_id)
		# Exclude self: if we just appended, overlap may be ourselves — filter.
		var self_count := 0
		for a in active_autos:
			if str(a.get("actor", "")) == actor:
				self_count += 1
		if self_count <= 1 and hit.get("auto", {}).get("actor", "") == actor and not bool(hit.get("with_player", false)):
			# Only collided with self — check player only.
			if active_manual.is_empty():
				return
			var mv := str(active_manual.get("prep", {}).get("venue_id", ""))
			var route := venue_route(venue_id)
			if mv != venue_id and venue_route(mv) != route:
				return
			hit = {"kind": "venue" if mv == venue_id else "route", "auto": {}, "venue_id": mv, "route": route, "with_player": true}
	else:
		return
	if hit.is_empty():
		return
	_resolve_parallel_collision(hit)


func _resolve_parallel_collision(hit: Dictionary) -> void:
	last_collision = hit.duplicate(true)
	var kind := str(hit.get("kind", "route"))
	var route := str(hit.get("route", ""))
	var blurb := "Два «ты» почти пересеклись на маршруте %s." % route
	if kind == "venue":
		blurb = "Два «ты» оказались у одного места (%s)." % str(hit.get("venue_id", ""))
	match auto_risk_mode:
		"careful":
			_safe_reroute_overlap(hit)
			_mark_parallel_done()
			EventBus.toast("Параллель: маршрут дубля сдвинут, встреча предотвращена", &"ok")
		"risk":
			# Allow overlap — legend takes a hit, still counts as parallel run.
			Game.economy.damage_legend(5.0, &"parallel_meet")
			Game.economy.add(&"scandal", 1.5, &"parallel_meet")
			_mark_parallel_done()
			EventBus.toast("Риск встречи: легенда дрогнула", &"warn")
		_:
			# Standard: player chooses via runtime event (or auto-safe if UI blocked).
			var opened: bool = Game.events.open_runtime_event({
				"id": "parallel_collision",
				"name": "Риск параллели",
				"blurb": blurb + " Как поступишь?",
				"choices": [
					{"id": "reroute", "label": "Сдвинуть маршрут дубля", "scandal": 0.0, "legend": 0.0, "money": -10.0},
					{"id": "delay", "label": "Задержать дубль", "scandal": 0.0, "legend": 0.5, "money": 0.0},
					{"id": "risk_it", "label": "Идти на риск", "scandal": 2.0, "legend": -6.0, "money": 0.0},
				],
			})
			if opened:
				# Wire choice side-effects after choose via pending flag.
				last_collision["awaiting_choice"] = true
			else:
				_safe_reroute_overlap(hit)
				EventBus.toast("Параллель: автосдвиг маршрута (UI занят)", &"info")
			_mark_parallel_done()


func apply_parallel_choice(choice_id: String) -> void:
	## Called from EventsAPI.choose when last_collision awaiting.
	if not bool(last_collision.get("awaiting_choice", false)):
		return
	last_collision["awaiting_choice"] = false
	match choice_id:
		"reroute", "delay":
			_safe_reroute_overlap(last_collision)
			if choice_id == "delay":
				for a in active_autos:
					if str(a.get("actor", "")).begins_with("clone"):
						a["wait"] = float(a.get("wait", 1.0)) + 8.0
		_:
			pass


func _safe_reroute_overlap(hit: Dictionary) -> void:
	var blocked_route := str(hit.get("route", ""))
	var blocked_venue := str(hit.get("venue_id", ""))
	for i in range(active_autos.size()):
		var a: Dictionary = active_autos[i]
		if not str(a.get("actor", "")).begins_with("clone"):
			continue
		var av := str(a.get("venue_id", a.get("prep", {}).get("venue_id", "")))
		if av != blocked_venue and venue_route(av) != blocked_route:
			continue
		# Release old slot, pick another unlocked venue on a different route.
		Game.facility.release_venue(StringName(av))
		var alt := _pick_venue_avoiding(blocked_route, blocked_venue)
		if Game.facility.reserve_venue(alt):
			a["venue_id"] = str(alt)
			var prep: Dictionary = a.get("prep", {})
			prep["venue_id"] = str(alt)
			a["prep"] = prep
			a["wait"] = float(a.get("wait", 1.0)) + 3.0
		else:
			# Hold in place longer if no alt.
			Game.facility.reserve_venue(StringName(av))
			a["wait"] = float(a.get("wait", 1.0)) + 10.0
		active_autos[i] = a


func _pick_venue_avoiding(blocked_route: String, blocked_venue: String) -> StringName:
	var unlocked: Array = Game.facility.unlocked_venues
	var best := &"kitchen_table"
	var best_cap := -1
	for v in unlocked:
		var sid := str(v)
		if sid == blocked_venue:
			continue
		if venue_route(sid) == blocked_route:
			continue
		var def: Dictionary = ContentDB.venue(v)
		var cap: int = int(def.get("capacity", 1))
		if Game.facility.venue_used(v) < cap and cap >= best_cap:
			best = v if v is StringName else StringName(sid)
			best_cap = cap
	return best


func set_auto_risk_mode(mode: String) -> void:
	if mode in ["careful", "standard", "risk"]:
		auto_risk_mode = mode
		EventBus.toast("Режим авто: %s" % _auto_mode_ru(), &"info")


func cycle_auto_risk_mode() -> String:
	match auto_risk_mode:
		"careful":
			auto_risk_mode = "standard"
		"standard":
			auto_risk_mode = "risk"
		_:
			auto_risk_mode = "careful"
	EventBus.toast("Режим авто: %s" % _auto_mode_ru(), &"info")
	return auto_risk_mode


func _auto_mode_ru() -> String:
	match auto_risk_mode:
		"careful":
			return "осторожный"
		"risk":
			return "рисковый"
		_:
			return "стандарт"


func _auto_bond_from_knowledge(target_id: StringName) -> float:
	var conf: float = Game.girls.automation_confidence(target_id)
	var success_chance: float = conf
	match auto_risk_mode:
		"careful":
			success_chance = conf * 0.75
			if conf < 0.35:
				# Careful refuses to improvise hard — weak safe bond.
				return float(ContentDB.balance.get("bond_neutral", 3.0)) * 0.4
		"risk":
			success_chance = clampf(conf * 1.25 + 0.1, 0.05, 0.95)
		_:
			pass
	if randf() < success_chance:
		var mult: float = lerpf(0.2, 0.55, conf)
		if auto_risk_mode == "risk":
			mult *= 1.15
		return float(ContentDB.balance.get("bond_correct", 14.0)) * mult
	var fail_mult: float = lerpf(0.35, 0.1, conf)
	if auto_risk_mode == "risk":
		fail_mult *= 1.35
	elif auto_risk_mode == "careful":
		fail_mult *= 0.6
	return float(ContentDB.balance.get("bond_wrong", -12.0)) * fail_mult


func to_dict() -> Dictionary:
	return {
		"prepared": prepared.duplicate(true),
		"stats": stats.duplicate(),
		"automation_level": automation_level,
		"auto_risk_mode": auto_risk_mode,
		"parallel_runs": parallel_runs,
		"schedule": schedule.to_dict() if schedule != null else {},
	}


func from_dict(data: Dictionary) -> void:
	prepared = data.get("prepared", {})
	stats = data.get("stats", stats)
	automation_level = int(data.get("automation_level", 0))
	auto_risk_mode = str(data.get("auto_risk_mode", "standard"))
	parallel_runs = int(data.get("parallel_runs", 0))
	if schedule == null:
		schedule = DateSchedule.new()
	schedule.from_dict(data.get("schedule", {}))
	active_manual.clear()
	active_autos.clear()
