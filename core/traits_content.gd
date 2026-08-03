class_name TraitsContent
extends RefCounted
## Character traits + date dialogues (1 correct / 1 neutral / 1 wrong per card).
## Influence IDs (8) drive orbit trees; dialogue keys map onto those IDs.
## Domains do not overlap: a correct answer for trait A is never correct for B.


const TIER_TRAIT_COUNT := {
	"simple": 2,
	"medium": 2,
	"high": 2,
}

const TIER_REWARD_MULT := {
	"simple": 1.0,
	"medium": 1.45,
	"high": 2.1,
}

const INFLUENCE_IDS: Array[String] = [
	"thrift", "generous", "punctual", "attentive", "calm", "ambitious", "daring", "witty",
]

## Influence ↔ date dialogue key (generosity axis covers generous; thrift has own cards).
const INFLUENCE_TO_DIALOGUE := {
	"thrift": "thrift",
	"generous": "generosity",
	"punctual": "time",
	"attentive": "attention",
	"calm": "peace",
	"ambitious": "ambition",
	"daring": "adventure",
	"witty": "humor",
}

const DIALOGUE_TO_INFLUENCE := {
	"thrift": "thrift",
	"generosity": "generous",
	"time": "punctual",
	"attention": "attentive",
	"peace": "calm",
	"ambition": "ambitious",
	"adventure": "daring",
	"humor": "witty",
	"punctual": "punctual",
	"attentive": "attentive",
	"calm": "calm",
	"ambitious": "ambitious",
	"daring": "daring",
	"witty": "witty",
	"generous": "generous",
}

## Prep-tag soft affinities so gifts/venues still matter.
const TRAIT_PREP_TAGS := {
	"time": ["order", "sincere"],
	"attention": ["sincere", "calm", "romantic"],
	"generosity": ["luxury", "romantic", "tasty"],
	"thrift": ["cheap", "order", "sincere"],
	"adventure": ["sport", "active", "space", "weird"],
	"peace": ["calm", "cheap", "sincere"],
	"ambition": ["business", "luxury", "media", "order"],
	"humor": ["media", "weird", "casual", "absurd"],
}

const QUIRK_POOL: Array[String] = [
	"rare_books",
	"late_tea",
	"plant_talk",
	"tiny_rituals",
	"street_photos",
	"old_movies",
	"spicy_food",
	"night_walks",
	"board_games",
	"vinyl",
	"cat_videos",
	"budget_travel",
]

const QUIRK_NAMES := {
	"rare_books": "любит редкие книги",
	"late_tea": "пьёт чай только поздно вечером",
	"plant_talk": "разговаривает с растениями",
	"tiny_rituals": "держит мелкие личные ритуалы",
	"street_photos": "собирает уличные кадры",
	"old_movies": "цитирует старое кино",
	"spicy_food": "гоняется за острым",
	"night_walks": "гуляет только ночью",
	"board_games": "тащит в настолки",
	"vinyl": "слушает винил",
	"cat_videos": "лечится котами в ленте",
	"budget_travel": "планирует поездки до копейки",
	"quiet_correction": "замечает бытовой диссонанс раньше всех",
	"series_impulse": "серия точных встреч даёт ей импульс",
	"dry_absurd": "сушит абсурд одной фразой",
	"viral_risk": "риск вирусного момента — её норма",
	"reinvest": "мыслит тратами как реинвестированием",
	"visual_brand": "читает образ как бренд",
	"precise_plate": "цена и вкус для неё одно уравнение",
	"clean_alibi": "любит формулировки без дыр",
	"sync_check": "ловит микросбои в жестах",
	"status_gift": "крупный жест = статус",
	"calm_chaos": "спокойно смотрит на неизвестный риск",
	"template_break": "ломает готовые шаблоны",
}


static func traits() -> Dictionary:
	return {
		"time": {
			"id": "time",
			"name": "Пунктуальность",
			"short": "ценит время",
			"hint": "Договорённости и опоздания важны.",
		},
		"attention": {
			"id": "attention",
			"name": "Внимание",
			"short": "хочет, чтобы слушали",
			"hint": "Ей важно, что ты помнишь детали о ней.",
		},
		"generosity": {
			"id": "generosity",
			"name": "Щедрость",
			"short": "ценит щедрость",
			"hint": "Скупость бьёт по настроению.",
		},
		"thrift": {
			"id": "thrift",
			"name": "Экономность",
			"short": "не любит переплат",
			"hint": "Цена и смысл траты важнее статуса.",
		},
		"adventure": {
			"id": "adventure",
			"name": "Азарт",
			"short": "любит новое",
			"hint": "Скучный шаблон — плохой знак.",
		},
		"peace": {
			"id": "peace",
			"name": "Спокойствие",
			"short": "ценит уют",
			"hint": "Шум и скандал ей неприятны.",
		},
		"ambition": {
			"id": "ambition",
			"name": "Амбиции",
			"short": "уважает цели",
			"hint": "Статус и планы — не пустой звук.",
		},
		"humor": {
			"id": "humor",
			"name": "Юмор",
			"short": "любит шутки",
			"hint": "Лёгкость важнее пафоса.",
		},
	}


