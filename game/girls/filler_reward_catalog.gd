class_name FillerRewardCatalog
extends Resource

const ID_ALINA_IMPROVED_GYM: StringName = &"alina_improved_gym"
const ID_MARINA_FREE_OUTFIT: StringName = &"marina_free_outfit"
const ID_VIKA_BASE_REROLL: StringName = &"vika_base_reroll"
const ID_DASHA_SOFTEN_NEGATIVE: StringName = &"dasha_soften_negative"
const ID_KATYA_INTERIOR_ACCENT: StringName = &"katya_interior_accent"
const ID_LERA_APARTMENT_CLEANING: StringName = &"lera_apartment_cleaning"
const ID_KIRA_EXPRESS_STYLING: StringName = &"kira_express_styling"
const ID_OLYA_OVERTIME: StringName = &"olya_overtime"
const ID_SONYA_RESTAURANT_SECOND_VENUE: StringName = &"sonya_restaurant_second_venue"
const ID_NIKA_BACKUP_OUTFIT: StringName = &"nika_backup_outfit"
const ID_RITA_URGENT_TAXI: StringName = &"rita_urgent_taxi"
const ID_EVA_READ_PEOPLE: StringName = &"eva_read_people"
const ID_CAREER_CONNECTIONS: StringName = &"career_connections"
const ID_CAREER_PROGRESSION_UNLOCK: StringName = &"career_progression_unlock"

const EVA_INITIAL_KNOWN_TAG_BONUS: int = 1
const VIKA_REROLL_COST: int = 25
const KIRA_STYLING_COST: int = 40
const RITA_TAXI_COST: int = 75
const ALINA_GYM_BASE_PRICE: int = 50
const ALINA_GYM_IMPROVED_PRICE: int = 35
const ALINA_GYM_MINUTES: int = 60
const OLYA_OVERTIME_PAY_PERCENT: int = 50
const APARTMENT_CLEAN_MINUTES: int = 30

@export var rewards: Array[FillerRewardDefinition] = []


func get_reward(reward_id: StringName) -> FillerRewardDefinition:
	if reward_id == &"":
		return null
	for reward in rewards:
		if reward != null and reward.id == reward_id:
			return reward
	return null


func get_reward_for_girl(girl_id: StringName) -> FillerRewardDefinition:
	if girl_id == &"":
		return null
	for reward in rewards:
		if reward != null and reward.girl_id == girl_id:
			return reward
	return null


func get_all_rewards() -> Array[FillerRewardDefinition]:
	var result: Array[FillerRewardDefinition] = []
	for reward in rewards:
		if reward != null:
			result.append(reward)
	return result


