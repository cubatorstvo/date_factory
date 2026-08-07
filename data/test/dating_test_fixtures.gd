class_name DatingTestFixtures
extends RefCounted
## Rich MODULE 09 dating fixtures registered into ContentDB overrides.


static func register_all(db: Node) -> void:
	db.call("clear_dating_overrides")
	for g in _greetings():
		db.call("register_dating_greeting", g)
	for ev in _events():
		db.call("register_dating_event", ev)
	var pool := DatingEventPoolDefinition.new()
	pool.id = &"date_pool_test_dating"
	var eids: Array[StringName] = []
	for ev2 in _events():
		eids.append(ev2.id)
	pool.event_ids = eids
	db.call("register_dating_pool", pool)
	var thin_pool := DatingEventPoolDefinition.new()
	thin_pool.id = &"date_pool_test_dating_thin"
	thin_pool.event_ids = [&"date_event_test_conv_1"]
	db.call("register_dating_pool", thin_pool)
	db.call("register_dating_farewell", _farewell())
	for girl in _girls():
		db.call("register_girl_definition", girl)


static func default_request(girl_id: StringName = &"girl_test_dating_kind") -> DatingStartRequest:
	var req := DatingStartRequest.new()
	req.girl_id = girl_id
	req.location_id = &"cafe"
	req.greeting_ids = [
		&"dating_greeting_test_simple",
		&"dating_greeting_test_status",
		&"dating_greeting_test_weird",
	]
	req.farewell_id = &"dating_farewell_test"
	req.rng_seed = 42
	return req


static func _greetings() -> Array[DatingGreetingDefinition]:
	var out: Array[DatingGreetingDefinition] = []
	out.append(_greeting(&"dating_greeting_test_simple", "Простое приветствие", [GameTypes.ActionTag.SIMPLICITY]))
	out.append(_greeting(&"dating_greeting_test_status", "Статусное приветствие", [GameTypes.ActionTag.PRESTIGE]))
	out.append(_greeting(&"dating_greeting_test_weird", "Странное приветствие", [GameTypes.ActionTag.ABSURDITY]))
	return out


static func _greeting(id: StringName, label: String, tags: Array) -> DatingGreetingDefinition:
	var g := DatingGreetingDefinition.new()
	g.id = id
	g.label = label
	var typed: Array[GameTypes.ActionTag] = []
	for t in tags:
		typed.append(t as GameTypes.ActionTag)
	g.direct_tags = typed
	g.result_text = label
	return g


static func _action(
	id: StringName,
	label: String,
	charac: GameTypes.PlayerCharacteristic,
	level: int,
	tags: Array,
	opts: Dictionary = {},
) -> DatingActionDefinition:
	var a := DatingActionDefinition.new()
	a.id = id
	a.label = label
	a.characteristic = charac
	a.required_characteristic_level = level
	var typed: Array[GameTypes.ActionTag] = []
	for t in tags:
		typed.append(t as GameTypes.ActionTag)
	a.direct_tags = typed
	a.resolver_id = opts.get("resolver_id", &"direct") as StringName
	a.money_cost = int(opts.get("money_cost", 0))
	a.is_public = bool(opts.get("is_public", false))
	a.is_major_expense = bool(opts.get("is_major_expense", false))
	a.required_perk_id = opts.get("required_perk_id", &"") as StringName
	a.result_text = String(opts.get("result_text", label))
	return a


static func _event(
	id: StringName,
	cat: GameTypes.DatingEventCategory,
	title: String,
	actions: Array[DatingActionDefinition],
	locs: Array[StringName] = [],
) -> DatingEventDefinition:
	var e := DatingEventDefinition.new()
	e.id = id
	e.category = cat
	e.title = title
	e.setup_text = title + " setup"
	e.actions = actions
	e.allowed_location_ids = locs
	return e


