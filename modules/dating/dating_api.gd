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


func set_prep(target_id: String, gift_id: StringName, venue_id: StringName, outfit_id: StringName, extra: StringName = &"") -> void:
	prepared[target_id] = {
		"gift_id": str(gift_id),
		"venue_id": str(venue_id),
		"outfit_id": str(outfit_id),
		"extra": str(extra),
	}


func get_prep(target_id: String) -> Dictionary:
	return prepared.get(target_id, {}).duplicate(true)


func can_start_manual(target_id: String) -> bool:
	if not active_manual.is_empty():
		return false
	if Game.economy.get_value(&"attention") < 1.0:
		EventBus.bottleneck.emit(&"attention", "Не хватает внимания")
		return false
	var prep := get_prep(target_id)
	if prep.is_empty():
		EventBus.toast("Сначала подготовь свидание (подарок/образ/место)", &"warn")
		return false
	var venue := ContentDB.venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
	if not Game.facility.is_venue_unlocked(StringName(str(venue.get("id", "kitchen_table")))):
		EventBus.toast("Место ещё не открыто", &"warn")
		return false
	if not Game.facility.reserve_venue(StringName(str(venue.get("id", "kitchen_table")))):
		EventBus.bottleneck.emit(&"venue", "Место занято")
		return false
	return true


func start_manual(target_id: String, is_unique: bool = true) -> bool:
	if not can_start_manual(target_id):
		return false
	var prep := get_prep(target_id)
	var venue_cost: float = float(ContentDB.venue(StringName(str(prep.get("venue_id", "kitchen_table")))).get("cost", 0))
	venue_cost *= Game.upgrades.effect_value("venue_cost_mult", 1.0)
	var effects: Dictionary = Game.girls.active_effects()
	venue_cost *= float(effects.get("date_cost_mult", 1.0))
	if venue_cost > 0.0 and not Game.economy.try_spend({"money": venue_cost}, &"venue"):
		Game.facility.release_venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
		EventBus.toast("Не хватает денег на место", &"warn")
		return false
	Game.economy.add(&"attention", -1.0, &"manual_date")
	# consume gift from stock or carried
	var gift_id := StringName(str(prep.get("gift_id", "")))
	if Game.inventory.carried_item == gift_id:
		Game.inventory.consume_carried()
	elif Game.inventory.gift_count(gift_id) > 0:
		Game.inventory.gift_counts[str(gift_id)] = Game.inventory.gift_count(gift_id) - 1
		Game.inventory.inventory_changed.emit()
	else:
		EventBus.toast("Нет подарка", &"warn")
		Game.facility.release_venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
		Game.economy.add(&"attention", 1.0, &"refund")
		return false

	active_manual = {
		"target_id": target_id,
		"unique": is_unique,
		"prep": prep,
		"phase": 0,
		"score": 0.0,
		"choices": [],
	}
	if is_unique:
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
		"emotion": str(active_manual.get("emotion", "neutral")),
	}


func _target_title(id: String, unique: bool) -> String:
	if unique:
		return Game.girls.display_name(StringName(id))
	return id


func _emit_phase() -> void:
	var phase := int(active_manual.get("phase", 0))
	var target_id := str(active_manual.get("target_id", ""))
	var unique := bool(active_manual.get("unique", true))
	var options: Array = _build_phase_options(phase, target_id, unique)
	active_manual["options"] = options
	date_phase.emit(phase, options)


