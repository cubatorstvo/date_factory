class_name CrisesAPI
extends Node
## Spatial FPS crises: signal → timer → physical hotspots (not text-only "solve").

signal crisis_started(payload: Dictionary)
signal crisis_progress(payload: Dictionary)
signal crisis_ended(payload: Dictionary)

var active: Dictionary = {}
var calm_until: float = 0.0
var resolved_count: int = 0
var failed_count: int = 0
var _roll_cd: float = 0.0
var _hotspots: Array = [] ## Node refs

const CATALOG: Array = [
	{
		"id": "lights_out", "cat": "tech", "min_stage": "stage_2",
		"signal": "Свет погас в коридоре",
		"threat": "Легенда треснет, если девушка увидит тёмный комплекс",
		"timer": 28.0, "fixes_needed": 1,
		"legend_fail": 6.0, "scandal_fail": 1.5,
		"solutions": [
			{"id": "breaker", "label": "Щиток", "hint": "Включи щиток у входа", "pos": [-2.5, 0.05, 2.0]},
			{"id": "lamp", "label": "Аварийная лампа", "hint": "Зажги лампу у стола", "pos": [1.5, 0.05, 1.2]},
		],
	},
	{
		"id": "stuck_door", "cat": "tech", "min_stage": "stage_2",
		"signal": "Дверь зала заклинило",
		"threat": "Гостья застрянет — слухи полетят",
		"timer": 24.0, "fixes_needed": 1,
		"legend_fail": 5.0, "scandal_fail": 1.0,
		"solutions": [
			{"id": "panel", "label": "Панель двери", "hint": "Открой панель замка", "pos": [3.0, 0.05, 0.0]},
			{"id": "kick", "label": "Рычаг", "hint": "Дёрни аварийный рычаг", "pos": [2.2, 0.05, -1.5]},
		],
	},
	{
		"id": "gift_wrong_hall", "cat": "logistics", "min_stage": "stage_3",
		"signal": "Подарок уехал не в тот зал",
		"threat": "Неверный реквизит сорвёт свидание",
		"timer": 30.0, "fixes_needed": 1,
		"legend_fail": 4.0, "scandal_fail": 0.5,
		"solutions": [
			{"id": "pickup_gift", "label": "Чужой стол", "hint": "Забери подарок со стола", "pos": [-1.0, 0.05, -2.0]},
			{"id": "drop_gift", "label": "Нужный зал", "hint": "Положи подарок в нужный зал", "pos": [4.0, 0.05, -1.0]},
		],
	},
	{
		"id": "two_yous", "cat": "clones", "min_stage": "stage_4", "needs_clones": true,
		"signal": "Два «ты» в одном коридоре",
		"threat": "Кто-то увидит двух одинаковых тебя",
		"timer": 22.0, "fixes_needed": 1,
		"legend_fail": 10.0, "scandal_fail": 3.0,
		"solutions": [
			{"id": "hold_lift", "label": "Лифт", "hint": "Задержи лифт", "pos": [-3.5, 0.05, 0.0]},
			{"id": "close_door", "label": "Дверь", "hint": "Закрой дверь сектора", "pos": [0.0, 0.05, -3.2]},
			{"id": "reroute_double", "label": "Терминал маршрута", "hint": "Перенаправь дубля", "pos": [2.5, 0.05, 1.5]},
		],
	},
	{
		"id": "clone_freeze", "cat": "clones", "min_stage": "stage_4", "needs_clones": true,
		"signal": "Дубль завис на линии",
		"threat": "Повтор фразы при свидетелях",
		"timer": 26.0, "fixes_needed": 1,
		"legend_fail": 7.0, "scandal_fail": 2.0,
		"solutions": [
			{"id": "sync_reboot", "label": "Синхронизация", "hint": "Перезапусти синхронизацию", "pos": [5.0, 0.05, -2.0]},
			{"id": "pull_double", "label": "Шлюз", "hint": "Уведи дубля в шлюз", "pos": [5.5, 0.05, 1.0]},
		],
	},
	{
		"id": "early_guest", "cat": "girls", "min_stage": "stage_3",
		"signal": "Гостья пришла раньше",
		"threat": "Она увидит подготовку или чужой маршрут",
		"timer": 25.0, "fixes_needed": 1,
		"legend_fail": 5.0, "scandal_fail": 1.0,
		"solutions": [
			{"id": "alt_room", "label": "Запасная комната", "hint": "Открой запасную комнату", "pos": [-4.0, 0.05, -2.5]},
			{"id": "delay_chat", "label": "Холл", "hint": "Задержи её разговором в холле", "pos": [0.5, 0.05, 2.5]},
		],
	},
	{
		"id": "journalist", "cat": "public", "min_stage": "stage_3",
		"signal": "Журналист у зоны свиданий",
		"threat": "Фото сломает алиби",
		"timer": 27.0, "fixes_needed": 1,
		"legend_fail": 8.0, "scandal_fail": 2.5,
		"solutions": [
			{"id": "block_cam", "label": "Штора/зона", "hint": "Закрой зону от камер", "pos": [1.0, 0.05, -3.5]},
			{"id": "pr_desk", "label": "PR-стол", "hint": "Отвлеки через PR-стол", "pos": [-2.0, 0.05, 0.5]},
		],
	},
	{
		"id": "memory_desync", "cat": "tech", "min_stage": "stage_4", "needs_clones": true,
		"signal": "Синхронизация памяти зависла",
		"threat": "Дубль перепутает подтверждённую черту",
		"timer": 20.0, "fixes_needed": 2,
		"legend_fail": 9.0, "scandal_fail": 2.0,
		"solutions": [
			{"id": "core_a", "label": "Ядро A", "hint": "Сбрось ядро A", "pos": [3.5, 0.05, 2.0]},
			{"id": "core_b", "label": "Ядро B", "hint": "Сбрось ядро B", "pos": [-3.0, 0.05, -1.0]},
			{"id": "lab_console", "label": "Лаб. консоль", "hint": "Подтверди на лаб. консоли", "pos": [6.0, 0.05, 0.0]},
		],
	},
]