static func _events() -> Array[DatingEventDefinition]:
	var out: Array[DatingEventDefinition] = []
	# CONVERSATION x4
	out.append(_event(&"date_event_test_conv_1", GameTypes.DatingEventCategory.CONVERSATION, "Conv Care", [
		_action(&"action_test_care", "Забота", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.CARE]),
		_action(&"action_test_prestige", "Престиж", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.PRESTIGE]),
		_action(&"action_test_neutral_status", "Нейтраль", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.PRESTIGE]),
	]))
	out.append(_event(&"date_event_test_conv_2", GameTypes.DatingEventCategory.CONVERSATION, "Conv Muscle Gate", [
		_action(&"action_test_muscle_gate", "Мышца 3", GameTypes.PlayerCharacteristic.MUSCLE, 3, [GameTypes.ActionTag.DOMINANCE]),
		_action(&"action_test_hold_door", "Дверной проём", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.CARE], {"required_perk_id": PerkIds.MUSCLE_HOLD_DOORWAY}),
	]))
	out.append(_event(&"date_event_test_conv_3", GameTypes.DatingEventCategory.CONVERSATION, "Conv Collision", [
		_action(&"action_test_collision", "Престиж+Абсурд", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.PRESTIGE, GameTypes.ActionTag.ABSURDITY]),
		_action(&"action_test_vulnerability", "Уязвимость", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.VULNERABILITY]),
	]))
	out.append(_event(&"date_event_test_conv_4", GameTypes.DatingEventCategory.CONVERSATION, "Conv Cafe Only", [
		_action(&"action_test_cafe_only", "Только кафе", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.SIMPLICITY]),
	], [&"cafe"]))
	# SPACE x4
	out.append(_event(&"date_event_test_space_1", GameTypes.DatingEventCategory.SPACE_EVENT, "Space Public Conflict", [
		_action(&"action_test_public_conflict", "Публичный конфликт", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.CONFLICT], {"is_public": true}),
		_action(&"action_test_private_care", "Тихая забота", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.CARE], {"is_public": false}),
	]))
	out.append(_event(&"date_event_test_space_2", GameTypes.DatingEventCategory.SPACE_EVENT, "Space Paid", [
		_action(&"action_test_paid_normal", "Обычный расход", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.PRESTIGE], {"money_cost": 20}),
		_action(&"action_test_paid_major", "Крупный расход", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.PRESTIGE], {"money_cost": 20, "is_major_expense": true}),
		_action(&"action_test_buy_problem", "Купить проблему", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.CONTROL], {"required_perk_id": PerkIds.CAPITAL_BUY_PROBLEM, "money_cost": 10}),
	]))
	out.append(_event(&"date_event_test_space_3", GameTypes.DatingEventCategory.SPACE_EVENT, "Space External", [
		_action(&"action_test_external", "Внешний резолвер", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.RISK], {"resolver_id": &"test_external"}),
		_action(&"action_test_external_fail", "Внешний FAIL", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.VULNERABILITY], {"resolver_id": &"test_external_fail", "money_cost": 20}),
	]))
	out.append(_event(&"date_event_test_space_4", GameTypes.DatingEventCategory.SPACE_EVENT, "Space Appearance", [
		_action(&"action_test_appearance_neutral", "Внешность 0", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.PRESTIGE]),
		_action(&"action_test_appearance_gate5", "Внешность 5", GameTypes.PlayerCharacteristic.APPEARANCE, 5, [GameTypes.ActionTag.PRESTIGE]),
		_action(&"action_test_appearance_gate6", "Внешность 6", GameTypes.PlayerCharacteristic.APPEARANCE, 6, [GameTypes.ActionTag.PRESTIGE]),
		_action(&"action_test_appearance_two_tags", "Внешность 2 тега", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.PRESTIGE, GameTypes.ActionTag.CONTROL]),
	]))
	# PROPOSAL x4
	out.append(_event(&"date_event_test_prop_1", GameTypes.DatingEventCategory.GIRL_PROPOSAL, "Prop Risk", [
		_action(&"action_test_risk", "Риск", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.RISK]),
		_action(&"action_test_simplicity", "Простота", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.SIMPLICITY]),
	]))
	out.append(_event(&"date_event_test_prop_2", GameTypes.DatingEventCategory.GIRL_PROPOSAL, "Prop Dominance", [
		_action(&"action_test_dominance", "Доминация", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.DOMINANCE]),
		_action(&"action_test_originality", "Оригинальность", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.ORIGINALITY]),
	]))
	out.append(_event(&"date_event_test_prop_3", GameTypes.DatingEventCategory.GIRL_PROPOSAL, "Prop Spontaneity", [
		_action(&"action_test_spontaneity", "Спонтанность", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.SPONTANEITY]),
		_action(&"action_test_control", "Контроль", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.CONTROL]),
	]))
	out.append(_event(&"date_event_test_prop_4", GameTypes.DatingEventCategory.GIRL_PROPOSAL, "Prop Obsession", [
		_action(&"action_test_obsession", "Одержимость", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.OBSESSION]),
		_action(&"action_test_absurdity", "Абсурд", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.ABSURDITY]),
	]))
	return out


