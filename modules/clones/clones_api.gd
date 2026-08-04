class_name ClonesAPI
extends Node
## Hero doubles: grow → personal acceptance → deploy. Not "order a clone".

signal clones_changed
signal acceptance_open(payload: Dictionary)
signal acceptance_close
signal acceptance_step(step_index: int, payload: Dictionary)

var clones: Array = []
var max_slots: int = 0
var busy: Dictionary = {}
var pending: Dictionary = {} ## active acceptance draft
var _accept_step: int = 0
var deferred_hits: Array = [] ## skipped defects → delayed world events

const ACCEPT_STEPS: Array = [
	{"id": "look", "title": "Общий вид", "prompt": "Сравни рост, волосы, одежду и аксессуары с эталоном."},
	{"id": "detail", "title": "Детали", "prompt": "Проверь часы (время!), браслет, обувь, подпись."},
	{"id": "motion", "title": "Движение", "prompt": "Дорожка: шаг, поворот, жест руки."},
	{"id": "schedule", "title": "Время и маршрут", "prompt": "Спроси время, ближайшее свидание и маршрут."},
	{"id": "memory", "title": "Память", "prompt": "Первая девушка, подтверждённая черта, обещание, подарок."},
	{"id": "decide", "title": "Решение", "prompt": "Одобрить, условно, на доработку или утилизировать."},
]


func setup(_game: Node) -> void:
	reset()


func reset() -> void:
	clones.clear()
	busy.clear()
	max_slots = 0
	pending.clear()
	_accept_step = 0
	deferred_hits.clear()


func can_create() -> bool:
	if not pending.is_empty():
		return false
	var effects: Dictionary = Game.girls.active_effects()
	if not Game.girls.is_met(&"scientist") and not bool(effects.get("unlock_clones", false)):
		return false
	return _deployed_count() < maxi(1, max_slots + int(Game.upgrades.effect_value("clone_slots")))


func _deployed_count() -> int:
	var n: int = 0
	for c in clones:
		var st: String = str(c.get("status", "approved"))
		if st in ["approved", "conditional"]:
			n += 1
	return n


func create_clone() -> bool:
	## Legacy entry: starts personal acceptance instead of instant deploy.
	return begin_acceptance()


func begin_acceptance() -> bool:
	if not pending.is_empty():
		EventBus.toast("Сначала заверши текущую приёмку", &"warn")
		return false
	_ensure_accept_ui()
	if not Game.girls.is_met(&"scientist") and not bool(Game.girls.active_effects().get("unlock_clones", false)):
		EventBus.toast("Сначала познакомься с Учёной", &"warn")
		return false
	var slots: int = maxi(1, max_slots + int(Game.upgrades.effect_value("clone_slots")))
	if _deployed_count() >= slots:
		EventBus.toast("Нет свободных слотов дублей", &"warn")
		return false
	var cost: float = 150.0 * float(Game.girls.active_effects().get("clone_cost_mult", 1.0))
	if not Game.upgrades.has_effect("clone_instant"):
		if not Game.economy.try_spend({"money": cost}, &"clone"):
			EventBus.toast("Нужно %.0f$ на выращивание" % cost, &"warn")
			return false
	else:
		Game.economy.try_spend({"money": cost * 0.5}, &"clone")
	var id: String = "clone_%d" % (int(Time.get_unix_time_from_system()) % 100000 + clones.size())
	var defects: Array = _roll_defects(clones.is_empty())
	pending = {
		"id": id,
		"name": "Дубль %s" % Game.names.next_name(),
		"quality": 1.0 + Game.upgrades.effect_value("clone_quality"),
		"reliability": 0.7,
		"fatigue": 0.0,
		"spec": "mass",
		"color": [0.55 + randf() * 0.35, 0.35 + randf() * 0.25, 0.3 + randf() * 0.25],
		"status": "pending",
		"defects": defects,
		"marks": [], ## defect ids the player marked
		"false_marks": 0,
		"paid": cost,
	}
	_accept_step = 0
	EventBus.toast("Капсула готова — личная приёмка", &"clone")
	Game.facility.set_flag("stage_4a", true)
	acceptance_open.emit(_acceptance_payload())
	_emit_step()
	var popup := RevealPopup.ui()
	if popup:
		popup.present_decision("Приёмка дубля", "%s готов к осмотру. Пройди шаги терминала и прими решение." % str(pending.get("name", "Дубль")))
	return true


