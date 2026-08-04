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
			_open_shop_menu("gift_shop")
		"take_gift":
			EventBus.toast("Полки с подарками убраны — покупай в городе и носи в инвентаре", &"info")
		"wardrobe":
			_cycle_outfit()
			Game.quests.complete("s1_outfit")
		"prepare_table", "prepare_and_start", "start_date":
			_try_start_home_date()
		"take_food":
			_take_food(str(payload.get("food_id", "simple_meal")))
		"take_drink":
			_take_drink(str(payload.get("drink_id", "water")))
		"place_on_table":
			_place_carried_on_table()
		"upgrade_homeware":
			Game.dating.schedule.upgrade_homeware()
		"answer_doorbell":
			# Doorbell removed — tip player toward the table.
			Game.dating.schedule.answer_doorbell()
		"date_wait_skip":
			wait_for_scheduled_time()
		"date_wait_stand":
			stand_up_from_table()
		"sit_restaurant", "enter_restaurant":
			_try_start_restaurant_date()
		"open_flower_shop":
			_open_shop_menu("flower_shop")
		"open_jewelry_shop":
			_open_shop_menu("jewelry_shop")
		"open_gift_shop":
			_open_shop_menu("gift_shop")
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
		"go_outside":
			_travel_to(&"city", &"HomeEntrance")
			Game.quests.complete("s1_city")
			if not Game.city.outside_tip_shown:
				Game.city.outside_tip_shown = true
				EventBus.toast("Город: найди ресторан Two Hearts по тёплой вывеске.", &"story")
		"go_home", "go_home_from_neighbor":
			_travel_to(&"home", &"PlayerSpawn")
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


static func _travel_to(location_id: StringName, spawn_marker: StringName) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var world := tree.get_first_node_in_group("world_root")
	if world != null and world.has_method("travel_to"):
		world.call("travel_to", location_id, spawn_marker)
		return
	# Fallback if world travel API is unavailable.
	if location_id == &"city":
		_teleport_player(Vector3(-13.0, 0.05, 4.7), &"street")
	else:
		_teleport_player(Vector3(-3.6, 0.05, 3.6), &"apartment")


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
	var mid := func() -> void:
		_finish_teleport(player, pos, zone)
	var unlock := func() -> void:
		if is_instance_valid(player):
			player.set("_date_lock", false)
	if transition == null:
		mid.call()
		unlock.call()
		return
	transition.run_blackout(0.32, mid, 0.42, unlock)


static func _finish_teleport(player: Node3D, pos: Vector3, zone: StringName) -> void:
	if not is_instance_valid(player):
		return
	player.global_position = pos
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	if zone != &"":
		Sfx.set_zone(zone)
	Sfx.play(&"door")


static func _city_buy_gift(gift_id: StringName, discount: float) -> void:
	var def: Dictionary = ContentDB.gift(gift_id)
	var cost := float(def.get("cost", def.get("price", 10))) * discount
	if not Game.economy.try_spend({"money": cost}, &"city_gift"):
		EventBus.toast("Не хватает денег", &"warn")
		return
	Game.inventory._add_gift(gift_id, 1)
	EventBus.toast("Куплено: %s" % str(def.get("name", gift_id)), &"ok")
	Game.quests.complete("s1_money")


static func _open_shop_menu(shop_id: String) -> void:
	var catalog: Dictionary = DatePlaces.shop_catalog().get(shop_id, {})
	var items: Array = catalog.get("items", [])
	if items.is_empty():
		EventBus.toast("Магазин пуст", &"warn")
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		var shop := tree.get_first_node_in_group("shop_ui")
		if shop != null and shop.has_method("open"):
			shop.call("open", shop_id)
			return
	# Fallback without ShopUI: buy first affordable (legacy).
	for raw2 in items:
		if Game.inventory.can_buy_gift(StringName(str(raw2))):
			Game.inventory.buy_gift(StringName(str(raw2)))
			Game.quests.complete("s1_money")
			return
	EventBus.toast("Не хватает денег на товары", &"warn")


static func _take_food(food_id: String) -> void:
	if Game.inventory.carried_item != &"":
		EventBus.toast("Сначала положи то, что в руках, на стол", &"warn")
		return
	Game.inventory.carried_item = StringName("food:%s" % food_id)
	EventBus.carry_changed.emit(Game.inventory.carried_item)
	EventBus.toast("Взял еду — отнеси на стол", &"ok")