static func _farewell() -> DatingFarewellDefinition:
	var f := DatingFarewellDefinition.new()
	f.id = &"dating_farewell_test"
	f.title = "Прощание"
	f.setup_text = "Время прощаться"
	f.actions = [
		_action(&"action_test_farewell_muscle", "Прощание Мышца", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.CARE]),
		_action(&"action_test_farewell_appearance", "Прощание Внешность", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.PRESTIGE]),
		_action(&"action_test_farewell_capital", "Прощание Капитал", GameTypes.PlayerCharacteristic.CAPITAL, 0, [GameTypes.ActionTag.PRESTIGE]),
		_action(&"action_test_farewell_aura", "Прощание Аура", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.SIMPLICITY]),
		_action(&"action_test_farewell_care", "Прощание Забота+", GameTypes.PlayerCharacteristic.AURA, 0, [GameTypes.ActionTag.CARE, GameTypes.ActionTag.VULNERABILITY]),
		_action(&"action_test_farewell_dislike", "Прощание Доминация", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.DOMINANCE]),
		_action(&"action_test_farewell_public_conflict", "Прощание скандал", GameTypes.PlayerCharacteristic.MUSCLE, 0, [GameTypes.ActionTag.CONFLICT], {"is_public": true}),
		_action(&"action_test_farewell_appearance_neutral", "Прощание внешность 0", GameTypes.PlayerCharacteristic.APPEARANCE, 0, [GameTypes.ActionTag.CONTROL]),
	]
	return f


static func _girls() -> Array[GirlDefinition]:
	var out: Array[GirlDefinition] = []
	out.append(_girl(&"girl_test_dating_kind", GameTypes.PrimaryGirlTrait.KIND, GameTypes.SecondaryGirlTrait.DEMANDING))
	out.append(_girl(&"girl_test_dating_status", GameTypes.PrimaryGirlTrait.STATUS, GameTypes.SecondaryGirlTrait.SCANDALOUS))
	out.append(_girl(&"girl_test_dating_thrill", GameTypes.PrimaryGirlTrait.THRILL_SEEKING, GameTypes.SecondaryGirlTrait.VARIETY_SEEKING))
	out.append(_girl(&"girl_test_dating_strange", GameTypes.PrimaryGirlTrait.STRANGE, GameTypes.SecondaryGirlTrait.CONSISTENT))
	var thin := _girl(&"girl_test_dating_thin", GameTypes.PrimaryGirlTrait.KIND, GameTypes.SecondaryGirlTrait.DEMANDING)
	thin.dating_pool_ids = [&"date_pool_test_dating_thin"]
	out.append(thin)
	return out


static func _girl(
	id: StringName,
	primary: GameTypes.PrimaryGirlTrait,
	secondary: GameTypes.SecondaryGirlTrait,
) -> GirlDefinition:
	var g := GirlDefinition.new()
	g.id = id
	g.display_name = String(id)
	g.primary_trait = primary
	g.secondary_trait = secondary
	g.dating_pool_ids = [&"date_pool_test_dating"]
	g.clue_notes = ["Clue A", "Clue B", "Clue C"]
	return g