func _roll_defects(first_double: bool) -> Array:
	var pool: Array = [
		{"id": "hair_wrong", "cat": "look", "step": 0, "label": "Волосы другого оттенка", "text": "Волосы заметно рыжее эталона."},
		{"id": "watch_hour", "cat": "time", "step": 1, "label": "Часы −1 час", "text": "Наручные часы отстают ровно на час."},
		{"id": "left_hand", "cat": "motion", "step": 2, "label": "Ведущая рука", "text": "Жест делает левой — эталон правша."},
		{"id": "route_swap", "cat": "schedule", "step": 3, "label": "Перепутанный маршрут", "text": "Называет чужой маршрут на вечер."},
		{"id": "memory_girl", "cat": "memory", "step": 4, "label": "Память о девушке", "text": "Путает имя первой девушки / черту."},
		{"id": "unstable", "cat": "stability", "step": 2, "label": "Зависание", "text": "На секунду замирает и повторяет фразу."},
	]
	pool.shuffle()
	var count: int = 2 if first_double else (1 + randi() % 3)
	if randf() < 0.12 and not first_double:
		count = 0 ## rare perfect batch
	var out: Array = []
	for i in range(mini(count, pool.size())):
		var d: Dictionary = pool[i].duplicate(true)
		d["found"] = false
		d["skipped"] = false
		out.append(d)
	return out


func _acceptance_payload() -> Dictionary:
	return {
		"id": str(pending.get("id", "")),
		"name": str(pending.get("name", "Дубль")),
		"step": _accept_step,
		"steps_total": ACCEPT_STEPS.size(),
		"marks": pending.get("marks", []).duplicate(),
	}


func _emit_step() -> void:
	if pending.is_empty():
		return
	var step_def: Dictionary = ACCEPT_STEPS[_accept_step]
	var defects_here: Array = []
	for d in pending.get("defects", []):
		if int(d.get("step", -1)) == _accept_step:
			defects_here.append(d.duplicate(true))
	var payload: Dictionary = {
		"step": _accept_step,
		"step_id": str(step_def.get("id", "")),
		"title": str(step_def.get("title", "")),
		"prompt": str(step_def.get("prompt", "")),
		"defects": defects_here,
		"is_decide": _accept_step >= ACCEPT_STEPS.size() - 1,
		"name": str(pending.get("name", "")),
		"marks": pending.get("marks", []).duplicate(),
	}
	acceptance_step.emit(_accept_step, payload)


func mark_defect(defect_id: String) -> void:
	if pending.is_empty():
		return
	var marks: Array = pending.get("marks", []).duplicate()
	var known: bool = false
	for d in pending.get("defects", []):
		if str(d.get("id", "")) == defect_id:
			known = true
			break
	if not known:
		pending["false_marks"] = int(pending.get("false_marks", 0)) + 1
		EventBus.toast("Ложная метка — трата внимания контролёра", &"warn")
		Game.economy.add(&"attention", -0.25, &"false_mark")
		return
	if not marks.has(defect_id):
		marks.append(defect_id)
		pending["marks"] = marks
		EventBus.toast("Проблема отмечена на терминале", &"clone")
		clones_changed.emit()


func clear_mark(defect_id: String) -> void:
	if pending.is_empty():
		return
	var marks: Array = pending.get("marks", []).duplicate()
	marks.erase(defect_id)
	pending["marks"] = marks


func advance_acceptance() -> void:
	if pending.is_empty():
		return
	if _accept_step >= ACCEPT_STEPS.size() - 1:
		return
	_accept_step += 1
	_emit_step()


func decide_acceptance(decision: String) -> bool:
	if pending.is_empty():
		return false
	var marks: Array = pending.get("marks", [])
	var defects: Array = pending.get("defects", []).duplicate(true)
	var latent: Array = []
	var clone_name := str(pending.get("name", "Дубль"))
	for i in range(defects.size()):
		var d: Dictionary = defects[i]
		var did: String = str(d.get("id", ""))
		if marks.has(did):
			d["found"] = true
			d["skipped"] = false
		else:
			d["found"] = false
			d["skipped"] = true
			latent.append(d.duplicate(true))
		defects[i] = d
	match decision:
		"approve":
			_deploy_pending("approved", defects, latent)
			if not latent.is_empty():
				EventBus.toast("Одобрен, но %d дефект(ов) не отмечены — риск в мире" % latent.size(), &"warn")
			else:
				EventBus.toast("%s принят в строй" % str(pending.get("name", "Дубль")), &"clone")
			_present_clone_decision(clone_name, "Одобрен в строй")
		"conditional":
			_deploy_pending("conditional", defects, latent)
			EventBus.toast("Условный выпуск — усиленный контроль", &"clone")
			_present_clone_decision(clone_name, "Условно одобрен")
		"rework":
			var refund: float = float(pending.get("paid", 0)) * 0.35
			Game.economy.add(&"money", refund, &"clone_rework")
			EventBus.toast("На доработку. Возврат %.0f$" % refund, &"info")
			_present_clone_decision(clone_name, "На доработку")
			_clear_pending()
		"scrap":
			EventBus.toast("Экземпляр утилизирован", &"warn")
			Game.economy.damage_legend(1.0, &"scrap_double")
			_present_clone_decision(clone_name, "Утилизирован")
			_clear_pending()
		_:
			return false
	return true


