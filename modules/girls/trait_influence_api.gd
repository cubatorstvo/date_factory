class_name TraitInfluenceAPI
extends Node
## Collective trait influence: confirmed + 100% orbit → units per trait tree.
## Design: docs/11_TRAIT_INFLUENCE.md (T1 = counters + save; branches later).

signal influence_changed

const TRAIT_IDS: Array[String] = [
	"thrift", "generous", "punctual", "attentive", "calm", "ambitious", "daring", "witty",
]

const TRAIT_NAMES := {
	"thrift": "Экономность",
	"generous": "Щедрость",
	"punctual": "Пунктуальность",
	"attentive": "Внимательность",
	"calm": "Спокойствие",
	"ambitious": "Амбициозность",
	"daring": "Азартность",
	"witty": "Юмор",
}

## Observation-axis / legacy id → influence trait.
const AXIS_TO_INFLUENCE := {
	"time": "punctual",
	"attention": "attentive",
	"generosity": "generous",
	"adventure": "daring",
	"peace": "calm",
	"ambition": "ambitious",
	"humor": "witty",
	"punctual": "punctual",
	"attentive": "attentive",
	"generous": "generous",
	"thrift": "thrift",
	"calm": "calm",
	"ambitious": "ambitious",
	"daring": "daring",
	"witty": "witty",
}

const THRESHOLDS: Array[int] = [1, 3, 10, 30, 100, 300]

## trait_id → Array[String] girl ids contributing (idempotent).
var contributors: Dictionary = {}
## trait_id → int cached count
var counts: Dictionary = {}
## "trait_id:threshold" already toasted
var announced: Dictionary = {}
## trait_id → "A"|"B"|"C" (empty = not chosen)
var branches: Dictionary = {}
## trait_id → "deepen"|"expand" (порог 30; empty = not chosen)
var depth_choices: Dictionary = {}
## Active synergy ids (slot-limited)
var active_synergies: Array = []
## Up to 2 influence ids for targeted candidate search (T6)
var search_targets: Array = []
## trait_id → true when порог 100 institution unlocked
var institutions: Dictionary = {}
## One active doctrine trait_id (порог 300); empty = none
var active_doctrine: String = ""
## Thrift doctrine: money diverted to expansion-only reserve
var expansion_reserve: float = 0.0

const SEARCH_SIGNAL_HINTS := {
	"thrift": ["сравнивает цены", "бережёт чек", "спрашивает про смысл траты"],
	"generous": ["не смотрит на ценник", "любит щедрый жест", "тянется к «сделать приятно»"],
	"punctual": ["глядит на часы", "держит план вечера", "не любит пустого ожидания"],
	"attentive": ["замечает детали", "переспрашивает мелочи", "помнит прошлые фразы"],
	"calm": ["уходит от шума", "держит ровный тон", "просит тише"],
	"ambitious": ["говорит о целях", "ценится статус", "спрашивает про рост"],
	"daring": ["тянется к необычному", "предлагает свернуть с маршрута", "скучает от шаблона"],
	"witty": ["ловит паузу шуткой", "подкалывает легко", "разряжает неловкость"],
}

## Threshold-10 branch catalog (names + preview; thrift has real effects).
const BRANCH_DEFS := {
	"thrift": {
		"A": {"name": "Умные закупки", "preview": "−8% ко всем стандартным подаркам; авто не берёт дороже, если дешёвый не хуже."},
		"B": {"name": "Бережливый комплекс", "preview": "−8% к найму персонала / операционным ставкам."},
		"C": {"name": "Минимум потерь", "preview": "При провале свидания возвращается ~35% стоимости подарка."},
	},
	"generous": {
		"A": {"name": "Подарочная культура", "preview": "Качество подарков чуть сильнее влияет на исход (+0.2 prep)."},
		"B": {"name": "Сеть взаимопомощи", "preview": "Орбита мягче чинит легенду (+0.15 за визит — позже)."},
		"C": {"name": "Публичная благосклонность", "preview": "+10% популярности от свиданий."},
	},
	"punctual": {
		"A": {"name": "Логистика встреч", "preview": "+0.25 к оценке подготовки места."},
		"B": {"name": "Синхронизация дублей", "preview": "−15% к ошибкам дублей (мультипликатор)."},
		"C": {"name": "Предупреждение кризисов", "preview": "Авто +0.05 уверенности для пунктуальных."},
	},
	"attentive": {
		"A": {"name": "Память отношений", "preview": "+0.1 к силе правильной интерпретации (bond)."},
		"B": {"name": "Контроль качества", "preview": "Авто +0.06 уверенности для внимательных."},
		"C": {"name": "Изучение характера", "preview": "Наблюдения чуть быстрее копятся (задел)."},
	},
	"calm": {
		"A": {"name": "Контроль скандала", "preview": "−12% скандала со свиданий."},
		"B": {"name": "Устойчивость процессов", "preview": "Авто осторожнее: +0.04 conf."},
		"C": {"name": "Защита легенды", "preview": "Меньше урона легенде от мелких сбоев (задел)."},
	},
	"ambitious": {
		"A": {"name": "Доход и расширение", "preview": "+8% денег со свиданий."},
		"B": {"name": "Статус и популярность", "preview": "+8% популярности со свиданий."},
		"C": {"name": "Масштаб операций", "preview": "Авто +0.05 уверенности для амбициозных."},
	},
	"daring": {
		"A": {"name": "Большая ставка", "preview": "Риск-авто: чуть выше награда при успехе (+0.15 score)."},
		"B": {"name": "Импровизация", "preview": "Нейтральные ответы чуть мягче штрафуют."},
		"C": {"name": "Скандал как топливо", "preview": "Часть скандала → популярность (0.08)."},
	},
	"witty": {
		"A": {"name": "Социальное восстановление", "preview": "−10% скандала со свиданий."},
		"B": {"name": "Публичный образ", "preview": "+8% популярности со свиданий."},
		"C": {"name": "Естественность дублей", "preview": "−10% к ошибкам дублей."},
	},
}

## Synergies unlocked at 30/30 (activate via limited slots).
const SYNERGY_DEFS := {
	"precise_gift": {
		"name": "Точный подарок",
		"traits": ["thrift", "attentive"],
		"preview": "Авто берёт самый дешёвый среди реально подходящих подарков.",
	},
	"thrifty_logistics": {
		"name": "Бережливая логистика",
		"traits": ["thrift", "punctual"],
		"preview": "Авто-свидания чуть короче (−8% времени ожидания).",
	},
	"reinvest": {
		"name": "Реинвестирование",
		"traits": ["thrift", "ambitious"],
		"preview": "+5% денег со свиданий при активной синергии.",
	},
	"personal_gesture": {
		"name": "Личный жест",
		"traits": ["generous", "attentive"],
		"preview": "Совпадение тегов подарка сильнее (+0.25 prep).",
	},
	"calm_buffer": {
		"name": "Буфер без паники",
		"traits": ["punctual", "calm"],
		"preview": "−10% скандала со свиданий.",
	},
	"controlled_chaos": {
		"name": "Контролируемый хаос",
		"traits": ["calm", "daring"],
		"preview": "Авто +0.05 уверенности (риск под контролем).",
	},
}