static func all_trait_ids() -> Array:
	## Dialogue keys used on dates (includes thrift pole).
	return ["time", "attention", "generosity", "thrift", "adventure", "peace", "ambition", "humor"]


static func all_influence_ids() -> Array:
	return INFLUENCE_IDS.duplicate()


static func trait_count_for_tier(tier: String) -> int:
	return int(TIER_TRAIT_COUNT.get(tier, 2))


static func reward_mult(tier: String) -> float:
	return float(TIER_REWARD_MULT.get(tier, 1.0))


static func to_influence(raw: String) -> String:
	return str(DIALOGUE_TO_INFLUENCE.get(str(raw), ""))


static func to_dialogue(influence_id: String) -> String:
	return str(INFLUENCE_TO_DIALOGUE.get(str(influence_id), ""))


static func dialogue_traits_from_primaries(primaries: Array) -> Array:
	var out: Array = []
	for p in primaries:
		var dkey := to_dialogue(str(p))
		if dkey.is_empty():
			dkey = str(p)
		if not out.has(dkey):
			out.append(dkey)
	return out


static func sanitize_primaries(raw: Array) -> Array:
	var out: Array = []
	var has_spend_pole := false
	for p in raw:
		var tid := to_influence(str(p))
		if tid.is_empty() and INFLUENCE_IDS.has(str(p)):
			tid = str(p)
		if tid.is_empty() or out.has(tid):
			continue
		if tid == "thrift" or tid == "generous":
			if has_spend_pole:
				continue
			has_spend_pole = true
		out.append(tid)
		if out.size() >= 2:
			break
	while out.size() < 2:
		var pool: Array = all_influence_ids()
		pool.shuffle()
		for cand in pool:
			var c := str(cand)
			if out.has(c):
				continue
			if (c == "thrift" or c == "generous") and has_spend_pole:
				continue
			out.append(c)
			if c == "thrift" or c == "generous":
				has_spend_pole = true
			break
	return out.slice(0, 2)


static func pick_primary_pair(bias_tags: Array = []) -> Array:
	var pool: Array = all_influence_ids()
	# Soft bias from likes/tags and explicit influence ids (search).
	var preferred: Array = []
	for tag in bias_tags:
		var raw := str(tag)
		if INFLUENCE_IDS.has(raw):
			preferred.append(raw)
			continue
		var as_inf := to_influence(raw)
		if not as_inf.is_empty():
			preferred.append(as_inf)
			continue
		match raw:
			"cheap", "order":
				preferred.append("thrift")
			"luxury", "romantic":
				preferred.append("generous")
			"sport", "active", "chaos":
				preferred.append("daring")
				preferred.append("punctual")
			"calm", "sincere":
				preferred.append("calm")
				preferred.append("attentive")
			"business":
				preferred.append("ambitious")
				preferred.append("thrift")
			"media", "weird", "scandal":
				preferred.append("witty")
				preferred.append("daring")
			"fashion":
				preferred.append("attentive")
				preferred.append("ambitious")
			"tech", "science":
				preferred.append("attentive")
				preferred.append("punctual")
			_:
				pass
	var first := ""
	if not preferred.is_empty() and randf() < 0.7:
		first = str(preferred[randi() % preferred.size()])
	else:
		first = str(pool[randi() % pool.size()])
	var second := ""
	var guard := 0
	while second.is_empty() and guard < 24:
		guard += 1
		var cand := ""
		if not preferred.is_empty() and randf() < 0.55:
			cand = str(preferred[randi() % preferred.size()])
		else:
			cand = str(pool[randi() % pool.size()])
		if cand == first:
			continue
		if (first == "thrift" and cand == "generous") or (first == "generous" and cand == "thrift"):
			continue
		second = cand
	if second.is_empty():
		for cand2 in pool:
			var c2 := str(cand2)
			if c2 == first:
				continue
			if (first == "thrift" and c2 == "generous") or (first == "generous" and c2 == "thrift"):
				continue
			second = c2
			break
	return sanitize_primaries([first, second])


static func pick_quirk(forced: String = "") -> String:
	if forced != "" and QUIRK_NAMES.has(forced):
		return forced
	return str(QUIRK_POOL[randi() % QUIRK_POOL.size()])