func _present_clone_decision(clone_name: String, decision_label: String) -> void:
	var popup := RevealPopup.ui()
	if popup:
		popup.present_clone(clone_name, decision_label)


func _deploy_pending(status: String, defects: Array, latent: Array) -> void:
	var entry: Dictionary = pending.duplicate(true)
	entry["status"] = status
	entry["defects"] = defects
	entry["latent_defects"] = latent
	entry["reliability"] = 0.85 if latent.is_empty() else 0.55
	if status == "conditional":
		entry["reliability"] = minf(float(entry["reliability"]), 0.5)
	entry.erase("marks")
	entry.erase("false_marks")
	entry.erase("paid")
	clones.append(entry)
	if _deployed_count() == 1:
		Game.dating.raise_automation(2)
		Game.quests.complete("s4_clone")
		Game.facility.set_flag("stage_4b", true)
	_schedule_latent_hits(entry)
	_clear_pending()
	clones_changed.emit()


func _clear_pending() -> void:
	pending.clear()
	_accept_step = 0
	acceptance_close.emit()
	clones_changed.emit()


func _ensure_accept_ui() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	if not tree.get_nodes_in_group("clone_accept_ui").is_empty():
		return
	var script_res: Script = load("res://scenes/ui/clone_accept_ui.gd") as Script
	if script_res == null:
		return
	var ui := CanvasLayer.new()
	ui.set_script(script_res)
	ui.name = "CloneAcceptUI"
	var host: Node = tree.current_scene
	if host == null:
		host = tree.root
	host.add_child(ui)


func available_count() -> int:
	var n := 0
	for c in clones:
		var st: String = str(c.get("status", "approved"))
		if st != "approved" and st != "conditional":
			continue
		var id := str(c.get("id", ""))
		if not bool(busy.get(id, false)) and float(c.get("fatigue", 0)) < 0.9:
			n += 1
	return n


func assign_to_date() -> String:
	for c in clones:
		var st: String = str(c.get("status", "approved"))
		if st != "approved" and st != "conditional":
			continue
		var id := str(c.get("id", ""))
		if bool(busy.get(id, false)):
			continue
		if float(c.get("fatigue", 0)) >= 0.9:
			continue
		busy[id] = true
		return id
	return "manager"


func finish_date(clone_id: String) -> void:
	busy[clone_id] = false
	for i in range(clones.size()):
		if str(clones[i].get("id", "")) == clone_id:
			var fat: float = 0.2 * Game.upgrades.effect_value("clone_fatigue_mult", 1.0)
			if str(clones[i].get("status", "")) == "conditional":
				fat *= 1.25
			clones[i]["fatigue"] = minf(1.0, float(clones[i].get("fatigue", 0)) + fat)
			break
	clones_changed.emit()


func roll_error() -> StringName:
	var chance: float = 0.18 * Game.upgrades.effect_value("clone_error_mult", 1.0)
	chance *= float(Game.girls.active_effects().get("clone_error_mult", 1.0))
	if randf() > chance:
		return &""
	var errs := [&"wrong_gift", &"wrong_outfit", &"wrong_place", &"forgot_ending", &"argument"]
	return errs[randi() % errs.size()]


func tick_recover(delta: float) -> void:
	var rate := 0.05 * delta
	if Game.staff.has_effect("clone_recover"):
		rate *= 2.0
	for i in range(clones.size()):
		clones[i]["fatigue"] = maxf(0.0, float(clones[i].get("fatigue", 0)) - rate)