func setup(_game: Node) -> void:
	reset()


func reset() -> void:
	_clear_hotspots()
	active.clear()
	calm_until = 0.0
	resolved_count = 0
	failed_count = 0
	_roll_cd = 8.0


func is_active() -> bool:
	return not active.is_empty()


func hud_text() -> String:
	if active.is_empty():
		return ""
	var left: float = float(active.get("time_left", 0))
	var need: int = int(active.get("fixes_needed", 1))
	var done: int = int(active.get("fixes_done", 0))
	var hints: PackedStringArray = []
	for s in active.get("open_solutions", []):
		hints.append(str(s.get("hint", s.get("label", ""))))
	return "КРИЗИС: %s  [%d/%d]  %.0fс\n%s" % [
		str(active.get("signal", "?")), done, need, left, " · ".join(hints)
	]


func begin_crisis(crisis_id: String) -> bool:
	if is_active():
		return false
	if _blocked():
		return false
	var def: Dictionary = _def(crisis_id)
	if def.is_empty():
		return false
	if not _eligible(def):
		return false
	var fixes: int = int(def.get("fixes_needed", 1))
	var band: String = Game.economy.legend_band()
	if band == "crisis":
		fixes = mini(fixes + 1, def.get("solutions", []).size())
	elif band == "high":
		fixes = 1
	var timer: float = float(def.get("timer", 25.0))
	match band:
		"high":
			timer *= 1.25
		"low":
			timer *= 0.85
		"crisis":
			timer *= 0.7
	var sols: Array = []
	for s in def.get("solutions", []):
		sols.append((s as Dictionary).duplicate(true))
	active = {
		"id": str(def.get("id", crisis_id)),
		"cat": str(def.get("cat", "")),
		"signal": str(def.get("signal", "")),
		"threat": str(def.get("threat", "")),
		"time_left": timer,
		"fixes_needed": fixes,
		"fixes_done": 0,
		"done_ids": [],
		"open_solutions": sols,
		"legend_fail": float(def.get("legend_fail", 5.0)),
		"scandal_fail": float(def.get("scandal_fail", 1.0)),
	}
	_spawn_hotspots()
	_maybe_add_orbit_assist()
	EventBus.toast("КРИЗИС: %s" % str(active["signal"]), &"warn")
	EventBus.bottleneck.emit(&"crisis", str(active["threat"]))
	crisis_started.emit(_payload())
	var popup := RevealPopup.ui()
	if popup:
		popup.present_crisis(str(active["signal"]), str(active.get("threat", "Беги к узлам и закрой их физически.")))
	Sfx.play_ui(&"alarm")
	return true


func apply_fix(solution_id: String) -> bool:
	## Physical interact completed — not a menu "Решить".
	if active.is_empty():
		return false
	if solution_id == "orbit_help":
		return _apply_orbit_help()
	var sid := solution_id
	if sid.is_empty():
		return false
	var done_ids: Array = active.get("done_ids", [])
	if done_ids.has(sid):
		return false
	var found: bool = false
	for s in active.get("open_solutions", []):
		if str(s.get("id", "")) == sid:
			found = true
			break
	if not found:
		return false
	done_ids.append(sid)
	active["done_ids"] = done_ids
	active["fixes_done"] = int(active.get("fixes_done", 0)) + 1
	_remove_hotspot(sid)
	EventBus.toast("Узел закрыт: %s" % sid, &"ok")
	crisis_progress.emit(_payload())
	if int(active["fixes_done"]) >= int(active["fixes_needed"]):
		_succeed()
		return true
	return true