func _build_phase_options(phase: int, target_id: String, unique: bool) -> Array:
	var likes: Array = []
	var dislikes: Array = []
	var tags: Array = []
	if ContentDB.girls.has(target_id):
		var def := ContentDB.girl(StringName(target_id))
		likes = def.get("likes", [])
		dislikes = def.get("dislikes", [])
		tags = def.get("tags", [])
	else:
		var e: Dictionary = Game.girls.get_entry(StringName(target_id))
		likes = e.get("likes", ["sincere", "cheap"])
		dislikes = e.get("dislikes", [])
	var pool: Array = []
	match phase:
		0:
			pool = [
				{"id": "sincere_hello", "label": "Искренне поприветствовать", "tags": ["sincere", "calm", "cheap"]},
				{"id": "compliment", "label": "Сделать комплимент внешности", "tags": ["fashion", "romantic", "media"]},
				{"id": "boast", "label": "Похвастаться популярностью", "tags": ["media", "luxury", "scandal"]},
				{"id": "sport_energy", "label": "Предложить активный тон", "tags": ["sport", "useful", "active"]},
				{"id": "dark_joke", "label": "Мрачная шутка", "tags": ["dark", "weird", "chaos", "scandal"]},
				{"id": "tech_smalltalk", "label": "Заговорить о технологиях", "tags": ["tech", "science", "space"]},
			]
		1:
			pool = [
				{"id": "listen", "label": "Слушать внимательно", "tags": ["sincere", "calm", "order"]},
				{"id": "upgrade_food", "label": "Заказать подороже", "tags": ["luxury", "tasty", "business"]},
				{"id": "change_topic", "label": "Сменить тему на лёгкую", "tags": ["casual", "cheap", "media"]},
				{"id": "share_plan", "label": "Рассказать план на вечер", "tags": ["order", "business", "science"]},
				{"id": "weird_story", "label": "Рассказать странную историю", "tags": ["weird", "dark", "chaos", "space"]},
				{"id": "train_talk", "label": "Поговорить о тренировках", "tags": ["sport", "useful"]},
			]
		_:
			pool = [
				{"id": "gift", "label": "Вручить подарок с теплотой", "tags": ["sincere", "romantic", "cheap"]},
				{"id": "gift_flex", "label": "Вручить подарок как трофей", "tags": ["luxury", "media", "business"]},
				{"id": "fix", "label": "Исправить мелкую проблему", "tags": ["order", "useful", "tech"]},
				{"id": "selfie", "label": "Предложить селфи/контент", "tags": ["media", "fashion", "scandal"]},
				{"id": "quiet_end", "label": "Завершить спокойно", "tags": ["calm", "sincere"]},
				{"id": "chaos_end", "label": "Завершить абсурдно", "tags": ["chaos", "weird", "absurd", "space"]},
			]
	# Score each option vs profile and pick 3 diverse ones
	var scored: Array = []
	for o in pool:
		var s: float = _option_fit(o.get("tags", []), likes, dislikes, tags)
		var copy: Dictionary = o.duplicate(true)
		copy["base_score"] = s
		copy["hint"] = _fit_hint(s)
		scored.append(copy)
	scored.sort_custom(func(a, b): return float(a.get("base_score", 0)) > float(b.get("base_score", 0)))
	# Always include best, worst-ish, and a mid option so player can learn
	var out: Array = []
	if scored.size() >= 1:
		out.append(scored[0])
	if scored.size() >= 3:
		out.append(scored[int(scored.size() / 2)])
		out.append(scored[scored.size() - 1])
	elif scored.size() == 2:
		out.append(scored[1])
	# Shuffle display order so best isn't always first
	out.shuffle()
	for o2 in out:
		o2["label"] = "%s  (%s)" % [str(o2.get("label", "")), str(o2.get("hint", ""))]
	return out


func _option_fit(opt_tags: Array, likes: Array, dislikes: Array, girl_tags: Array) -> float:
	var score := 0.6
	for t in opt_tags:
		if likes.has(t):
			score += 0.7
		if dislikes.has(t):
			score -= 0.8
		if girl_tags.has(t):
			score += 0.25
	return score


func _fit_hint(score: float) -> String:
	if score >= 1.6:
		return "похоже, зайдёт"
	if score >= 0.9:
		return "нейтрально"
	return "рискованно"


func profile_hints(target_id: String, unique: bool) -> PackedStringArray:
	var hints: PackedStringArray = PackedStringArray()
	var likes: Array = []
	var dislikes: Array = []
	if ContentDB.girls.has(target_id):
		var def := ContentDB.girl(StringName(target_id))
		hints.append("Тип: %s" % str(def.get("archetype", target_id)))
		likes = def.get("likes", [])
		dislikes = def.get("dislikes", [])
		hints.append(str(def.get("bonus_desc", "")))
	else:
		var e: Dictionary = Game.girls.get_entry(StringName(target_id))
		hints.append("Городской контакт: %s" % str(e.get("archetype", "Кандидатка")))
		likes = e.get("likes", ["sincere"])
		dislikes = e.get("dislikes", [])
	if not likes.is_empty():
		hints.append("Любит: %s" % Loc.tags_list(likes))
	if not dislikes.is_empty():
		hints.append("Не любит: %s" % Loc.tags_list(dislikes))
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
	var add: float = float(picked.get("base_score", picked.get("score", 0.5)))
	if Game.upgrades.has_effect("bad_choice_mult") and add < 0.7:
		add *= Game.upgrades.effect_value("bad_choice_mult", 1.0)
	active_manual["score"] = float(active_manual.get("score", 0)) + add
	var emotion := &"neutral"
	if add >= 1.5:
		emotion = &"delighted"
	elif add >= 1.0:
		emotion = &"happy"
	elif add < 0.5:
		emotion = &"annoyed"
	active_manual["emotion"] = str(emotion)
	EventBus.notify.emit("DATE_EMOTION:%s" % str(emotion), &"date_fx")
	active_manual["phase"] = int(active_manual.get("phase", 0)) + 1
	if int(active_manual["phase"]) >= 3 or Game.upgrades.has_effect("fast_manual"):
		_finish_manual()
	else:
		_emit_phase()