func _schedule_latent_hits(entry: Dictionary) -> void:
	var latent: Array = entry.get("latent_defects", [])
	if latent.is_empty():
		return
	var delay: float = 5.0
	for d in latent:
		deferred_hits.append({
			"clone_id": str(entry.get("id", "")),
			"clone_name": str(entry.get("name", "Дубль")),
			"defect": d.duplicate(true),
			"due": delay,
		})
		delay += 8.0 + randf() * 6.0
	EventBus.toast("Неотмеченные дефекты проявятся в мире позже", &"warn")


func _tick_deferred_hits(delta: float) -> void:
	if deferred_hits.is_empty():
		return
	# Pause wall-clock due while an event is open OR shared auto-interval is closed.
	# Do not burn due → 0 spam / retry loops while waiting on the 10 game-minute gate.
	if not Game.events.active.is_empty():
		return
	if not Game.events.can_open_auto_event():
		return
	var remain: Array = []
	var fired: bool = false
	for hit in deferred_hits:
		hit["due"] = float(hit.get("due", 1.0)) - delta
		if fired:
			if float(hit.get("due", 0)) <= 0.0:
				hit["due"] = 5.0
			remain.append(hit)
			continue
		if float(hit["due"]) > 0.0:
			remain.append(hit)
			continue
		# Interval ready + no active event: fire at most one hit this tick.
		if not _fire_latent_hit(hit):
			hit["due"] = 2.0
			remain.append(hit)
			continue
		fired = true
	deferred_hits = remain


func _fire_latent_hit(hit: Dictionary) -> bool:
	var defect: Dictionary = hit.get("defect", {})
	var cat: String = str(defect.get("cat", "look"))
	var label: String = str(defect.get("label", defect.get("id", "дефект")))
	var clone_name: String = str(hit.get("clone_name", "Дубль"))
	var legend_hit: float = 4.0
	var scandal_hit: float = 1.0
	var blurb: String = "Пропущенный дефект дубля всплыл в мире."
	match cat:
		"look":
			blurb = "Кто-то сфотографировал %s — образ не совпадает с эталоном (%s)." % [clone_name, label]
			legend_hit = 8.0
			scandal_hit = 2.0
		"time":
			blurb = "%s опоздал: часы/расписание врут (%s)." % [clone_name, label]
			legend_hit = 5.0
			scandal_hit = 1.5
		"motion":
			blurb = "На записи видно: %s жестикулирует не как ты (%s)." % [clone_name, label]
			legend_hit = 6.0
		"schedule":
			blurb = "%s поехал не туда (%s). Маршруты пересеклись." % [clone_name, label]
			legend_hit = 9.0
			scandal_hit = 2.5
		"memory":
			blurb = "%s перепутал имя/черту (%s). Она заметила." % [clone_name, label]
			legend_hit = 7.0
		"stability":
			blurb = "%s завис и повторил фразу (%s) при свидетелях." % [clone_name, label]
			legend_hit = 6.5
			scandal_hit = 2.0
	return Game.events.open_runtime_event({
		"id": "latent_%s" % str(defect.get("id", "x")),
		"name": "Последствие пропуска: %s" % label,
		"blurb": blurb,
		"choices": [
			{"id": "cover", "label": "Замять и усилить алиби", "scandal": scandal_hit * 0.5, "legend": -legend_hit * 0.4, "money": -25.0},
			{"id": "admit_fix", "label": "Отозвать дубль и починить", "scandal": 0.0, "legend": -legend_hit * 0.2, "money": -40.0},
			{"id": "ignore", "label": "Игнорировать", "scandal": scandal_hit, "legend": -legend_hit, "money": 0.0},
		],
	})


func _process(delta: float) -> void:
	if Game.run_started:
		tick_recover(delta)
		_tick_deferred_hits(delta)


func to_dict() -> Dictionary:
	return {
		"clones": clones.duplicate(true),
		"max_slots": max_slots,
		"pending": pending.duplicate(true),
		"accept_step": _accept_step,
		"deferred_hits": deferred_hits.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	clones = data.get("clones", [])
	for i in range(clones.size()):
		if not clones[i].has("status"):
			clones[i]["status"] = "approved"
		if not clones[i].has("latent_defects"):
			clones[i]["latent_defects"] = []
	max_slots = int(data.get("max_slots", 0))
	pending = data.get("pending", {})
	_accept_step = int(data.get("accept_step", 0))
	deferred_hits = data.get("deferred_hits", [])
	busy.clear()
	clones_changed.emit()
	if not pending.is_empty():
		acceptance_open.emit(_acceptance_payload())
		_emit_step()
