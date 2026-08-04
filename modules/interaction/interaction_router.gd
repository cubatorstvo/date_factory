class_name InteractionRouter
extends RefCounted
## Central routing from world interactables to module APIs.


static func route(action_id: StringName, source: Node, _by: Node, payload: Dictionary = {}) -> void:
	if not Game.quests.can_do(action_id):
		EventBus.toast(Game.quests.gate_hint(action_id), &"warn")
		return
	match str(action_id):
		"job":
			Game.economy.do_job()
			Game.quests.complete("s1_money")
		"buy_gift":
			var gid := StringName(str(payload.get("gift_id", "flower")))
			if Game.inventory.buy_gift(gid):
				Game.quests.complete("s1_money")
		"take_gift":
			var gid2 := StringName(str(payload.get("gift_id", "flower")))
			if Game.inventory.gift_count(gid2) <= 0:
				EventBus.toast("Сначала купи подарок на полке", &"warn")
				return
			if Game.inventory.take_gift(gid2):
				Game.quests.complete("s1_prepare")
				EventBus.toast("Подарок в руках — подойди к столу", &"info")
		"wardrobe":
			_cycle_outfit()
			Game.quests.complete("s1_outfit")
		"prepare_table", "prepare_and_start", "start_date":
			if not _prepare_default_date():
				return
			Game.quests.complete("s1_prepare")
			EventBus.toast("Столик забронирован. Выйди на улицу и найди розовую вывеску Two Hearts.", &"story")
			EventBus.notify.emit("DATE_ROUTE_READY", &"objective")
		"phone":
			EventBus.notify.emit("PHONE_TOGGLE", &"ui")
		"expand":
			if Game.facility.buy_stage_expansion():
				Game.quests.complete("s1_expand")
				Game.quests.complete("s2_expand")
				Game.quests.complete("s3_lab")
				Game.quests.complete("s4_factory")
				Game.quests.complete("s5_orbit")
		"hire":
			var role := StringName(str(payload.get("role_id", "messenger")))
			if Game.staff.hire(role):
				Game.quests.complete("s2_hire")
				if str(role) == "pr":
					Game.quests.complete("s5_pr")
		"create_clone":
			Game.clones.begin_acceptance()
		"buy_upgrade":
			var uid := StringName(str(payload.get("upgrade_id", "")))
			if uid != &"":
				Game.upgrades.buy(uid)
				if str(uid) == "venue_conveyor":
					Game.quests.complete("s5_conveyor")
		"open_venue_upgrade":
			var vid := StringName(str(payload.get("venue_id", "cheap_cafe")))
			for u in Game.upgrades.available():
				var fx: Dictionary = u.get("effects", {})
				if str(fx.get("unlock_venue", "")) == str(vid):
					Game.upgrades.buy(StringName(str(u.get("id", ""))))
					Game.quests.complete("s2_venues")
					return
			Game.facility.unlock_venue(vid)
			Game.quests.complete("s2_venues")
		"visit_harem":
			var gid3 := StringName(str(payload.get("girl_id", "neighbor")))
			Game.girls.visit_harem(gid3)
			var lines: Array = ContentDB.girl(gid3).get("lines", ["..."])
			var lvl := int(Game.girls.get_entry(gid3).get("relation_level", 0))
			EventBus.toast(Game.girls.display_name(gid3) + ": " + str(lines[mini(lines.size() - 1, lvl)]), &"girl")
			Game.quests.complete("s4_harem")
		"fix_device":
			Game.economy.add(&"scandal", -1.0, &"fix")
			EventBus.toast("Устройство перезапущено", &"info")
		"crisis_fix":
			if Game.crises != null:
				Game.crises.apply_fix(str(payload.get("solution_id", "")))
		"finale_station":
			_finale_station(str(payload.get("station", "")))
		"start_finale":
			_start_finale()
		"toggle_auto":
			Game.dating.raise_automation(mini(3, Game.dating.automation_level + 1))
			EventBus.toast("Автоматизация уровень %d" % Game.dating.automation_level, &"info")
			Game.quests.complete("s4_parallel")
		"talk_girl":
			_talk_girl(str(payload.get("girl_id", "")), source)
		"enter_restaurant":
			if Game.dating.prepared.is_empty():
				EventBus.toast("Сначала подготовь свидание дома.", &"warn")
				return
			_start_prepared_or_neighbor()
		"go_outside":
			_teleport_player(Vector3(-47.0, 0.05, 4.7), &"street")
			Game.quests.complete("s1_city")
			if not Game.city.outside_tip_shown:
				Game.city.outside_tip_shown = true
				EventBus.toast("Город: ищи девушек. Q — телефон. Жёлтый ! — цель обучения.", &"story")
		"go_home", "go_home_from_neighbor":
			_teleport_player(Vector3(0.0, 0.05, 2.5), &"apartment")
		"go_neighbor":
			_teleport_player(Vector3(0.0, 0.05, -10.0 + 2.5), &"apartment")
			EventBus.toast("Квартира соседки. Можно заговорить.", &"info")
		"neighbor_look":
			EventBus.toast("Уютно. Пахнет ламинатом и надеждами.", &"info")
		"city_rest":
			var bonus := float(payload.get("bonus", 1.0))
			Game.economy.add(&"attention", 0.8 * bonus, &"rest")
			EventBus.toast("Ты перевёл дух. Внимание восстанавливается.", &"ok")
		"city_buy_gift":
			_city_buy_gift(StringName(str(payload.get("gift_id", "flower"))), float(payload.get("discount", 1.0)))
		"city_cafe_job":
			Game.economy.do_job()
			Game.economy.add(&"money", 5.0, &"cafe_tip")
			EventBus.toast("Онлайн-халтура: деньги капают.", &"money")
		"city_cafe_scroll":
			Game.economy.add(&"popularity", 0.4, &"scroll")
			Game.economy.add(&"attention", -0.2, &"scroll")
			EventBus.toast("Скролл ради популярности. Глаза горят.", &"info")
		"city_coffee":
			if Game.economy.try_spend({"money": 8.0}, &"coffee"):
				Game.economy.add(&"attention", 1.0, &"coffee")
				EventBus.toast("Латте корпоративной любви.", &"ok")
			else:
				EventBus.toast("Даже на кофе нет.", &"warn")
		"city_workout":
			Game.economy.add(&"attention", 0.5, &"workout")
			Game.economy.add(&"popularity", 0.2, &"workout")
			EventBus.toast("Пот и микропопулярность.", &"ok")
		"city_gym_pass":
			if Game.economy.try_spend({"money": 40.0}, &"gym"):
				Game.economy.max_attention += 0.5
				EventBus.toast("Абонемент: потолок внимания вырос.", &"ok")
			else:
				EventBus.toast("Зал не для бедных... пока.", &"warn")
		"city_park_fun":
			Game.economy.add(&"popularity", 0.3, &"ducks")
			EventBus.toast("Утки одобряют. +⭐", &"ok")
		"city_bar_drink":
			if Game.economy.try_spend({"money": 15.0}, &"bar"):
				Game.economy.add(&"scandal", 0.8, &"bar")
				Game.economy.add(&"popularity", 0.6, &"bar")
				EventBus.toast("Шот и репутация с привкусом скандала.", &"warn")
			else:
				EventBus.toast("Бармен смотрит на тебя как на пустой кошелёк.", &"warn")
		"city_karaoke":
			Game.economy.add(&"popularity", 1.0, &"karaoke")
			Game.economy.add(&"scandal", 0.5, &"karaoke")
			EventBus.toast("Ты спел. Город запомнил. К сожалению.", &"info")
		"city_bus_info":
			EventBus.toast("Маршруты: Дом ↔ Площадь ↔ Конец света (скоро).", &"info")
		_:
			EventBus.toast("Действие: %s" % str(action_id), &"info")


