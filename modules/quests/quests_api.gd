class_name QuestsAPI
extends Node
## Sequential tutorial + stage goals. Main steps cannot be skipped.
## HUD goal + tip/toast both read current_step_id() / primary_text().

signal quests_changed

const STAGE1_MAIN_ORDER: Array[String] = [
	"s1_money", "s1_outfit", "s1_prepare",
	"s1_city", "s1_date", "s1_profile", "s1_contact", "s1_expand",
]

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
			_add("s1_money", "1/8 Поработай на кровати, затем зайди в городской магазин", "main")
			_add("s1_outfit", "2/8 Смени одежду в шкафу", "main")
			_add("s1_prepare", "3/8 В телефоне назначь свидание (дом или ресторан + время)", "main")
			_add("s1_city", "4/8 Подготовь стол дома или выйди к ресторану Two Hearts", "main")
			_add("s1_date", "5/8 Проведи свидание и нажми «Завершить»", "main")
			_add("s1_profile", "6/8 В телефоне открой Журнал Соседки — там видно, как складываются отношения", "main")
			_add("s1_contact", "7/8 Заполучи ещё один номер — поговори с любой девушкой", "main")
			_add("s1_expand", "8/8 Набери 5⭐ и открой дверь расширения (+X)", "main")
		"stage_2":
			_add("s2_girls", "Познакомься с новой уникальной девушкой через телефон", "main")
			_add("s2_hire", "В рабочем уголке найми менеджера переписки", "main")
			_add("s2_venues", "Открой кафе или парк по афишам", "side")
			_add("s2_expand", "Когда хватит ⭐ и денег — расширь комплекс до операционного штаба", "main")
		"stage_3":
			_add("s3_scientist", "Познакомься с Учёной (нужна популярность)", "main")
			_add("s3_staff", "Найми ещё сотрудников в штабе", "side")
			_add("s3_lab", "Расширь комплекс к особняку / лаборатории", "main")
		"stage_4":
			_add("s4_clone", "4A: в лаборатории создай первого дубля", "main")
			_add("s4_parallel", "4C: параллель ты + дубль без провала легенды", "main")
			_add("s4_harem", "Посети жилую часть орбиты", "side")
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
	if Game != null and Game.run_started:
		tip_current()


func _add(id: String, label: String, kind: String) -> void:
	if completed.has(id):
		active.append({"id": id, "label": label, "kind": kind, "done": true})
		return
	active.append({"id": id, "label": label, "kind": kind, "done": false})


func is_done(id: String) -> bool:
	return completed.has(id)


func can_do(action: StringName) -> bool:
	## Hard gates for stage 1 tutorial sequence (must match current HUD step).
	if str(Game.stage_id) != "stage_1":
		return true
	match str(action):
		"phone":
			return true
		"book_date", "schedule":
			## Step 3 — booking only after money + wardrobe.
			return is_done("s1_money") and is_done("s1_outfit")
		"job":
			## Step 1 — earn money / visit shop from the start.
			return true
		"buy_gift", "take_gift", "open_flower_shop", "open_jewelry_shop", "open_gift_shop", "open_bookstore", "open_clothing_shop", "open_homeware_shop", "city_buy_gift":
			return true
		"wardrobe":
			return is_done("s1_money")
		"prepare_table", "prepare_and_start", "start_date", "take_food", "take_drink", "place_on_table", "upgrade_homeware", "date_wait_skip", "date_wait_stand":
			return is_done("s1_outfit") and Game.dating.has_scheduled_date()
		"enter_restaurant", "sit_restaurant", "sit_cafe", "sit_park", "sit_cinema", "sit_arcade":
			return Game.dating.has_scheduled_date() and Game.dating.schedule.is_no_prep()
		"expand":
			return is_done("s1_profile") and is_done("s1_contact")
		"go_outside", "talk_girl", "go_neighbor", "go_home", "go_home_from_neighbor":
			return true
		"city_rest", "city_cafe_job", "city_cafe_scroll", "city_coffee", "city_workout", "city_gym_pass", "city_park_fun", "city_bar_drink", "city_karaoke", "city_bus_info", "neighbor_look", "open_arcade":
			return true
		_:
			return true


func gate_hint(_action: StringName) -> String:
	## Always point at the same active step the HUD shows.
	if can_do(_action):
		return ""
	var current: String = primary_text()
	if current != "":
		return "Сначала: %s" % current
	return "Сначала выполни текущую цель"


func current_step_id() -> String:
	## Single source of truth for HUD goal + tip/toast.
	for q in active:
		if not bool(q.get("done", false)) and str(q.get("kind", "")) == "main":
			return str(q.get("id", ""))
	for q in active:
		if not bool(q.get("done", false)):
			return str(q.get("id", ""))
	return ""


func _mains_before_done(id: String) -> bool:
	## Stage-1 mains stay in HUD order — no silent jump ahead via free travel.
	var idx: int = STAGE1_MAIN_ORDER.find(id)
	if idx < 0:
		return true
	for i in range(idx):
		if not is_done(STAGE1_MAIN_ORDER[i]):
			return false
	return true


func tip_current() -> void:
	## Toast describes what to do NOW (matches goal_label / primary_text).
	if Game == null or not Game.run_started:
		return
	var step_id: String = current_step_id()
	if step_id == "":
		return
	var text: String = primary_text()
	if text == "":
		return
	EventBus.toast(text, &"quest")


func complete(id: String) -> void:
	if completed.has(id):
		return
	if not _mains_before_done(id):
		return
	var was_current: bool = current_step_id() == id
	for i in range(active.size()):
		if str(active[i].get("id", "")) == id and not bool(active[i].get("done", false)):
			active[i]["done"] = true
			completed.append(id)
			quests_changed.emit()
			EventBus.quest_updated.emit(StringName(id))
			## Tip the NEW active step — never re-toast the completed previous one.
			if was_current:
				tip_current()
			return


func on_phone_opened() -> void:
	flags["phone_opened"] = true
	## Profile step completes only when the contact profile is opened (after the first date).


func on_profile_seen() -> void:
	flags["profile_seen"] = true
	complete("s1_profile")


func on_date_finished(result: Dictionary) -> void:
	var tid: String = str(result.get("target_id", ""))
	if bool(result.get("unique", false)) or tid == "neighbor":
		complete("s1_date")
		complete("s2_girls")
		if tid == "scientist":
			complete("s3_scientist")
		if tid == "alien":
			complete("s5_alien")
		if tid == "algorithm":
			complete("s6_algo")
			complete("s6_finale")


func primary_text() -> String:
	var step_id: String = current_step_id()
	if step_id != "":
		for q in active:
			if str(q.get("id", "")) == step_id:
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