## Порог 100 — institution name by branch (A/B/C).
const INSTITUTION_NAMES := {
	"thrift": {"A": "Рынок работает на тебя", "B": "Культура эффективности", "C": "Ничто не пропадает"},
	"generous": {"A": "Жест, который помнят", "B": "Круг поддержки", "C": "Статус через отдачу"},
	"punctual": {"A": "Город как расписание", "B": "Непрерывное алиби", "C": "Кризис до кризиса"},
	"attentive": {"A": "Память комплекса", "B": "Тихий контроль", "C": "Карта характеров"},
	"calm": {"A": "Щит легенды", "B": "Ровный ритм", "C": "Буфер скандала"},
	"ambitious": {"A": "Контур роста", "B": "Публичный масштаб", "C": "Операционный рывок"},
	"daring": {"A": "Окно прорыва", "B": "Импров-сеть", "C": "Скандал-топливо+"},
	"witty": {"A": "Социальный амортизатор", "B": "Образ фабрики", "C": "Живые дубли"},
}

## Порог 300 — doctrines (one active).
const DOCTRINE_DEFS := {
	"thrift": {
		"name": "Рациональная империя",
		"preview": "~12% дохода свиданий → резерв расширения (не в карман).",
		"limit": "Слабо помогает, когда нужен крупный статусный жест / люкс.",
		"flag": "doctrine_rational_empire",
	},
	"generous": {
		"name": "Империя взаимности",
		"preview": "Орбита сильнее чинит легенду (+0.2/визит задел); +12% pop.",
		"limit": "Требует поддерживать отношения — не безличный аварийный ресурс.",
		"flag": "doctrine_reciprocity",
	},
	"punctual": {
		"name": "Единый ритм",
		"preview": "−20% ошибок дублей; авто-время −10%.",
		"limit": "Не телепортирует и не отменяет физический мир.",
		"flag": "doctrine_unified_rhythm",
	},
	"attentive": {
		"name": "Память орбиты",
		"preview": "+0.15 gift quality; авто +0.08 conf.",
		"limit": "Не раскрывает неизвестные черты бесплатно.",
		"flag": "doctrine_orbit_memory",
	},
	"calm": {
		"name": "Тихая крепость",
		"preview": "−18% скандала со свиданий.",
		"limit": "Плохо усиливает риск-проекты и эпатаж.",
		"flag": "doctrine_quiet_fortress",
	},
	"ambitious": {
		"name": "Корпорация роста",
		"preview": "+12% денег и популярности со свиданий.",
		"limit": "Усиливает давление легенды при провалах (+).",
		"flag": "doctrine_growth_corp",
	},
	"daring": {
		"name": "Контролируемый хаос+",
		"preview": "Риск-авто: +0.2 score; scandal→pop 0.12.",
		"limit": "Крупный провал всё ещё крупный.",
		"flag": "doctrine_controlled_chaos",
	},
	"witty": {
		"name": "Фабрика историй",
		"preview": "−12% скандала, +10% pop, −10% clone errors.",
		"limit": "Не заменяет честное решение серьёзных кризисов.",
		"flag": "doctrine_story_factory",
	},
}


func setup(_game: Node) -> void:
	reset()


func reset() -> void:
	contributors.clear()
	counts.clear()
	announced.clear()
	branches.clear()
	depth_choices.clear()
	active_synergies.clear()
	search_targets.clear()
	institutions.clear()
	active_doctrine = ""
	expansion_reserve = 0.0
	for tid in TRAIT_IDS:
		contributors[tid] = []
		counts[tid] = 0
		branches[tid] = ""
		depth_choices[tid] = ""
		institutions[tid] = false
	influence_changed.emit()


func normalize_trait(raw: String) -> String:
	var key := str(raw)
	if AXIS_TO_INFLUENCE.has(key):
		return str(AXIS_TO_INFLUENCE[key])
	if TRAIT_IDS.has(key):
		return key
	return ""


func display_name(trait_id: String) -> String:
	return str(TRAIT_NAMES.get(trait_id, trait_id))


func count(trait_id: String) -> int:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return 0
	return int(counts.get(tid, 0))


func next_threshold(trait_id: String) -> int:
	var c := count(trait_id)
	for t in THRESHOLDS:
		if c < t:
			return t
	return THRESHOLDS[THRESHOLDS.size() - 1]


func contributors_of(trait_id: String) -> Array:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return []
	return (contributors.get(tid, []) as Array).duplicate()


func recount(announce: bool = true) -> void:
	var prev: Dictionary = counts.duplicate()
	for tid in TRAIT_IDS:
		contributors[tid] = []
		counts[tid] = 0
	if Game.girls == null:
		influence_changed.emit()
		return
	for row in Game.girls.list_claimed():
		var gid := str(row.get("id", ""))
		if gid.is_empty():
			continue
		for raw in _influence_traits_for_girl(StringName(gid), row):
			var tid := normalize_trait(str(raw))
			if tid.is_empty():
				continue
			var revealed_ok: bool = Game.girls.is_trait_revealed(StringName(gid), str(raw)) \
				or Game.girls.is_trait_revealed(StringName(gid), tid)
			if not revealed_ok:
				var axis := _influence_to_axis(tid)
				if axis.is_empty() or not Game.girls.is_trait_revealed(StringName(gid), axis):
					continue
			var list: Array = contributors[tid]
			if list.has(gid):
				continue
			# Mutual exclusion thrift/generous per girl.
			if tid == "thrift" and (contributors["generous"] as Array).has(gid):
				continue
			if tid == "generous" and (contributors["thrift"] as Array).has(gid):
				continue
			list.append(gid)
			contributors[tid] = list
			counts[tid] = list.size()
	if announce:
		_announce_crossings(prev)
	influence_changed.emit()


func _influence_traits_for_girl(gid: StringName, row: Dictionary) -> Array:
	## Prefer explicit primary_traits (T2+); else map girl_traits axes.
	var primary: Array = row.get("primary_traits", [])
	if primary.is_empty() and Game.girls.unlocked.has(str(gid)):
		primary = Game.girls.unlocked[str(gid)].get("primary_traits", [])
	if not primary.is_empty():
		return primary.duplicate()
	var out: Array = []
	for t in Game.girls.girl_traits(gid):
		var tid := normalize_trait(str(t))
		if tid.is_empty():
			continue
		if not out.has(tid):
			out.append(tid)
	return out