static func _take_drink(drink_id: String) -> void:
	if Game.inventory.carried_item != &"":
		EventBus.toast("Сначала положи то, что в руках, на стол", &"warn")
		return
	Game.inventory.carried_item = StringName("drink:%s" % drink_id)
	EventBus.carry_changed.emit(Game.inventory.carried_item)
	EventBus.toast("Взял напиток — отнеси на стол", &"ok")


static func _place_carried_on_table() -> void:
	var carried := str(Game.inventory.carried_item)
	if carried.begins_with("food:"):
		var fid := carried.trim_prefix("food:")
		if Game.dating.schedule.place_food(fid):
			Game.inventory.carried_item = &""
			EventBus.carry_changed.emit(&"")
			Game.quests.complete("s1_prepare")
			if Game.dating.schedule.is_table_ready():
				Game.quests.complete("s1_city")
	elif carried.begins_with("drink:"):
		var did := carried.trim_prefix("drink:")
		if Game.dating.schedule.place_drink(did):
			Game.inventory.carried_item = &""
			EventBus.carry_changed.emit(&"")
			Game.quests.complete("s1_prepare")
			if Game.dating.schedule.is_table_ready():
				Game.quests.complete("s1_city")
	else:
		EventBus.toast("На стол нужна еда или напиток из холодильника", &"warn")


static var _home_start_in_flight: bool = false
static var _home_auto_attempted: bool = false


static func _try_start_home_date() -> void:
	if not Game.dating.has_scheduled_date() or not Game.dating.schedule.is_home():
		EventBus.toast("Сначала назначь домашнее свидание в телефоне", &"warn")
		return
	if Game.inventory.carried_item != &"" and (str(Game.inventory.carried_item).begins_with("food:") or str(Game.inventory.carried_item).begins_with("drink:")):
		_place_carried_on_table()
		return
	if not Game.dating.schedule.is_table_ready():
		EventBus.toast("Положи на стол еду и напиток", &"warn")
		return
	var until: int = Game.dating.schedule.minutes_until_date()
	if until < -DateSchedule.WAIT_LEAVE_MIN:
		Game.dating.schedule.fire_no_show()
		_hide_date_wait_ui()
		return
	_seat_player_at_home_table()
	Game.dating.schedule.player_seated = true
	if Game.dating.schedule.is_table_ready():
		Game.quests.complete("s1_prepare")
		Game.quests.complete("s1_city")
	if until > DateSchedule.ARRIVE_EARLY_MIN:
		_show_date_wait_ui(until)
		EventBus.toast("Ты сел за стол. Жди или промотай время.", &"info")
		return
	# Inside arrive window — start immediately (no doorbell).
	Game.dating.schedule.girl_arrived = true
	_home_auto_attempted = true
	_hide_date_wait_ui()
	_launch_home_date_now()


static func try_auto_start_seated_home_date() -> void:
	## Called from DatingAPI tick when seated + window + girl_arrived.
	if _home_start_in_flight or _home_auto_attempted:
		return
	if not Game.dating.has_scheduled_date() or not Game.dating.schedule.is_home():
		return
	if not Game.dating.schedule.player_seated or not Game.dating.schedule.girl_arrived:
		return
	if not Game.dating.active_manual.is_empty():
		return
	var until: int = Game.dating.schedule.minutes_until_date()
	if until > DateSchedule.ARRIVE_EARLY_MIN or until < -DateSchedule.WAIT_LEAVE_MIN:
		return
	_home_auto_attempted = true
	_hide_date_wait_ui()
	_launch_home_date_now()


static func wait_for_scheduled_time() -> void:
	if not Game.dating.has_scheduled_date() or Game.time == null:
		return
	if not Game.dating.schedule.player_seated:
		EventBus.toast("Сначала сядь за стол", &"info")
		return
	var sched: Dictionary = Game.dating.schedule.scheduled
	Game.time.skip_to_minutes(int(sched.get("day", 1)), int(sched.get("minutes", 0)))
	Game.dating.schedule.update_arrival_flags()
	if Game.dating.schedule.is_home():
		if Game.dating.schedule.should_auto_arrive_home() or Game.dating.schedule.minutes_until_date() <= DateSchedule.ARRIVE_EARLY_MIN:
			Game.dating.schedule.girl_arrived = true
			_home_auto_attempted = true
			_hide_date_wait_ui()
			_launch_home_date_now()
		else:
			_show_date_wait_ui(Game.dating.schedule.minutes_until_date())
	elif Game.dating.schedule.is_restaurant():
		_hide_date_wait_ui()
		var target: String = Game.dating.schedule.target_id()
		var unique: bool = bool(Game.dating.schedule.scheduled.get("unique", ContentDB.girls.has(target)))
		_start_date_with_transition(target, unique, &"restaurant")