func _finish_manual() -> void:
	var prep: Dictionary = active_manual.get("prep", {})
	var target_id := str(active_manual.get("target_id", ""))
	var unique := bool(active_manual.get("unique", true))
	var base := float(active_manual.get("score", 0))
	base += _prep_score(target_id, unique, prep)
	base += Game.upgrades.effect_value("manual_quality")
	var grade := _grade_from_score(base)
	var result := _apply_result(target_id, unique, prep, grade, true)
	Game.facility.release_venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
	active_manual.clear()
	date_ui_close.emit()
	last_result = result
	EventBus.date_finished.emit(result)


func _prep_score(target_id: String, unique: bool, prep: Dictionary) -> float:
	var score := 0.0
	var gift := ContentDB.gift(StringName(str(prep.get("gift_id", ""))))
	var outfit := ContentDB.outfit(StringName(str(prep.get("outfit_id", "casual"))))
	var venue := ContentDB.venue(StringName(str(prep.get("venue_id", "kitchen_table"))))
	score += float(gift.get("quality", 1)) * 0.4
	score += float(outfit.get("quality", 1)) * 0.3
	score += float(venue.get("quality", 1)) * 0.3
	score += Game.upgrades.effect_value("gift_quality") * 0.2
	score += Game.upgrades.effect_value("venue_quality_all") * 0.2
	var likes: Array = []
	var dislikes: Array = []
	if unique:
		var def := ContentDB.girl(StringName(target_id))
		likes = def.get("likes", [])
		dislikes = def.get("dislikes", [])
		if str(def.get("special_rule", "")) == "hate_cheap_outfit" and str(outfit.get("style", "")) in ["casual", "cheap"]:
			score -= 1.5
		if str(def.get("special_rule", "")) == "no_repeat_outfit" and str(prep.get("outfit_id", "")) == str(Game.inventory.last_outfit):
			score -= 1.0 * Game.upgrades.effect_value("repeat_penalty_mult", 1.0)
	else:
		# procedural likes stored on candidate refresh via prepared meta optional
		pass
	var gift_tags: Array = gift.get("tags", [])
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