static func quirk_label(quirk_id: String) -> String:
	return str(QUIRK_NAMES.get(quirk_id, quirk_id))


static func pack_for_profile(profile: Dictionary = {}) -> Dictionary:
	var primaries: Array = profile.get("primary_traits", [])
	if primaries.is_empty():
		primaries = pick_primary_pair(profile.get("likes", []))
	else:
		primaries = sanitize_primaries(primaries)
	var quirk := str(profile.get("quirk", ""))
	if quirk.is_empty():
		quirk = pick_quirk()
	return {
		"primary_traits": primaries,
		"traits": dialogue_traits_from_primaries(primaries),
		"quirk": quirk,
	}


static func dialogues() -> Array:
	## Each card is locked to one trait. Wrong answers are the antithesis of that trait only.
	var out: Array = []
	out.append_array(_time_cards())
	out.append_array(_attention_cards())
	out.append_array(_generosity_cards())
	out.append_array(_thrift_cards())
	out.append_array(_adventure_cards())
	out.append_array(_peace_cards())
	out.append_array(_ambition_cards())
	out.append_array(_humor_cards())
	return out


static func dialogues_for(trait_id: String) -> Array:
	var key := str(trait_id)
	var dkey := to_dialogue(key)
	if not dkey.is_empty():
		key = dkey
	var out: Array = []
	for d in dialogues():
		if str(d.get("trait", "")) == key:
			out.append(d)
	return out


static func _card(card_id: String, trait_id: String, prompt: String, correct_label: String, wrong_label: String, neutral_label: String) -> Dictionary:
	var alt: String = _alt_interpret(trait_id)
	return {
		"id": card_id,
		"trait": trait_id,
		"observation": prompt,
		"prompt": prompt,
		"options": [
			{"id": card_id + "_c", "label": correct_label, "interpret": trait_id, "quality": "good"},
			{"id": card_id + "_w", "label": wrong_label, "interpret": alt, "quality": "bad"},
			{"id": card_id + "_n", "label": neutral_label, "interpret": "", "quality": "ok"},
		],
		## Legacy keys kept for any old readers.
		"correct": {"id": card_id + "_c", "label": correct_label, "polarity": "correct", "interpret": trait_id, "quality": "good"},
		"wrong": {"id": card_id + "_w", "label": wrong_label, "polarity": "wrong", "interpret": alt, "quality": "bad"},
		"neutral": {"id": card_id + "_n", "label": neutral_label, "polarity": "neutral", "interpret": "", "quality": "ok"},
	}


static func _alt_interpret(trait_id: String) -> String:
	## Distinct wrong reading — never the same axis as the card trait.
	var map: Dictionary = {
		"time": "adventure",
		"attention": "ambition",
		"generosity": "thrift",
		"thrift": "generosity",
		"adventure": "time",
		"peace": "humor",
		"ambition": "attention",
		"humor": "peace",
	}
	return str(map.get(trait_id, "attention"))


static func _time_cards() -> Array:
	return [
		_card("time_late", "time",
			"Она взглянула на часы: «Ты часто опаздываешь?»",
			"Признаю и предлагаю чёткий план, как не опаздывать",
			"«Время — условность, расслабься»",
			"Спросить, какой у неё любимый чай"),
		_card("time_plan", "time",
			"Вечер плывёт. Она спрашивает: «У нас вообще есть план?»",
			"Коротко проговорить следующий час по пунктам",
			"«Поплывём как получится, планы — для слабаков»",
			"Заметить, что в зале играет приятная музыка"),
		_card("time_wait", "time",
			"Официант задерживается. Она молча ждёт.",
			"Извиниться за ожидание и предложить запасной вариант",
			"Начать громко жаловаться всем вокруг",
			"Просто посидеть молча, глядя в окно"),
	]


static func _attention_cards() -> Array:
	return [
		_card("att_story", "attention",
			"Она рассказывает длинную историю про свой день.",
			"Слушать до конца и уточнить одну деталь",
			"Перебить и рассказать про свой день громче",
			"Кивнуть и поправить салфетку"),
		_card("att_detail", "attention",
			"«Помнишь, о чём я говорила в прошлый раз?»",
			"Вспомнить и связать с тем, что она сказала сейчас",
			"«Не помню, давай о чём-нибудь важном — обо мне»",
			"Предложить заказать воды"),
		_card("att_phone", "attention",
			"Телефон вибрирует у тебя в кармане посреди её фразы.",
			"Убрать телефон и вернуть взгляд к ней",
			"Достать и листать ленту, «слушая» краем уха",
			"Глянуть на меню заведения"),
	]


