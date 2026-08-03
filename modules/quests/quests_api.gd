class_name QuestsAPI
extends Node
## Sequential tutorial + stage goals. Main steps cannot be skipped.

signal quests_changed

var active: Array = []
var completed: Array = []
var flags: Dictionary = {} ## tutorial flags: phone_opened, profile_seen, etc.


func setup(_game: Node) -> void:
	reset_for_stage(&"stage_1")


func reset() -> void:
	flags.clear()
	completed.clear()
	reset_for_stage(Game.stage_id)


func reset_for_stage(stage_id: StringName) -> void:
	active.clear()
	match str(stage_id):
		"stage_1":
			_add("s1_profile", "1/7 Открой телефон (Q или тумба) и посмотри профиль Соседки", "main")
			_add("s1_money", "2/7 Поработай на кровати, затем купи цветок на полке", "main")
			_add("s1_outfit", "3/7 Смени одежду в шкафу", "main")
			_add("s1_prepare", "4/7 Возьми подарок в руки", "main")
			_add("s1_date", "5/7 Подойди к столу: свидание с Соседкой", "main")
			_add("s1_city", "6/7 Выйди на улицу (дверь −X) и найди новый контакт (жёлтый !)", "main")
			_add("s1_contact", "6/7 Поговори с отмеченной девушкой и возьми номер", "main")
			_add("s1_expand", "7/7 Набери 5⭐ и жёлтая дверь расширения (+X)", "main")
		"stage_2":
			_add("s2_girls", "Познакомься с новой уникальной девушкой через телефон", "main")
			_add("s2_hire", "В рабочем уголке найми менеджера переписки", "main")
			_add("s2_venues", "Открой кафе или парк по афишам", "side")
			_add("s2_expand", "Когда хватит ⭐ и денег — расширь комплекс до агентства", "main")
		"stage_3":
			_add("s3_scientist", "Познакомься с Учёной (нужна популярность)", "main")
			_add("s3_staff", "Найми ещё сотрудников в агентстве", "side")
			_add("s3_lab", "Расширь комплекс к особняку / лаборатории", "main")
		"stage_4":
			_add("s4_clone", "В лаборатории создай первого клона", "main")
			_add("s4_parallel", "Включи автолинии свиданий", "main")
			_add("s4_harem", "Посети жилую часть гарема", "side")
			_add("s4_factory", "Расширь комплекс до фабрики", "main")
		"stage_5":
			_add("s5_conveyor", "Открой конвейер свиданий", "main")
			_add("s5_alien", "Открой Инопланетянку", "main")
			_add("s5_pr", "Найми PR-менеджера", "side")
			_add("s5_orbit", "Построй орбитальный сектор", "main")
		"stage_6":
			_add("s6_mega", "Собери 3 части мегамашины", "main")
			_add("s6_algo", "Открой Алгоритм Любви", "main")
			_add("s6_finale", "Активируй станции и запусти финальное свидание", "main")
		_:
			_add("pg_continue", "Постгейм: улучшай фабрику, клонов и рекорды", "main")
	quests_changed.emit()
	EventBus.quest_updated.emit(&"refresh")


func _add(id: String, label: String, kind: String) -> void:
	if completed.has(id):
		active.append({"id": id, "label": label, "kind": kind, "done": true})
		return
	active.append({"id": id, "label": label, "kind": kind, "done": false})


func is_done(id: String) -> bool:
	return completed.has(id)


func can_do(action: StringName) -> bool:
	## Hard gates for stage 1 tutorial sequence.
	if str(Game.stage_id) != "stage_1":
		return true
	match str(action):
		"phone", "job":
			return true
		"buy_gift", "take_gift":
			return is_done("s1_profile")
		"wardrobe":
			return is_done("s1_money")
		"prepare_table", "prepare_and_start", "start_date":
			return is_done("s1_outfit") and (Game.inventory.total_gifts() > 0 or Game.inventory.carried_item != &"")
		"expand":
			return is_done("s1_date") and is_done("s1_contact")
		"go_outside", "talk_girl", "go_neighbor", "go_home", "go_home_from_neighbor":
			return true
		"city_rest", "city_buy_gift", "city_cafe_job", "city_cafe_scroll", "city_coffee", "city_workout", "city_gym_pass", "city_park_fun", "city_bar_drink", "city_karaoke", "city_bus_info", "neighbor_look":
			return true
		_:
			return true


func gate_hint(action: StringName) -> String:
	if can_do(action):
		return ""
	match str(action):
		"buy_gift", "take_gift":
			return "Сначала открой телефон и посмотри профиль Соседки"
		"wardrobe":
			return "Сначала заработай и купи подарок"
		"prepare_table", "prepare_and_start", "start_date":
			if not is_done("s1_outfit"):
				return "Сначала смени одежду в шкафу"
			return "Сначала возьми подарок с полки"
		"expand":
			return "Сначала свидание с соседкой и новый контакт в городе"
		_:
			return "Сначала выполни текущую цель"


func complete(id: String) -> void:
	if completed.has(id):
		return
	for i in range(active.size()):
		if str(active[i].get("id", "")) == id and not bool(active[i].get("done", false)):
			active[i]["done"] = true
			completed.append(id)
			EventBus.toast("Цель выполнена: %s" % str(active[i].get("label", id)), &"quest")
			quests_changed.emit()
			EventBus.quest_updated.emit(StringName(id))
			return


func on_phone_opened() -> void:
	flags["phone_opened"] = true
	complete("s1_profile")


func on_profile_seen() -> void:
	flags["profile_seen"] = true
	complete("s1_profile")


func on_date_finished(result: Dictionary) -> void:
	var tid := str(result.get("target_id", ""))
	if bool(result.get("unique", false)) or tid == "neighbor":
		complete("s1_date")
		complete("s2_girls")
		if tid == "neighbor":
			Game.city.pick_tutorial_target()
			EventBus.toast("Выйди в город — найди новую девушку с жёлтым !", &"story")
		if tid == "scientist":
			complete("s3_scientist")
		if tid == "alien":
			complete("s5_alien")
		if tid == "algorithm":
			complete("s6_algo")
			complete("s6_finale")


func primary_text() -> String:
	for q in active:
		if not bool(q.get("done", false)) and str(q.get("kind", "")) == "main":
			return _enrich(str(q.get("label", "")))
	for q in active:
		if not bool(q.get("done", false)):
			return _enrich(str(q.get("label", "")))
	if Game.postgame:
		return "Постгейм: развивай фабрику дальше"
	return "Все текущие цели выполнены — ищи жёлтые точки взаимодействия"


func _enrich(label: String) -> String:
	if label.find("популярности") >= 0 or label.find("расширь") >= 0 or label.find("дверь") >= 0:
		var need: float = float(ContentDB.balance.get("stage_popularity", {}).get("stage_2", 5))
		var have: float = Game.economy.get_value(&"popularity")
		var cost: float = float(ContentDB.stage(Game.stage_id).get("next_cost", 60))
		return "%s  (сейчас ⭐%.0f/%.0f, деньги %.0f/%.0f)" % [label, have, need, Game.economy.get_value(&"money"), cost]
	return label


func to_dict() -> Dictionary:
	return {"active": active.duplicate(true), "completed": completed.duplicate(), "flags": flags.duplicate()}


func from_dict(data: Dictionary) -> void:
	active = data.get("active", [])
	completed = data.get("completed", [])
	flags = data.get("flags", {})
	quests_changed.emit()