func _influence_to_axis(tid: String) -> String:
	match tid:
		"punctual":
			return "time"
		"attentive":
			return "attention"
		"generous", "thrift":
			return "generosity"
		"daring":
			return "adventure"
		"calm":
			return "peace"
		"ambitious":
			return "ambition"
		"witty":
			return "humor"
		_:
			return ""


func _announce_crossings(prev: Dictionary) -> void:
	for tid in TRAIT_IDS:
		var old_c := int(prev.get(tid, 0))
		var new_c := int(counts.get(tid, 0))
		if new_c <= old_c:
			continue
		for th in THRESHOLDS:
			if old_c < th and new_c >= th:
				var key := "%s:%d" % [tid, th]
				if bool(announced.get(key, false)):
					continue
				announced[key] = true
				var msg := "Влияние «%s»: %d девуш. (порог %d)" % [display_name(tid), new_c, th]
				if th == 10 and get_branch(tid).is_empty():
					msg += " — открой телефон → Orbit: выбор ветки"
				elif th == 30 and get_depth_choice(tid).is_empty():
					msg += " — Orbit: углубить ветку или расширить"
				elif th == 100:
					_unlock_institution(tid)
					msg += " — институциональный узел: %s" % institution_name(tid)
				elif th == 300:
					msg += " — доступна доктрина (Orbit, одна активная)"
				EventBus.call_deferred("toast", msg, &"girl")
	_sync_world_flags()


func summary_line() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for tid in TRAIT_IDS:
		var c := int(counts.get(tid, 0))
		if c <= 0:
			continue
		parts.append("%s %d" % [display_name(tid), c])
	if parts.is_empty():
		return "Влияние черт: пока нет (нужны подтверждение + 100% орбита)"
	return "Влияние: " + ", ".join(parts)


func has_threshold(trait_id: String, threshold: int) -> bool:
	return count(trait_id) >= threshold


func lesson_unlocked(trait_id: String) -> bool:
	## Порог 1 — личный урок.
	return has_threshold(trait_id, 1)


func rule_unlocked(trait_id: String) -> bool:
	## Порог 3 — повторяемое правило / авто.
	return has_threshold(trait_id, 3)


func search_unlocked(trait_id: String) -> bool:
	## Порог 3 открывает целенаправленный поиск кандидаток.
	return has_threshold(trait_id, 3)


func searchable_traits() -> Array:
	var out: Array = []
	for tid in TRAIT_IDS:
		if search_unlocked(tid):
			out.append(tid)
	return out


func search_accuracy_for(trait_id: String) -> float:
	var tid := normalize_trait(trait_id)
	if tid.is_empty() or not search_unlocked(tid):
		return 0.0
	var c := float(count(tid))
	## 3 → ~0.40, 10 → ~0.55, 30 → ~0.68, 100 → ~0.80
	return clampf(0.28 + log(c + 1.0) * 0.12, 0.35, 0.82)


func current_search_accuracy() -> float:
	if search_targets.is_empty():
		return 0.0
	var best := 0.0
	for t in search_targets:
		best = maxf(best, search_accuracy_for(str(t)))
	return best


func get_search_targets() -> Array:
	return search_targets.duplicate()


func set_search_targets(traits: Array) -> bool:
	var cleaned: Array = []
	for raw in traits:
		var tid := normalize_trait(str(raw))
		if tid.is_empty() or cleaned.has(tid):
			continue
		if not search_unlocked(tid):
			EventBus.call_deferred("toast", "Поиск «%s» ещё закрыт (нужно влияние 3)" % display_name(tid), &"warn")
			return false
		cleaned.append(tid)
		if cleaned.size() >= 2:
			break
	if cleaned.has("thrift") and cleaned.has("generous"):
		EventBus.call_deferred("toast", "Нельзя искать thrift и generous вместе", &"warn")
		return false
	search_targets = cleaned
	influence_changed.emit()
	if cleaned.is_empty():
		EventBus.call_deferred("toast", "Поиск сброшен", &"info")
	else:
		var names: PackedStringArray = PackedStringArray()
		for t2 in cleaned:
			names.append(display_name(str(t2)))
		EventBus.call_deferred("toast", "Поиск: %s (точность ~%.0f%%)" % [", ".join(names), current_search_accuracy() * 100.0], &"girl")
	if typeof(Game) != TYPE_NIL and is_instance_valid(Game) and Game.girls != null:
		Game.girls.refresh_candidates(true)
	return true


func clear_search() -> void:
	set_search_targets([])


func soft_signal_for(trait_id: String) -> String:
	var tid := normalize_trait(trait_id)
	var hints: Array = SEARCH_SIGNAL_HINTS.get(tid, [])
	if hints.is_empty():
		return ""
	return str(hints[randi() % hints.size()])


func roll_search_profile(base_likes: Array = []) -> Dictionary:
	## Biased primaries + soft observable signal. Never guarantees the trait.
	if search_targets.is_empty():
		var pack0: Dictionary = TraitsContent.pack_for_profile({"likes": base_likes})
		return {
			"primary_traits": pack0.get("primary_traits", []),
			"traits": pack0.get("traits", []),
			"quirk": pack0.get("quirk", ""),
			"soft_signal": "",
			"false_positive": false,
		}
	var acc := current_search_accuracy()
	var forced: Array = []
	var false_positive := false
	if randf() < acc:
		forced.append(str(search_targets[0]))
		if search_targets.size() > 1 and randf() < acc * 0.65:
			forced.append(str(search_targets[1]))
	else:
		## Miss — sometimes a misleading signal.
		if randf() < 0.4:
			false_positive = true
	var bias: Array = base_likes.duplicate()
	for t in forced:
		bias.append(t)
	for t2 in search_targets:
		if randf() < acc * 0.5:
			bias.append(str(t2))
	var primaries: Array = TraitsContent.pick_primary_pair(bias)
	if not forced.is_empty():
		var merged: Array = forced.duplicate()
		for p in primaries:
			if not merged.has(p):
				merged.append(p)
		primaries = TraitsContent.sanitize_primaries(merged)
	var signal_trait := ""
	if false_positive:
		signal_trait = str(search_targets[0])
	elif not forced.is_empty():
		signal_trait = str(forced[0])
	elif randf() < 0.25:
		signal_trait = str(search_targets[0])
		false_positive = not primaries.has(signal_trait)
	var soft := soft_signal_for(signal_trait) if signal_trait != "" else ""
	return {
		"primary_traits": primaries,
		"traits": TraitsContent.dialogue_traits_from_primaries(primaries),
		"quirk": TraitsContent.pick_quirk(),
		"soft_signal": soft,
		"false_positive": false_positive,
	}