func _apply_result(target_id: String, unique: bool, prep: Dictionary, grade: int, manual: bool) -> Dictionary:
	stats["total"] = int(stats.get("total", 0)) + 1
	var money := 0.0
	var pop := 0.0
	var rel := 0.0
	var scandal := 0.0
	match grade:
		Grade.CATASTROPHE:
			stats["fail"] = int(stats["fail"]) + 1
			money = 2.0
			pop = 0.0
			rel = 0.0
			scandal = 4.0
		Grade.FAIL:
			stats["fail"] = int(stats["fail"]) + 1
			money = 5.0
			pop = 0.5
			rel = 1.0
			scandal = 2.0
		Grade.OK:
			money = 12.0
			pop = 1.5
			rel = 3.0
			scandal = 0.0
		Grade.SUCCESS:
			stats["success"] = int(stats["success"]) + 1
			Game.total_successful_dates += 1
			money = 22.0
			pop = 3.0
			rel = 6.0
			scandal = 0.0
		Grade.PERFECT:
			stats["perfect"] = int(stats["perfect"]) + 1
			stats["success"] = int(stats["success"]) + 1
			Game.total_successful_dates += 1
			money = 35.0
			pop = 5.0
			rel = 10.0
			scandal = 0.0
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
	Game.economy.add(&"money", money, &"date")
	Game.economy.add(&"popularity", pop, &"date")
	Game.economy.add(&"scandal", scandal * Game.upgrades.effect_value("scandal_penalty_mult", 1.0) * float(effects.get("scandal_penalty_mult", 1.0)), &"date")
	if unique:
		Game.girls.add_relation(StringName(target_id), rel)
	var grade_name: String = str(["катастрофа", "неудача", "нормально", "успешно", "идеально"][grade])
	var result := {
		"target_id": target_id,
		"unique": unique,
		"grade": grade,
		"grade_name": grade_name,
		"money": money,
		"popularity": pop,
		"relation": rel,
		"scandal": scandal,
		"manual": manual,
	}
	EventBus.toast("Свидание: %s (+%d$ / +%.1f pop)" % [grade_name, int(money), pop], &"date")
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
	_process_autos(delta)
	_staff_automation(delta)
	# attention regen
	var regen := 0.05 * delta + float(Game.girls.active_effects().get("attention_regen", 0.0)) * delta
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
		var gift_id := _pick_gift_for(c)
		if gift_id == &"":
			EventBus.bottleneck.emit(&"gifts", "Нет подарков для автолинии")
			return
		var venue_id := _pick_venue()
		var outfit_id: StringName = Game.inventory.equipped_outfit
		if Game.staff.has_effect("auto_outfit") or Game.upgrades.has_effect("auto_outfit"):
			outfit_id = Game.inventory.auto_pick_outfit_for(c.get("likes", []))
		var prep := {"gift_id": str(gift_id), "venue_id": str(venue_id), "outfit_id": str(outfit_id), "extra": ""}
		if Game.inventory.gift_count(gift_id) <= 0:
			continue
		Game.inventory.gift_counts[str(gift_id)] = Game.inventory.gift_count(gift_id) - 1
		var wait: float = float(ContentDB.balance.get("auto_date_seconds", 12)) * Game.upgrades.effect_value("date_time_mult", 1.0)
		var actor := "manager"
		if automation_level >= 2 and Game.clones.available_count() > 0:
			actor = Game.clones.assign_to_date()
		active_autos.append({"target": c, "prep": prep, "wait": wait, "actor": actor})
		break
	auto_date_tick.emit(active_autos.size())


func _pick_gift_for(c: Dictionary) -> StringName:
	var likes: Array = c.get("likes", [])
	if str(c.get("kind", "")) == "unique":
		likes = ContentDB.girl(StringName(str(c.get("id", "")))).get("likes", [])
	for gid in Game.inventory.gift_counts.keys():
		if int(Game.inventory.gift_counts[gid]) <= 0:
			continue
		var tags: Array = ContentDB.gift(StringName(str(gid))).get("tags", [])
		for t in likes:
			if tags.has(t):
				return StringName(str(gid))
	for gid in Game.inventory.gift_counts.keys():
		if int(Game.inventory.gift_counts[gid]) > 0:
			return StringName(str(gid))
	return &""


func _pick_venue() -> StringName:
	var unlocked: Array = Game.facility.unlocked_venues
	# prefer higher capacity unlocked
	var best := &"kitchen_table"
	var best_cap := 0
	for v in unlocked:
		var def := ContentDB.venue(v)
		var cap := int(def.get("capacity", 1))
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
	var score := 2.5 + _prep_score(target_id if unique else "", unique, prep)
	score += Game.upgrades.effect_value("clone_quality")
	var actor := str(a.get("actor", "manager"))
	if actor.begins_with("clone"):
		var err: StringName = Game.clones.roll_error()
		if err != &"":
			score -= 1.5
			Game.economy.add(&"scandal", 1.5 * Game.upgrades.effect_value("clone_error_mult", 1.0), &"clone_err")
			EventBus.toast("Клон ошибся: %s" % str(err), &"warn")
		Game.clones.finish_date(actor)
	var grade := _grade_from_score(score)
	_apply_result(target_id, unique, prep, grade, false)


func raise_automation(level: int) -> void:
	automation_level = maxi(automation_level, level)


func to_dict() -> Dictionary:
	return {
		"prepared": prepared.duplicate(true),
		"stats": stats.duplicate(),
		"automation_level": automation_level,
	}


func from_dict(data: Dictionary) -> void:
	prepared = data.get("prepared", {})
	stats = data.get("stats", stats)
	automation_level = int(data.get("automation_level", 0))
	active_manual.clear()
	active_autos.clear()
