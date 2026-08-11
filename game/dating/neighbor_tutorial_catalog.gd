class_name NeighborTutorialCatalog
extends RefCounted
## Fixed teaching route layered over ordinary apartment dating content.

const FORCED_EVENT_IDS: Array[StringName] = [
	&"date_event_apartment_laminate",
	&"date_event_apartment_chair",
	&"date_event_apartment_mug_rule",
]

const CORRECT_ACTIONS: Dictionary = {
	&"date_event_apartment_laminate": &"date_action_apartment_laminate_admit",
	&"date_event_apartment_chair": &"date_action_apartment_chair_give",
	&"date_event_apartment_mug_rule": &"date_action_apartment_mug_simple",
	&"dating_farewell_early_common": &"date_action_farewell_walk",
}

const EXPLANATIONS: Dictionary = {
	&"date_action_apartment_laminate_hopes": "Забавно, но ты прячешь неловкость за шуткой. Девушке, которая любит странности, это могло бы понравиться; спокойной важнее честность.",
	&"date_action_apartment_laminate_sample": "Не выдумывай контроль там, где можно честно признаться. Статусная девушка оценит уверенную подачу, но фальшь заметит почти любая.",
	&"date_action_apartment_laminate_decor": "Показная оригинальность работает не на всех. Любительнице необычного — возможно; мне проще услышать правду.",
	&"date_action_apartment_chair_fix": "Импровизация хороша, если она действительно решает проблему. Здесь заботливее сначала дать гостье нормальный стул.",
	&"date_action_apartment_chair_order": "Деньги не заменяют внимания. Статусной девушке покупка может понравиться, но многим важнее то, как ты поступил прямо сейчас.",
	&"date_action_apartment_chair_design": "Не называй неудобство дизайном. Девушка, любящая абсурд, посмеётся, но заботы в этом всё равно нет.",
	&"date_action_apartment_mug_agree": "Соглашаться вслепую — не то же самое, что быть лёгким на подъём. Любительнице риска это ближе, но спокойной нужен понятный выбор.",
	&"date_action_apartment_mug_sort": "Ты превращаешь мелочь в систему контроля. Кому-то порядок нравится, но сейчас достаточно простого решения.",
	&"date_action_apartment_mug_reflection": "Красиво, но слишком театрально. Романтичная оригинальность подходит не каждой девушке и не каждой ситуации.",
	&"date_action_farewell_car": "Не трать деньги, чтобы заменить обычную заботу. Для любительницы статуса машина может быть плюсом, но это не универсальный ответ.",
	&"date_action_farewell_extra_block": "Продлевать встречу без причины — значит не слышать другого человека. Спонтанность хороша только когда она взаимна.",
	&"date_action_farewell_photo_shadow": "Эффектный жест может понравиться творческой девушке, но сначала убедись, что ей комфортно.",
	&"date_action_farewell_absurd_line": "Нелепая реплика запомнится, но не обязательно хорошо. Странной девушке может зайти; спокойной лучше простое тёплое прощание.",
}


static func is_correct(event_id: StringName, action_id: StringName) -> bool:
	return CORRECT_ACTIONS.get(event_id, &"") == action_id


static func explanation_for(action_id: StringName) -> String:
	return str(EXPLANATIONS.get(
		action_id,
		"Подумай, что здесь важнее для самой девушки, и попробуй ещё раз.",
	))