func progress_text(trait_id: String) -> String:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return "0/1"
	var c := count(tid)
	var nxt := next_threshold(tid)
	return "%d/%d" % [c, nxt]


func girl_has_primary(girl_id: StringName, influence_id: String) -> bool:
	if Game.girls == null:
		return false
	var want := normalize_trait(influence_id)
	if want.is_empty():
		return false
	for p in Game.girls.girl_primary_traits(girl_id):
		if normalize_trait(str(p)) == want:
			return true
	return false


func gift_price_mult_for_girl(girl_id: StringName) -> float:
	## Thrift@1: подарки для экономных дешевле ~10% (без глобальной ветки A).
	if lesson_unlocked("thrift") and girl_has_primary(girl_id, "thrift"):
		return 0.9
	return 1.0


func global_gift_price_mult() -> float:
	## Thrift branch A: все стандартные подарки дешевле; deepen усиливает.
	if get_branch("thrift") == "A":
		if get_depth_choice("thrift") == "deepen":
			return 0.88
		return 0.92
	return 1.0


func get_branch(trait_id: String) -> String:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return ""
	return str(branches.get(tid, ""))


func can_choose_branch(trait_id: String) -> bool:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return false
	if count(tid) < 10:
		return false
	return get_branch(tid).is_empty()


func pending_branch_traits() -> Array:
	var out: Array = []
	for tid in TRAIT_IDS:
		if can_choose_branch(tid):
			out.append(tid)
	return out


func branch_def(trait_id: String, branch: String) -> Dictionary:
	var tid := normalize_trait(trait_id)
	var b := str(branch).to_upper()
	if not BRANCH_DEFS.has(tid):
		return {}
	var bag: Dictionary = BRANCH_DEFS[tid]
	return bag.get(b, {}).duplicate(true)


func branch_preview(trait_id: String, branch: String) -> String:
	var d: Dictionary = branch_def(trait_id, branch)
	if d.is_empty():
		return ""
	return "%s — %s" % [str(d.get("name", branch)), str(d.get("preview", ""))]


func choose_branch(trait_id: String, branch: String) -> bool:
	var tid := normalize_trait(trait_id)
	var b := str(branch).to_upper()
	if tid.is_empty() or not (b in ["A", "B", "C"]):
		return false
	if not can_choose_branch(tid):
		if count(tid) < 10:
			EventBus.call_deferred("toast", "Нужно влияние 10 для выбора ветки", &"warn")
		elif not get_branch(tid).is_empty():
			EventBus.call_deferred("toast", "Ветка уже выбрана — смена недоступна", &"warn")
		return false
	var d: Dictionary = branch_def(tid, b)
	if d.is_empty():
		return false
	branches[tid] = b
	influence_changed.emit()
	EventBus.call_deferred("toast", "Ветка «%s»: %s" % [display_name(tid), str(d.get("name", b))], &"girl")
	return true


func get_depth_choice(trait_id: String) -> String:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return ""
	return str(depth_choices.get(tid, ""))


func can_choose_depth(trait_id: String) -> bool:
	var tid := normalize_trait(trait_id)
	if tid.is_empty():
		return false
	if count(tid) < 30:
		return false
	if get_branch(tid).is_empty():
		return false
	return get_depth_choice(tid).is_empty()


func pending_depth_traits() -> Array:
	var out: Array = []
	for tid in TRAIT_IDS:
		if can_choose_depth(tid):
			out.append(tid)
	return out


func choose_depth(trait_id: String, mode: String) -> bool:
	var tid := normalize_trait(trait_id)
	var m := str(mode).to_lower()
	if tid.is_empty() or not (m in ["deepen", "expand"]):
		return false
	if not can_choose_depth(tid):
		EventBus.call_deferred("toast", "Углубление недоступно (нужны ветка + влияние 30)", &"warn")
		return false
	depth_choices[tid] = m
	var label := "углубление выбранной ветки" if m == "deepen" else "первый узел второй ветки"
	influence_changed.emit()
	EventBus.call_deferred("toast", "%s: %s" % [display_name(tid), label], &"girl")
	return true


func synergy_def(synergy_id: String) -> Dictionary:
	return SYNERGY_DEFS.get(synergy_id, {}).duplicate(true)


func synergy_unlocked(synergy_id: String) -> bool:
	var d: Dictionary = SYNERGY_DEFS.get(synergy_id, {})
	if d.is_empty():
		return false
	for t in d.get("traits", []):
		if count(str(t)) < 30:
			return false
	return true


func synergy_slot_count() -> int:
	## stage_3 (операционный штаб) → 1 слот; позже больше.
	var stage := "stage_1"
	var is_post := false
	if typeof(Game) != TYPE_NIL and is_instance_valid(Game):
		stage = str(Game.get("stage_id"))
		is_post = bool(Game.get("postgame"))
	if is_post or stage in ["stage_5", "stage_6", "postgame"]:
		return 3
	if stage == "stage_4":
		return 2
	if stage == "stage_3":
		return 1
	return 0


func has_active_synergy(synergy_id: String) -> bool:
	return active_synergies.has(synergy_id)


func unlocked_synergies() -> Array:
	var out: Array = []
	for sid in SYNERGY_DEFS.keys():
		if synergy_unlocked(str(sid)):
			out.append(str(sid))
	return out


func pending_synergies() -> Array:
	var out: Array = []
	for sid in unlocked_synergies():
		if not has_active_synergy(str(sid)):
			out.append(str(sid))
	return out


func can_activate_synergy(synergy_id: String) -> bool:
	if not synergy_unlocked(synergy_id):
		return false
	if has_active_synergy(synergy_id):
		return false
	return active_synergies.size() < synergy_slot_count()


func activate_synergy(synergy_id: String) -> bool:
	var sid := str(synergy_id)
	if not SYNERGY_DEFS.has(sid):
		return false
	if not can_activate_synergy(sid):
		if synergy_slot_count() <= 0:
			EventBus.call_deferred("toast", "Синергии с stage_3 (операционный штаб)", &"warn")
		elif not synergy_unlocked(sid):
			EventBus.call_deferred("toast", "Нужно влияние 30 у обеих черт", &"warn")
		elif has_active_synergy(sid):
			EventBus.call_deferred("toast", "Синергия уже активна", &"warn")
		else:
			EventBus.call_deferred("toast", "Нет свободного слота синергии", &"warn")
		return false
	active_synergies.append(sid)
	var d: Dictionary = SYNERGY_DEFS[sid]
	influence_changed.emit()
	EventBus.call_deferred("toast", "Синергия: %s" % str(d.get("name", sid)), &"girl")
	return true


func deactivate_synergy(synergy_id: String) -> bool:
	var sid := str(synergy_id)
	if not active_synergies.has(sid):
		return false
	active_synergies.erase(sid)
	influence_changed.emit()
	EventBus.call_deferred("toast", "Синергия снята (нужна реорганизация)", &"info")
	return true