static func _talk_girl(girl_id: String, source: Node) -> void:
	if girl_id.is_empty():
		return
	var result: Dictionary = Game.city.talk(girl_id)
	var line := str(result.get("line", "..."))
	var name := str(Game.city.get_profile(girl_id).get("name", girl_id))
	if girl_id == "neighbor":
		name = Game.girls.display_name(&"neighbor")
	EventBus.toast("%s: %s" % [name, line], &"girl" if bool(result.get("ok", false)) else &"warn")
	# Face emotion on girl visual if present.
	for c in source.get_children():
		if c.has_method("set_emotion"):
			c.call("set_emotion", &"happy" if bool(result.get("ok", false)) else &"reject")
			break


static func _teleport_player(pos: Vector3, zone: StringName = &"") -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node3D
	if player == null:
		return
	player.set("_date_lock", true)
	var transition: TransitionOverlay = null
	if tree.current_scene:
		transition = tree.current_scene.find_child("TransitionOverlay", true, false) as TransitionOverlay
	if transition:
		await transition.fade_out(0.32)
	player.global_position = pos
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	if zone != &"":
		Sfx.set_zone(zone)
	Sfx.play(&"door")
	await tree.process_frame
	if transition:
		await transition.fade_in(0.42)
	player.set("_date_lock", false)


static func _city_buy_gift(gift_id: StringName, discount: float) -> void:
	var def: Dictionary = ContentDB.gift(gift_id)
	var cost := float(def.get("cost", 10)) * discount
	if not Game.economy.try_spend({"money": cost}, &"city_gift"):
		EventBus.toast("Не хватает денег", &"warn")
		return
	Game.inventory._add_gift(gift_id, 1)
	EventBus.toast("Куплено: %s" % str(def.get("name", gift_id)), &"ok")
	Game.quests.complete("s1_money")


static func _cycle_outfit() -> void:
	ContentDB.ensure_loaded()
	if not Game.inventory.own_outfit(&"cheap_formal"):
		Game.inventory.buy_outfit(&"cheap_formal")
	var opts: Array = Game.inventory.owned_outfits
	if opts.is_empty():
		return
	var idx: int = opts.find(Game.inventory.equipped_outfit)
	idx = (idx + 1) % opts.size()
	Game.inventory.equip_outfit(opts[idx])