static func _generosity_cards() -> Array:
	return [
		_card("gen_bill", "generosity",
			"Приносят счёт. Она смотрит, не давит.",
			"Спокойно взять счёт на себя",
			"Делить до копейки и спорить из принципа",
			"Спросить, нравится ли ей десерт в витрине"),
		_card("gen_gift", "generosity",
			"Разговор заходит о подарках «просто так».",
			"Сказать, что любишь делать приятное без повода",
			"«Подарки — пустая трата, лучше экономить»",
			"Спросить, какая погода завтра"),
		_card("gen_upgrade", "generosity",
			"Ей явно хочется вариант поинтереснее в меню.",
			"Предложить взять то, что ей глаза зажгло",
			"Настоять на самом дешёвом «и так сойдёт»",
			"Попросить у официанта ещё салфеток"),
	]


static func _thrift_cards() -> Array:
	return [
		_card("thr_bill", "thrift",
			"Счёт на столе. Она уже сравнила цены в меню.",
			"Предложить разумный вариант без переплаты",
			"Заказать самое дорогое «чтобы впечатлить»",
			"Спросить, какая у неё любимая песня"),
		_card("thr_gift", "thrift",
			"Она замечает ценник на витрине и хмурится.",
			"Согласиться: смысл важнее цены на ценнике",
			"Сказать, что дешёвое — всегда стыдно",
			"Посмотреть в окно"),
		_card("thr_plan", "thrift",
			"«Может, не обязательно брать премиум?»",
			"Поддержать и найти качество за честную цену",
			"Настоять на люксе ради статуса",
			"Спросить, далеко ли до метро"),
	]


static func _adventure_cards() -> Array:
	return [
		_card("adv_spot", "adventure",
			"«Может, после этого свернём куда-то необычное?»",
			"Согласиться и предложить свежую идею",
			"«Нет, только проверенный маршрут как всегда»",
			"Спросить, какой у неё знак зодиака"),
		_card("adv_risk", "adventure",
			"Рядом странный стенд / аттракцион / выставка.",
			"Предложить заглянуть «на пять минут»",
			"Отмахнуться: «Ерунда для детей»",
			"Проверить, не осталось ли на столе вилки"),
		_card("adv_plan", "adventure",
			"Она шутит про спонтанный мини-побег из рутины.",
			"Подхватить идею и добавить свой крутой штрих",
			"Занудно объяснить, почему «так нельзя»",
			"Кивнуть и отпить из стакана"),
	]


static func _peace_cards() -> Array:
	return [
		_card("peace_noise", "peace",
			"Где-то рядом начинается громкая сцена.",
			"Увести разговор в тихую сторону / сменить место",
			"Влезть в скандал и накалить ещё сильнее",
			"Проверить зарядку телефона"),
		_card("peace_pace", "peace",
			"Вечер можно ускорить «ради драйва» или замедлить.",
			"Предложить спокойный темп без спешки",
			"Тащить её в шумную толпу назло уюту",
			"Спросить, как ей освещение"),
		_card("peace_end", "peace",
			"Пора закругляться. Какой финал ей ближе?",
			"Тихий тёплый финал без лишнего шума",
			"Устроить эпатажный финал на весь зал",
			"Поправить стул и встать ровнее"),
	]


static func _ambition_cards() -> Array:
	return [
		_card("amb_goals", "ambition",
			"Она говорит о своих планах на год.",
			"Серьёзно поддержать и спросить следующий шаг",
			"Отшутиться: «Ну ты и замахнулась, мечтательница»",
			"Спросить, какой соус у неё в тарелке"),
		_card("amb_work", "ambition",
			"Всплывает тема работы и статуса.",
			"Отнестись уважительно к её вкладу и целям",
			"Сказать, что карьера — ерунда рядом с «кайфом»",
			"Посмотреть на декор стен"),
		_card("amb_flex", "ambition",
			"Кто-то рядом хвастается пустыми словами.",
			"Спокойно показать, что ценишь реальные результаты",
			"Начать хвастаться ещё громче и пустее",
			"Попросить принести хлеб"),
	]


static func _humor_cards() -> Array:
	return [
		_card("hum_joke", "humor",
			"В разговоре зависла пауза.",
			"Разрядить лёгкой шуткой в тему",
			"Сесть камнем и говорить только серьёзным тоном",
			"Протереть край стакана салфеткой"),
		_card("hum_fail", "humor",
			"Мелкая неловкость: что-то пролилось / стул скрипнул.",
			"Пошутить над ситуацией и продолжить легко",
			"Раздуть из мухи трагедию на весь вечер",
			"Тихо подозвать официанта"),
		_card("hum_tease", "humor",
			"Она подколола тебя дружески.",
			"Ответить в том же лёгком ключе",
			"Обидеться и читать нотацию «это несмешно»",
			"Спросить дорогу до выхода"),
	]