func synergy_preview(synergy_id: String) -> String:
	var d: Dictionary = synergy_def(synergy_id)
	if d.is_empty():
		return ""
	var parts: PackedStringArray = PackedStringArray()
	for t in d.get("traits", []):
		parts.append(display_name(str(t)))
	return "%s (%s) — %s" % [str(d.get("name", synergy_id)), "+".join(parts), str(d.get("preview", ""))]


func pick_precise_gift(likes: Array) -> StringName:
	## Cheapest among gifts that actually match likes (or value tags).
	var best_id := &""
	var best_price := INF
	for gid in Game.inventory.gift_counts.keys():
		if int(Game.inventory.gift_counts[gid]) <= 0:
			continue
		var gdef: Dictionary = ContentDB.gift(StringName(str(gid)))
		var tags: Array = gdef.get("tags", [])
		var matched := false
		for t in likes:
			if tags.has(t):
				matched = true
				break
		if not matched and not gift_matches_value(gdef, likes):
			continue
		var price := float(gdef.get("price", 0.0))
		if price < best_price:
			best_price = price
			best_id = StringName(str(gid))
	return best_id


func institution_ready(trait_id: String) -> bool:
	return count(trait_id) >= 100 and not get_branch(trait_id).is_empty()


func has_institution(trait_id: String) -> bool:
	var tid := normalize_trait(trait_id)
	return bool(institutions.get(tid, false)) or institution_ready(tid)


func institution_name(trait_id: String) -> String:
	var tid := normalize_trait(trait_id)
	var br := get_branch(tid)
	if br.is_empty():
		return "институт (нужна ветка)"
	var bag: Dictionary = INSTITUTION_NAMES.get(tid, {})
	return str(bag.get(br, "Институт %s/%s" % [display_name(tid), br]))


func _unlock_institution(trait_id: String) -> void:
	var tid := normalize_trait(trait_id)
	if tid.is_empty() or not institution_ready(tid):
		return
	if bool(institutions.get(tid, false)):
		return
	institutions[tid] = true
	_sync_world_flags()


func doctrine_ready(trait_id: String) -> bool:
	return count(trait_id) >= 300 and not get_branch(trait_id).is_empty() and DOCTRINE_DEFS.has(normalize_trait(trait_id))


func pending_doctrines() -> Array:
	var out: Array = []
	for tid in TRAIT_IDS:
		if doctrine_ready(tid) and active_doctrine != tid:
			out.append(tid)
	return out


func doctrine_def(trait_id: String) -> Dictionary:
	return DOCTRINE_DEFS.get(normalize_trait(trait_id), {}).duplicate(true)


func doctrine_preview(trait_id: String) -> String:
	var d: Dictionary = doctrine_def(trait_id)
	if d.is_empty():
		return ""
	return "%s — %s Ограничение: %s" % [str(d.get("name", "")), str(d.get("preview", "")), str(d.get("limit", ""))]


func can_activate_doctrine(trait_id: String) -> bool:
	var tid := normalize_trait(trait_id)
	if not doctrine_ready(tid):
		return false
	if active_doctrine != "" and active_doctrine != tid:
		return false
	return active_doctrine != tid


func activate_doctrine(trait_id: String) -> bool:
	var tid := normalize_trait(trait_id)
	if not doctrine_ready(tid):
		EventBus.call_deferred("toast", "Доктрина недоступна (нужны ветка + влияние 300)", &"warn")
		return false
	if active_doctrine != "" and active_doctrine != tid:
		EventBus.call_deferred("toast", "Уже активна доктрина «%s» — смена = реорганизация" % str(doctrine_def(active_doctrine).get("name", active_doctrine)), &"warn")
		return false
	if active_doctrine == tid:
		return true
	active_doctrine = tid
	_sync_world_flags()
	influence_changed.emit()
	var d: Dictionary = doctrine_def(tid)
	EventBus.call_deferred("toast", "Доктрина: %s · %s" % [str(d.get("name", tid)), str(d.get("limit", ""))], &"girl")
	return true


func deactivate_doctrine() -> bool:
	if active_doctrine.is_empty():
		return false
	active_doctrine = ""
	_sync_world_flags()
	influence_changed.emit()
	EventBus.call_deferred("toast", "Доктрина снята (реорганизация орбиты)", &"info")
	return true


func _sync_world_flags() -> void:
	if typeof(Game) == TYPE_NIL or not is_instance_valid(Game) or Game.facility == null:
		return
	for tid in TRAIT_IDS:
		var ready := institution_ready(tid)
		if ready:
			institutions[tid] = true
		var flag := "orbit_institution_%s" % tid
		Game.facility.set_flag(flag, ready)
	for tid2 in DOCTRINE_DEFS.keys():
		var dd: Dictionary = DOCTRINE_DEFS[tid2]
		var f := str(dd.get("flag", ""))
		if f.is_empty():
			continue
		Game.facility.set_flag(f, active_doctrine == tid2)
	Game.facility.set_flag("orbit_culture_active", _any_institution() or active_doctrine != "")


func _any_institution() -> bool:
	for tid in TRAIT_IDS:
		if institution_ready(tid):
			return true
	return false


func on_date_money_earned(amount: float) -> float:
	## Returns money kept in pocket; rest may go to expansion_reserve (thrift doctrine).
	if amount <= 0.0:
		return amount
	if active_doctrine != "thrift":
		return amount
	var divert := amount * 0.12
	expansion_reserve += divert
	return amount - divert


func spend_expansion_reserve(cost: float) -> bool:
	if cost <= 0.0:
		return true
	if expansion_reserve < cost:
		return false
	expansion_reserve -= cost
	influence_changed.emit()
	return true


func author_unique_mods() -> Dictionary:
	## Claimed uniques amplify matching trees (author, not random mass passives).
	var acc: Dictionary = {}
	if typeof(Game) == TYPE_NIL or not is_instance_valid(Game) or Game.girls == null:
		return acc
	for row in Game.girls.list_claimed():
		var gid := str(row.get("id", ""))
		if not ContentDB.girls.has(gid):
			continue
		var prim: Array = Game.girls.girl_primary_traits(StringName(gid))
		## Business: thrift+ambitious → author reinvest boost if synergy or doctrine.
		if gid == "business" and prim.has("thrift") and prim.has("ambitious"):
			if has_active_synergy("reinvest") or active_doctrine == "thrift":
				acc["money_mult"] = float(acc.get("money_mult", 1.0)) * 1.05
				acc["author_reinvest"] = true
		if gid == "neighbor" and prim.has("attentive"):
			acc["gift_quality_bonus"] = float(acc.get("gift_quality_bonus", 0.0)) + 0.1
		if gid == "lawyer" and prim.has("punctual"):
			acc["clone_error_mult"] = float(acc.get("clone_error_mult", 1.0)) * 0.95
		if gid == "alien" and prim.has("daring") and prim.has("calm"):
			if has_active_synergy("controlled_chaos") or active_doctrine == "daring":
				acc["auto_conf_bonus"] = float(acc.get("auto_conf_bonus", 0.0)) + 0.05
	return acc