static func _prepare_default_date() -> bool:
	Game.girls.refresh_candidates(false)
	var target := "neighbor"
	for c in Game.girls.candidates:
		if str(c.get("kind", "")) == "unique":
			target = str(c.get("id", "neighbor"))
			break
	var gift_id := &"flower"
	if Game.inventory.carried_item != &"":
		gift_id = Game.inventory.carried_item
	elif Game.inventory.gift_count(&"flower") > 0:
		gift_id = &"flower"
	elif Game.inventory.total_gifts() > 0:
		gift_id = StringName(str(Game.inventory.gift_counts.keys()[0]))
	else:
		EventBus.toast("Нужен подарок: купи и возьми с полки", &"warn")
		return false
	var venue := &"kitchen_table"
	Game.dating.set_prep(target, gift_id, venue, Game.inventory.equipped_outfit)
	EventBus.toast("Стол готов — свидание: %s" % Game.girls.display_name(StringName(target)), &"info")
	return true


static func _start_prepared_or_neighbor() -> void:
	var target := "neighbor"
	if not Game.dating.prepared.has("neighbor"):
		for k in Game.dating.prepared.keys():
			target = str(k)
			break
	if not Game.dating.prepared.has(target):
		EventBus.toast("Сначала подготовь стол", &"warn")
		return
	var unique: bool = ContentDB.girls.has(target)
	_start_date_with_transition(target, unique)


static func _start_date_with_transition(target: String, unique: bool) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node3D
	if player:
		player.set("_date_lock", true)
	var transition: TransitionOverlay = null
	if tree.current_scene:
		transition = tree.current_scene.find_child("TransitionOverlay", true, false) as TransitionOverlay
	if transition:
		await transition.fade_out(0.38)
	Sfx.set_zone(&"restaurant")
	if not Game.dating.start_manual(target, unique):
		Sfx.set_zone(&"street")
		if transition:
			await transition.fade_in(0.3)
		if player:
			player.set("_date_lock", false)
		return
	await tree.process_frame
	if transition:
		await transition.fade_in(0.5)


static func _finale_station(station: String) -> void:
	match station:
		"messages":
			EventBus.toast("Станция переписки активирована", &"story")
		"outfit":
			if not Game.inventory.own_outfit(&"final_absurd"):
				Game.inventory.owned_outfits.append(&"final_absurd")
			Game.inventory.equip_outfit(&"final_absurd")
			EventBus.toast("Финальный образ готов", &"story")
		"gift":
			if Game.inventory.gift_count(&"romance_cert") <= 0:
				Game.inventory._add_gift(&"romance_cert", 1)
			EventBus.toast("Абсурдный подарок произведён", &"story")
		"delivery":
			EventBus.toast("Доставка на орбиту подтверждена", &"story")
		"parallel":
			Game.dating.raise_automation(3)
			EventBus.toast("Параллельные линии в норме", &"story")
		"scandal":
			Game.economy.set_value(&"scandal", maxf(0.0, Game.economy.get_value(&"scandal") - 5.0))
			EventBus.toast("Скандал стабилизирован", &"story")
		"core":
			EventBus.toast("Ядро мегамашины гудит", &"story")
			Game.facility.set_flag("finale_core_ready", true)
		_:
			EventBus.toast("Станция %s" % station, &"story")
	Game.quests.complete("s6_mega")


static func _start_finale() -> void:
	if not Game.girls.unlock_algorithm_if_ready():
		EventBus.toast("Финал ещё не готов: нужны все девушки, популярность, легенда и мегамашина", &"warn")
		return
	if not Game.facility.has_flag("finale_core_ready"):
		EventBus.toast("Сначала активируй ядро мегамашины", &"warn")
		return
	# Pre-finale spatial crisis wave (not text-only).
	if not Game.facility.has_flag("finale_crisis_cleared"):
		if Game.crises != null and not Game.crises.is_active():
			Game.facility.set_flag("finale_crisis_pending", true)
			if Game.crises.begin_crisis("memory_desync") or Game.crises.begin_crisis("lights_out"):
				EventBus.toast("Перед Алгоритмом — последний пространственный сбой. Устрани ногами.", &"warn")
				return
			# If crisis couldn't start (blocked), allow proceed.
			Game.facility.set_flag("finale_crisis_cleared", true)
		elif Game.crises != null and Game.crises.is_active():
			EventBus.toast("Сначала сними активный кризис", &"warn")
			return
	if not Game.inventory.own_outfit(&"final_absurd"):
		Game.inventory.owned_outfits.append(&"final_absurd")
	Game.inventory.equip_outfit(&"final_absurd")
	if Game.inventory.gift_count(&"romance_cert") <= 0:
		Game.inventory._add_gift(&"romance_cert", 1)
	Game.dating.set_prep("algorithm", &"romance_cert", &"orbital_hall", &"final_absurd")
	if Game.dating.start_manual("algorithm", true):
		Game.quests.complete("s6_finale")
		Game.facility.set_flag("finale_date_started", true)