func try_roll(delta: float = 0.0) -> void:
	if not Game.run_started:
		return
	if is_active():
		return
	if _blocked():
		return
	if Time.get_ticks_msec() / 1000.0 < calm_until:
		return
	_roll_cd -= delta
	if _roll_cd > 0.0:
		return
	_roll_cd = 12.0 + randf() * 10.0
	var pressure: float = Game.economy.event_pressure_mult()
	var chance: float = 0.08 * pressure
	var st: String = str(Game.stage_id)
	if st == "stage_1":
		chance *= 0.15
	elif st == "stage_2":
		chance *= 0.45
	if randf() > chance:
		return
	var pool: Array = _eligible_ids()
	if pool.is_empty():
		return
	begin_crisis(str(pool[randi() % pool.size()]))


func _process(delta: float) -> void:
	if not Game.run_started:
		return
	try_roll(delta)
	if active.is_empty():
		return
	active["time_left"] = float(active.get("time_left", 0)) - delta
	if float(active["time_left"]) <= 0.0:
		_fail()


func to_dict() -> Dictionary:
	return {
		"resolved_count": resolved_count,
		"failed_count": failed_count,
		"calm_until": calm_until,
		# Active crises are ephemeral — don't restore mid-crisis after load.
	}


func from_dict(data: Dictionary) -> void:
	resolved_count = int(data.get("resolved_count", 0))
	failed_count = int(data.get("failed_count", 0))
	calm_until = float(data.get("calm_until", 0))
	active.clear()
	_clear_hotspots()


func _succeed() -> void:
	var id: String = str(active.get("id", ""))
	resolved_count += 1
	Game.economy.repair_legend(1.5, &"crisis_ok")
	EventBus.toast("Кризис снят: %s" % id, &"ok")
	calm_until = Time.get_ticks_msec() / 1000.0 + 40.0
	if Game.facility.has_flag("finale_crisis_pending"):
		Game.facility.set_flag("finale_crisis_cleared", true)
		Game.facility.set_flag("finale_crisis_pending", false)
		EventBus.toast("Путь к Алгоритму Любви открыт", &"story")
	var payload := _payload()
	payload["outcome"] = "ok"
	_clear_hotspots()
	active.clear()
	crisis_ended.emit(payload)
	EventBus.bottleneck.emit(&"crisis", "")


func _fail() -> void:
	var id: String = str(active.get("id", ""))
	failed_count += 1
	Game.economy.damage_legend(float(active.get("legend_fail", 5.0)), &"crisis_fail")
	Game.economy.add(&"scandal", float(active.get("scandal_fail", 1.0)), &"crisis_fail")
	EventBus.toast("Кризис провален: %s" % id, &"warn")
	Sfx.play_ui(&"warn")
	var fail_popup := RevealPopup.ui()
	if fail_popup:
		fail_popup.present_warn("Кризис провален", "Легенда и скандал уже пострадали. Следующий шанс скоро.")
	calm_until = Time.get_ticks_msec() / 1000.0 + 25.0
	var payload := _payload()
	payload["outcome"] = "fail"
	_clear_hotspots()
	active.clear()
	crisis_ended.emit(payload)


func _payload() -> Dictionary:
	return active.duplicate(true)


func _def(crisis_id: String) -> Dictionary:
	for c in CATALOG:
		if str(c.get("id", "")) == crisis_id:
			return c
	return {}


func _eligible(def: Dictionary) -> bool:
	var min_st: String = str(def.get("min_stage", "stage_1"))
	if not _stage_at_least(min_st):
		return false
	if bool(def.get("needs_clones", false)) and Game.clones.available_count() + Game.clones.clones.size() <= 0:
		return false
	return true


func _eligible_ids() -> Array:
	var out: Array = []
	for c in CATALOG:
		if _eligible(c):
			out.append(str(c.get("id", "")))
	return out


func _stage_at_least(min_st: String) -> bool:
	var order: Array = ["stage_1", "stage_2", "stage_3", "stage_4", "stage_5", "stage_6"]
	var cur: int = order.find(str(Game.stage_id))
	var need: int = order.find(min_st)
	if cur < 0:
		cur = 0
	if need < 0:
		need = 0
	return cur >= need