func clamp_effect_bag(acc: Dictionary) -> Dictionary:
	## §26.2 — no unbounded % stacking across trees/synergies/doctrines.
	var out: Dictionary = acc.duplicate(true)
	var boost_caps := {
		"money_mult": 1.45,
		"event_pop_mult": 1.45,
		"outfit_mult": 1.4,
		"line_mult": 1.4,
	}
	var cut_floors := {
		"gift_price_mult": 0.7,
		"staff_cost_mult": 0.7,
		"scandal_penalty_mult": 0.55,
		"clone_error_mult": 0.55,
		"auto_date_time_mult": 0.75,
		"fine_mult": 0.7,
	}
	for k in boost_caps.keys():
		if out.has(k):
			out[k] = minf(float(out[k]), float(boost_caps[k]))
	for k2 in cut_floors.keys():
		if out.has(k2):
			out[k2] = maxf(float(out[k2]), float(cut_floors[k2]))
	if out.has("gift_quality_bonus"):
		out["gift_quality_bonus"] = minf(float(out["gift_quality_bonus"]), 0.8)
	if out.has("fail_resource_refund"):
		out["fail_resource_refund"] = minf(float(out["fail_resource_refund"]), 0.55)
	if out.has("scandal_to_pop"):
		out["scandal_to_pop"] = minf(float(out["scandal_to_pop"]), 0.25)
	if out.has("auto_conf_bonus"):
		out["auto_conf_bonus"] = minf(float(out["auto_conf_bonus"]), 0.25)
	if out.has("risk_score_bonus"):
		out["risk_score_bonus"] = minf(float(out["risk_score_bonus"]), 0.35)
	return out


func culture_summary() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("Культура орбиты:")
	var any_br := false
	for tid in TRAIT_IDS:
		var br := get_branch(tid)
		if br.is_empty():
			continue
		any_br = true
		var bit := "%s %s" % [display_name(tid), br]
		if institution_ready(tid):
			bit += " / %s" % institution_name(tid)
		lines.append("• " + bit)
	if not any_br:
		lines.append("• ветки ещё не выбраны")
	if not active_synergies.is_empty():
		var sn: PackedStringArray = PackedStringArray()
		for sid in active_synergies:
			sn.append(str(synergy_def(str(sid)).get("name", sid)))
		lines.append("Синергии: " + ", ".join(sn))
	else:
		lines.append("Синергии: нет")
	if active_doctrine != "":
		var dd: Dictionary = doctrine_def(active_doctrine)
		lines.append("Доктрина: %s" % str(dd.get("name", active_doctrine)))
		lines.append("Ограничение: %s" % str(dd.get("limit", "—")))
	else:
		lines.append("Доктрина: не выбрана")
	if expansion_reserve > 0.0:
		lines.append("Резерв расширения: %.0f$" % expansion_reserve)
	return "\n".join(lines)


func branch_passive_effects() -> Dictionary:
	## Merged into GirlsAPI.active_effects / dating hooks.
	var acc: Dictionary = {}
	match get_branch("thrift"):
		"A":
			acc["gift_price_mult"] = float(acc.get("gift_price_mult", 1.0)) * 0.92
		"B":
			acc["staff_cost_mult"] = float(acc.get("staff_cost_mult", 1.0)) * 0.92
		"C":
			acc["fail_resource_refund"] = 0.35
	match get_branch("generous"):
		"A":
			acc["gift_quality_bonus"] = float(acc.get("gift_quality_bonus", 0.0)) + 0.2
		"C":
			acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) * 1.1
	match get_branch("punctual"):
		"A":
			acc["venue_prep_bonus"] = float(acc.get("venue_prep_bonus", 0.0)) + 0.25
		"B":
			acc["clone_error_mult"] = float(acc.get("clone_error_mult", 1.0)) * 0.85
	match get_branch("calm"):
		"A":
			acc["scandal_penalty_mult"] = float(acc.get("scandal_penalty_mult", 1.0)) * 0.88
	match get_branch("ambitious"):
		"A":
			acc["money_mult"] = float(acc.get("money_mult", 1.0)) * 1.08
		"B":
			acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) * 1.08
	match get_branch("daring"):
		"C":
			acc["scandal_to_pop"] = float(acc.get("scandal_to_pop", 0.0)) + 0.08
	match get_branch("witty"):
		"A":
			acc["scandal_penalty_mult"] = float(acc.get("scandal_penalty_mult", 1.0)) * 0.9
		"B":
			acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) * 1.08
		"C":
			acc["clone_error_mult"] = float(acc.get("clone_error_mult", 1.0)) * 0.9
	if get_depth_choice("thrift") == "deepen" and get_branch("thrift") == "B":
		acc["staff_cost_mult"] = float(acc.get("staff_cost_mult", 1.0)) * 0.95
	if get_depth_choice("thrift") == "deepen" and get_branch("thrift") == "C":
		acc["fail_resource_refund"] = maxf(float(acc.get("fail_resource_refund", 0.0)), 0.45)
	if has_active_synergy("reinvest"):
		acc["money_mult"] = float(acc.get("money_mult", 1.0)) * 1.05
	if has_active_synergy("calm_buffer"):
		acc["scandal_penalty_mult"] = float(acc.get("scandal_penalty_mult", 1.0)) * 0.9
	if has_active_synergy("thrifty_logistics"):
		acc["auto_date_time_mult"] = float(acc.get("auto_date_time_mult", 1.0)) * 0.92
	if has_active_synergy("personal_gesture"):
		acc["gift_quality_bonus"] = float(acc.get("gift_quality_bonus", 0.0)) + 0.25
	## Institutions @100 (rule-ish, not pure % spam).
	if institution_ready("thrift"):
		match get_branch("thrift"):
			"A":
				acc["gift_price_mult"] = float(acc.get("gift_price_mult", 1.0)) * 0.96
			"B":
				acc["staff_cost_mult"] = float(acc.get("staff_cost_mult", 1.0)) * 0.96
			"C":
				acc["fail_resource_refund"] = maxf(float(acc.get("fail_resource_refund", 0.0)), 0.5)
	if institution_ready("punctual"):
		acc["clone_error_mult"] = float(acc.get("clone_error_mult", 1.0)) * 0.92
	if institution_ready("calm"):
		acc["scandal_penalty_mult"] = float(acc.get("scandal_penalty_mult", 1.0)) * 0.92
	## Doctrine @300 (one active) + limits encoded as missing bonuses elsewhere.
	match active_doctrine:
		"thrift":
			acc["doctrine_expansion_divert"] = 0.12
			acc["status_gift_penalty"] = 0.35
		"generous":
			acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) * 1.12
		"punctual":
			acc["clone_error_mult"] = float(acc.get("clone_error_mult", 1.0)) * 0.8
			acc["auto_date_time_mult"] = float(acc.get("auto_date_time_mult", 1.0)) * 0.9
		"attentive":
			acc["gift_quality_bonus"] = float(acc.get("gift_quality_bonus", 0.0)) + 0.15
			acc["auto_conf_bonus"] = float(acc.get("auto_conf_bonus", 0.0)) + 0.08
		"calm":
			acc["scandal_penalty_mult"] = float(acc.get("scandal_penalty_mult", 1.0)) * 0.82
		"ambitious":
			acc["money_mult"] = float(acc.get("money_mult", 1.0)) * 1.12
			acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) * 1.12
		"daring":
			acc["scandal_to_pop"] = float(acc.get("scandal_to_pop", 0.0)) + 0.12
			acc["risk_score_bonus"] = float(acc.get("risk_score_bonus", 0.0)) + 0.2
		"witty":
			acc["scandal_penalty_mult"] = float(acc.get("scandal_penalty_mult", 1.0)) * 0.88
			acc["event_pop_mult"] = float(acc.get("event_pop_mult", 1.0)) * 1.1
			acc["clone_error_mult"] = float(acc.get("clone_error_mult", 1.0)) * 0.9
	var author: Dictionary = author_unique_mods()
	for k in author.keys():
		var v: Variant = author[k]
		if typeof(v) == TYPE_BOOL:
			acc[k] = bool(acc.get(k, false)) or bool(v)
		elif str(k).ends_with("_mult"):
			var base_m: float = float(acc.get(k, 1.0))
			if not acc.has(k):
				base_m = 1.0
			acc[k] = base_m * float(v)
		else:
			acc[k] = float(acc.get(k, 0.0)) + float(v)
	return clamp_effect_bag(acc)