static func stand_up_from_table() -> void:
	Game.dating.schedule.player_seated = false
	Game.dating.schedule.girl_arrived = false
	_home_auto_attempted = false
	_home_start_in_flight = false
	_hide_date_wait_ui()
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node3D
	if player != null and is_instance_valid(player):
		player.set("_date_lock", false)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	EventBus.toast("Ты встал из-за стола", &"info")


static func _launch_home_date_now() -> void:
	if _home_start_in_flight:
		return
	if not Game.dating.has_scheduled_date() or not Game.dating.schedule.is_home():
		return
	if not Game.dating.active_manual.is_empty():
		return
	_home_start_in_flight = true
	var target: String = Game.dating.schedule.target_id()
	var unique: bool = bool(Game.dating.schedule.scheduled.get("unique", ContentDB.girls.has(target)))
	_start_date_with_transition(target, unique, &"apartment")
	# Clear flight flag shortly after (transition may fail start).
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		tree.create_timer(0.6).timeout.connect(func() -> void:
			_home_start_in_flight = false
		)
	else:
		_home_start_in_flight = false


static func _seat_player_at_home_table() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var seat_pos := _find_home_hero_seat_global()
	if seat_pos != Vector3.INF:
		player.global_position = seat_pos
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	player.rotation = Vector3(0.0, PI, 0.0)
	player.set("_date_lock", true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


static func _find_home_hero_seat_global() -> Vector3:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return Vector3.INF
	var world := tree.get_first_node_in_group("world_root") as Node
	if world == null and tree.current_scene != null:
		world = tree.current_scene.find_child("ComplexWorld", true, false)
	if world == null:
		return Vector3.INF
	var marker := world.find_child("HeroSeat", true, false) as Node3D
	if marker != null:
		return marker.global_position + Vector3(0.0, 0.05, 0.0)
	var chair := world.find_child("DiningChairSouth", true, false) as Node3D
	if chair != null:
		return chair.global_position + Vector3(0.0, 0.05, 0.0)
	return Vector3.INF


static func _show_date_wait_ui(until: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var hud := tree.get_first_node_in_group("hud") as Node
	if hud == null and tree.current_scene != null:
		hud = tree.current_scene.find_child("HUD", true, false)
	if hud != null and hud.has_method("show_date_wait"):
		hud.call("show_date_wait", until)


static func _hide_date_wait_ui() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var hud := tree.get_first_node_in_group("hud") as Node
	if hud == null and tree.current_scene != null:
		hud = tree.current_scene.find_child("HUD", true, false)
	if hud != null and hud.has_method("hide_date_wait"):
		hud.call("hide_date_wait")


static func _try_start_restaurant_date() -> void:
	if not Game.dating.has_scheduled_date() or not Game.dating.schedule.is_restaurant():
		EventBus.toast("Сначала назначь свидание в ресторане через телефон", &"warn")
		return
	var until: int = Game.dating.schedule.minutes_until_date()
	if until > DateSchedule.ARRIVE_EARLY_MIN and Game.time != null:
		var sched: Dictionary = Game.dating.schedule.scheduled
		EventBus.toast("Ты сел и ждёшь — время бежит к свиданию", &"info")
		Game.time.skip_to_minutes(int(sched.get("day", 1)), int(sched.get("minutes", 0)))
	var target: String = Game.dating.schedule.target_id()
	var unique: bool = bool(Game.dating.schedule.scheduled.get("unique", ContentDB.girls.has(target)))
	Game.dating.schedule.player_seated = true
	_start_date_with_transition(target, unique, &"restaurant")


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
	EventBus.toast("Назначай свидание в телефоне: место и время", &"info")
	return false


static func _start_prepared_or_neighbor() -> void:
	_try_start_restaurant_date()


static func _start_date_with_transition(target: String, unique: bool, zone: StringName = &"restaurant") -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player") as Node3D
	if player:
		player.set("_date_lock", true)
	var transition: TransitionOverlay = null
	if tree.current_scene:
		transition = tree.current_scene.find_child("TransitionOverlay", true, false) as TransitionOverlay
	var begin_date := func() -> void:
		Sfx.set_zone(zone)
		if not Game.dating.start_manual(target, unique):
			Sfx.set_zone(&"street" if zone == &"restaurant" else &"apartment")
			if is_instance_valid(player):
				player.set("_date_lock", false)
		else:
			Game.quests.complete("s1_prepare")
			Game.quests.complete("s1_date")
	# Date stage keeps lock via date_ui_open when start succeeds.
	if transition == null:
		begin_date.call()
		return
	transition.run_blackout(0.38, begin_date, 0.5)


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