func _blocked() -> bool:
	if not Game.dating.active_manual.is_empty():
		return true
	if not Game.events.active.is_empty():
		return true
	var tree: SceneTree = get_tree()
	if tree == null:
		return true
	for g in ["phone_ui", "date_ui", "pause_ui", "clone_accept_ui"]:
		for n in tree.get_nodes_in_group(g):
			if n is CanvasItem and bool(n.visible):
				return true
	return false


func _spawn_hotspots() -> void:
	_clear_hotspots()
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var parent: Node = tree.get_first_node_in_group("world_root")
	if parent == null:
		parent = tree.current_scene
	if parent == null:
		return
	for s in active.get("open_solutions", []):
		var area := Interactable.new()
		area.name = "CrisisHotspot_%s" % str(s.get("id", "x"))
		area.add_to_group("crisis_hotspot")
		area.display_name = str(s.get("label", "Узел"))
		area.action_label = "Устранить"
		area.action_id = &"crisis_fix"
		area.payload = {"solution_id": str(s.get("id", "")), "crisis_id": str(active.get("id", ""))}
		var pos_arr: Array = s.get("pos", [0, 0, 0])
		area.position = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(1.2, 1.8, 1.2)
		cs.shape = shape
		cs.position = Vector3(0, 0.9, 0)
		area.add_child(cs)
		# Visible marker
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.45, 0.45, 0.45)
		mi.mesh = box
		mi.position = Vector3(0, 1.1, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.25, 0.15)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.3, 0.1)
		mi.material_override = mat
		area.add_child(mi)
		parent.add_child(area)
		_hotspots.append(area)


func _remove_hotspot(solution_id: String) -> void:
	var remain: Array = []
	for h in _hotspots:
		if not is_instance_valid(h):
			continue
		var pid := ""
		if h is Interactable:
			pid = str((h as Interactable).payload.get("solution_id", ""))
		if pid == solution_id:
			h.queue_free()
		else:
			remain.append(h)
	_hotspots = remain
	var open_sols: Array = []
	for s in active.get("open_solutions", []):
		if str(s.get("id", "")) != solution_id:
			open_sols.append(s)
	active["open_solutions"] = open_sols


func _clear_hotspots() -> void:
	for h in _hotspots:
		if is_instance_valid(h):
			h.queue_free()
	_hotspots.clear()
	var tree: SceneTree = get_tree()
	if tree:
		for n in tree.get_nodes_in_group("crisis_hotspot"):
			if is_instance_valid(n):
				n.queue_free()


func _maybe_add_orbit_assist() -> void:
	var helper: StringName = Game.girls.orbit_helper_for_crisis(str(active.get("cat", "")))
	if helper == &"":
		return
	active["orbit_helper"] = str(helper)
	var sol := {
		"id": "orbit_help",
		"label": "Помощь: %s" % Game.girls.display_name(helper),
		"hint": "%s закроет один узел за тебя" % Game.girls.display_name(helper),
		"pos": [0.0, 0.05, 1.8],
	}
	var open: Array = active.get("open_solutions", [])
	open.append(sol)
	active["open_solutions"] = open
	# Spawn just this hotspot
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var parent: Node = tree.get_first_node_in_group("world_root")
	if parent == null:
		parent = tree.current_scene
	if parent == null:
		return
	var area := Interactable.new()
	area.name = "CrisisHotspot_orbit_help"
	area.add_to_group("crisis_hotspot")
	area.display_name = str(sol["label"])
	area.action_label = "Попросить помощь"
	area.action_id = &"crisis_fix"
	area.payload = {"solution_id": "orbit_help", "crisis_id": str(active.get("id", ""))}
	area.position = Vector3(0.0, 0.05, 1.8)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2, 1.8, 1.2)
	cs.shape = shape
	cs.position = Vector3(0, 0.9, 0)
	area.add_child(cs)
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.45, 0.45, 0.45)
	mi.mesh = box
	mi.position = Vector3(0, 1.1, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.6, 1.0)
	mi.material_override = mat
	area.add_child(mi)
	parent.add_child(area)
	_hotspots.append(area)


func _apply_orbit_help() -> bool:
	var helper := str(active.get("orbit_helper", ""))
	if helper.is_empty():
		return false
	# Consume one remaining non-orbit solution as the orbit's physical act.
	var pick := ""
	for s in active.get("open_solutions", []):
		var sid := str(s.get("id", ""))
		if sid != "" and sid != "orbit_help" and not active.get("done_ids", []).has(sid):
			pick = sid
			break
	if pick.is_empty():
		return false
	EventBus.toast("%s закрыла узел за тебя" % Game.girls.display_name(StringName(helper)), &"girl")
	_remove_hotspot("orbit_help")
	return apply_fix(pick)