func prep_gift_score_mod(girl_id: StringName, gift: Dictionary) -> float:
	## Thrift@1: разумный/дешёвый подарок полный эффект; бессмысленный люкс слабее.
	var mod := 0.0
	if not lesson_unlocked("thrift") or not girl_has_primary(girl_id, "thrift"):
		return mod
	var tags: Array = gift.get("tags", [])
	var price := float(gift.get("price", 0.0))
	var value_ok := tags.has("cheap") or tags.has("sincere") or tags.has("useful") or tags.has("order")
	var luxury_flex := tags.has("luxury") or price >= 80.0
	if value_ok:
		mod += 0.7
	if luxury_flex and not value_ok:
		mod -= 0.9
	## Thrift doctrine limit: status/luxury flex weaker.
	if active_doctrine == "thrift" and luxury_flex:
		mod -= float(branch_passive_effects().get("status_gift_penalty", 0.35))
	return mod


func auto_avoid_empty_luxury() -> bool:
	## Thrift@3 or thrift branch A: авто не берёт «просто дорогое» без совпадения тегов.
	return rule_unlocked("thrift") or get_branch("thrift") == "A"


func gift_matches_value(gift: Dictionary, likes: Array) -> bool:
	var tags: Array = gift.get("tags", [])
	for t in likes:
		if tags.has(t):
			return true
	for t2 in ["cheap", "sincere", "useful", "order", "tasty"]:
		if tags.has(t2):
			return true
	return false


func is_empty_luxury_gift(gift: Dictionary, likes: Array) -> bool:
	var tags: Array = gift.get("tags", [])
	var price := float(gift.get("price", 0.0))
	var luxury := tags.has("luxury") or price >= 100.0
	if not luxury:
		return false
	for t in likes:
		if tags.has(t):
			return false
	return true


func punctual_prep_bonus(girl_id: StringName, venue: Dictionary) -> float:
	var bonus := 0.0
	if lesson_unlocked("punctual") and girl_has_primary(girl_id, "punctual"):
		var tags: Array = venue.get("tags", [])
		if tags.has("order") or str(venue.get("id", "")) == "kitchen_table":
			bonus += 0.35
		else:
			bonus += 0.1
	if get_branch("punctual") == "A":
		bonus += float(branch_passive_effects().get("venue_prep_bonus", 0.0))
	return bonus


func auto_confidence_bonus(girl_id: StringName) -> float:
	var bonus := 0.0
	if rule_unlocked("punctual") and girl_has_primary(girl_id, "punctual"):
		bonus += 0.08
	if rule_unlocked("thrift") and girl_has_primary(girl_id, "thrift"):
		bonus += 0.05
	if rule_unlocked("attentive") and girl_has_primary(girl_id, "attentive"):
		bonus += 0.05
	if get_branch("punctual") == "C" and girl_has_primary(girl_id, "punctual"):
		bonus += 0.05
	if get_branch("attentive") == "B" and girl_has_primary(girl_id, "attentive"):
		bonus += 0.06
	if get_branch("calm") == "B":
		bonus += 0.04
	if get_branch("ambitious") == "C" and girl_has_primary(girl_id, "ambitious"):
		bonus += 0.05
	if has_active_synergy("controlled_chaos"):
		bonus += 0.05
	bonus += float(branch_passive_effects().get("auto_conf_bonus", 0.0))
	return bonus


func scandal_mult_for_date(girl_id: StringName) -> float:
	if lesson_unlocked("calm") and girl_has_primary(girl_id, "calm"):
		return 0.85
	return 1.0