static func create_seed() -> FillerRewardCatalog:
	var catalog := FillerRewardCatalog.new()
	catalog.rewards.append(_make(
		ID_ALINA_IMPROVED_GYM,
		GirlCatalog.ID_ALINA,
		"Улучшенный тренажёр",
		"Откроется тренажёр за $35 вместо базового за $50.",
		"Алина открыла доступ к своему тренажёру.\nМышца +1: $35 вместо $50."
	))
	catalog.rewards.append(_make(
		ID_MARINA_FREE_OUTFIT,
		GirlCatalog.ID_MARINA,
		"Бесплатный комплект",
		"Марина разрешила выбрать один доступный комплект одежды бесплатно.",
		"Марина разрешила выбрать один доступный комплект одежды бесплатно."
	))
	catalog.rewards.append(_make(
		ID_VIKA_BASE_REROLL,
		GirlCatalog.ID_VIKA,
		"Пересобрать ответы",
		"Раз за свидание можно заплатить $25 и заменить три текущих обычных ответа.",
		"Раз за свидание можно заплатить $25 и заменить три текущих обычных ответа."
	))
	catalog.rewards.append(_make(
		ID_DASHA_SOFTEN_NEGATIVE,
		GirlCatalog.ID_DASHA,
		"Сгладить неловкость",
		"Первый плохой ответ на каждом свидании даёт 0 вместо -1.",
		"Первый плохой ответ на каждом свидании даёт 0 вместо -1."
	))
	catalog.rewards.append(_make(
		ID_KATYA_INTERIOR_ACCENT,
		GirlCatalog.ID_KATYA,
		"Акцент интерьера",
		"Можно назначить один купленный предмет квартиры акцентным. Удачный локальный ход этого предмета даёт +2.",
		"Можно назначить один купленный предмет квартиры акцентным. Первое назначение бесплатно. Удачный локальный ход акцента даёт +2."
	))
	catalog.rewards.append(_make(
		ID_LERA_APARTMENT_CLEANING,
		GirlCatalog.ID_LERA,
		"Клининг квартиры",
		"Перед каждым свиданием дома квартира автоматически подготовлена.",
		"Перед каждым свиданием дома квартира автоматически подготовлена."
	))
	catalog.rewards.append(_make(
		ID_KIRA_EXPRESS_STYLING,
		GirlCatalog.ID_KIRA,
		"Экспресс-стайлинг",
		"Перед свиданием можно заплатить $40 и получить Внешность +1 на всю встречу.",
		"Перед свиданием можно заплатить $40 и получить Внешность +1 на всю встречу."
	))
	catalog.rewards.append(_make(
		ID_OLYA_OVERTIME,
		GirlCatalog.ID_OLYA,
		"Подработка",
		"Каждый день можно отработать вторую смену за 50% обычной выплаты.\nПри первой смене её можно сразу добавить галкой.",
		"Каждый день можно отработать вторую смену за 50% обычной выплаты.\nПри первой смене её можно сразу добавить галкой."
	))
	catalog.rewards.append(_make(
		ID_SONYA_RESTAURANT_SECOND_VENUE,
		GirlCatalog.ID_SONYA,
		"Постоянный столик",
		"В Restaurant источник «Локация» можно использовать два раза за свидание.",
		"В Restaurant источник «Локация» можно использовать два раза за свидание."
	))
	catalog.rewards.append(_make(
		ID_NIKA_BACKUP_OUTFIT,
		GirlCatalog.ID_NIKA,
		"Запасной наряд",
		"Перед свиданием можно взять второй купленный Outfit и один раз переодеться после эпизода.",
		"Перед свиданием можно взять второй купленный Outfit и один раз переодеться после эпизода."
	))
	catalog.rewards.append(_make(
		ID_RITA_URGENT_TAXI,
		GirlCatalog.ID_RITA,
		"Срочное такси",
		"За $75 можно полностью обойти ожидание между свиданиями.",
		"За $75 можно полностью обойти ожидание между свиданиями."
	))
	catalog.rewards.append(_make(
		ID_EVA_READ_PEOPLE,
		GirlCatalog.ID_EVA,
		"Читать людей",
		"При знакомстве сразу открывается на один Tag больше.\nУ уже знакомых незавершённых девушек сейчас откроется ещё один неизвестный Tag.",
		"При знакомстве сразу открывается на один Tag больше.\nУ уже знакомых незавершённых девушек сейчас откроется ещё один неизвестный Tag."
	))
	catalog.rewards.append(_make(
		ID_CAREER_CONNECTIONS,
		GirlCatalog.ID_MINE_BOSS,
		"Карьерные связи",
		"Откроются карьерные связи. Rank 2 и Rank 3 станут доступны при достаточном Capital.",
		"Открыты карьерные связи. Rank 2 и Rank 3 можно взять при достаточном Capital."
	))
	return catalog


static func _make(
	id: StringName,
	girl_id: StringName,
	display_name: String,
	preview_description: String,
	granted_description: String
) -> FillerRewardDefinition:
	var reward := FillerRewardDefinition.new()
	reward.id = id
	reward.girl_id = girl_id
	reward.display_name = display_name
	reward.preview_description = preview_description
	reward.granted_description = granted_description
	return reward