func phone_orbit_report() -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[b]Орбита / влияние черт[/b]")
	lines.append("Единица = подтверждённая черта + 100% связь. Пороги: 1 → урок, 3 → авто-правило, 10 → ветка.")
	lines.append("")
	var any := false
	for tid in TRAIT_IDS:
		var c := count(tid)
		if c <= 0:
			continue
		any = true
		var nxt := next_threshold(tid)
		var flags: PackedStringArray = PackedStringArray()
		if c >= 1:
			flags.append("урок")
		if c >= 3:
			flags.append("авто")
		if search_unlocked(tid):
			flags.append("поиск*")
		var br := get_branch(tid)
		if br != "":
			var bd: Dictionary = branch_def(tid, br)
			flags.append("ветка %s: %s" % [br, str(bd.get("name", br))])
			var depth := get_depth_choice(tid)
			if depth == "deepen":
				flags.append("углубление")
			elif depth == "expand":
				flags.append("2-я ветка")
			elif c >= 30:
				flags.append("ВЫБОР 30")
		elif c >= 10:
			flags.append("ВЫБОР ВЕТКИ")
		var flag_txt := ""
		if not flags.is_empty():
			flag_txt = " · " + ", ".join(flags)
		lines.append("• %s: [b]%d/%d[/b]%s" % [display_name(tid), c, nxt, flag_txt])
	if not any:
		lines.append("Пока нет единиц влияния. Подтверди черты и доведи связь до 100%.")
	var pending: Array = pending_branch_traits()
	if not pending.is_empty():
		lines.append("")
		lines.append("[b]Доступен выбор ветки[/b] (кнопки ниже):")
		for tid2 in pending:
			lines.append("— %s" % display_name(str(tid2)))
			for b in ["A", "B", "C"]:
				lines.append("  %s) %s" % [b, branch_preview(str(tid2), b)])
	var slots := synergy_slot_count()
	lines.append("")
	lines.append("[b]Синергии[/b] слоты: %d/%d" % [active_synergies.size(), slots])
	if active_synergies.is_empty():
		lines.append("— активных нет")
	else:
		for sid in active_synergies:
			var sd: Dictionary = synergy_def(str(sid))
			lines.append("• %s" % str(sd.get("name", sid)))
	var pend_syn: Array = pending_synergies()
	if not pend_syn.is_empty() and slots > 0:
		lines.append("Доступны к активации:")
		for sid2 in pend_syn:
			lines.append("  · %s" % synergy_preview(str(sid2)))
	elif slots <= 0:
		lines.append("[i]Слоты синергий открываются на stage_3.[/i]")
	var pend_depth: Array = pending_depth_traits()
	if not pend_depth.is_empty():
		lines.append("")
		lines.append("[b]Порог 30[/b]: углубить ветку или открыть узел второй.")
		for tid3 in pend_depth:
			lines.append("— %s" % display_name(str(tid3)))
	var searchable: Array = searchable_traits()
	lines.append("")
	if search_targets.is_empty():
		lines.append("[b]Поиск[/b]: не задан")
	else:
		var sn: PackedStringArray = PackedStringArray()
		for st in search_targets:
			sn.append(display_name(str(st)))
		lines.append("[b]Поиск[/b]: %s · точность ~%.0f%%" % [", ".join(sn), current_search_accuracy() * 100.0])
		lines.append("[i]Повышает шанс сигналов, не ставит метку «экономная» над головой.[/i]")
	if not searchable.is_empty():
		var open_n: PackedStringArray = PackedStringArray()
		for st2 in searchable:
			open_n.append(display_name(str(st2)))
		lines.append("Открыто направлений: %s" % ", ".join(open_n))
	else:
		lines.append("Поиск откроется с влияния 3 по любой черте.")
	lines.append("")
	lines.append("[b]Институты / доктрины[/b]")
	var any_inst := false
	for tid4 in TRAIT_IDS:
		if institution_ready(tid4):
			any_inst = true
			lines.append("• %s: %s" % [display_name(tid4), institution_name(tid4)])
	if not any_inst:
		lines.append("— институтов нет (порог 100 + ветка)")
	if active_doctrine != "":
		var dd2: Dictionary = doctrine_def(active_doctrine)
		lines.append("Доктрина: [b]%s[/b]" % str(dd2.get("name", active_doctrine)))
		lines.append("[i]Ограничение: %s[/i]" % str(dd2.get("limit", "")))
		if expansion_reserve > 0.0:
			lines.append("Резерв расширения: %.0f$" % expansion_reserve)
	else:
		var pd: Array = pending_doctrines()
		if pd.is_empty():
			lines.append("Доктрина: нет (порог 300)")
		else:
			lines.append("Доступны доктрины (одна активная):")
			for tid5 in pd:
				lines.append("  · %s" % doctrine_preview(str(tid5)))
	lines.append("")
	lines.append("[i]Смена ветки недоступна. Одна доктрина за раз. Ложноположительные сигналы поиска возможны.[/i]")
	if lesson_unlocked("thrift"):
		lines.append("Урок экономности: разумные подарки сильнее, люкс без смысла слабее; −10% цены для экономных.")
	if rule_unlocked("thrift"):
		lines.append("Авто / экономность: реже берёт «просто дорогое» без совпадения профиля.")
	if get_branch("thrift") == "A":
		lines.append("Ветка A: −8% ко всем подаркам.")
	elif get_branch("thrift") == "B":
		lines.append("Ветка B: −8% к найму персонала.")
	elif get_branch("thrift") == "C":
		lines.append("Ветка C: возврат части стоимости подарка при провале.")
	return "\n".join(lines)


func to_dict() -> Dictionary:
	return {
		"contributors": contributors.duplicate(true),
		"counts": counts.duplicate(true),
		"announced": announced.duplicate(true),
		"branches": branches.duplicate(true),
		"depth_choices": depth_choices.duplicate(true),
		"active_synergies": active_synergies.duplicate(),
		"search_targets": search_targets.duplicate(),
		"institutions": institutions.duplicate(true),
		"active_doctrine": active_doctrine,
		"expansion_reserve": expansion_reserve,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		return
	var c: Dictionary = data.get("contributors", {})
	var n: Dictionary = data.get("counts", {})
	var a: Dictionary = data.get("announced", {})
	var br: Dictionary = data.get("branches", {})
	var dc: Dictionary = data.get("depth_choices", {})
	for tid in TRAIT_IDS:
		if c.has(tid):
			contributors[tid] = (c[tid] as Array).duplicate()
		if n.has(tid):
			counts[tid] = int(n[tid])
		if br.has(tid):
			var bv := str(br[tid]).to_upper()
			if bv in ["A", "B", "C"]:
				branches[tid] = bv
		if dc.has(tid):
			var dv := str(dc[tid]).to_lower()
			if dv in ["deepen", "expand"]:
				depth_choices[tid] = dv
	announced = a.duplicate(true)
	active_synergies.clear()
	for sid in data.get("active_synergies", []):
		var s := str(sid)
		if SYNERGY_DEFS.has(s) and not active_synergies.has(s):
			active_synergies.append(s)
	search_targets.clear()
	for st in data.get("search_targets", []):
		var stid := normalize_trait(str(st))
		if stid.is_empty() or search_targets.has(stid):
			continue
		search_targets.append(stid)
		if search_targets.size() >= 2:
			break
	var inst: Dictionary = data.get("institutions", {})
	for tid in TRAIT_IDS:
		institutions[tid] = bool(inst.get(tid, false))
	var ad := normalize_trait(str(data.get("active_doctrine", "")))
	active_doctrine = ad if DOCTRINE_DEFS.has(ad) else ""
	expansion_reserve = float(data.get("expansion_reserve", 0.0))
	# Reconcile with live girls (source of truth).
	recount(false)
	_sync_world_flags()
