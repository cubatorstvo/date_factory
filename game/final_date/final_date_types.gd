class_name FinalDateTypes
extends RefCounted
## MODULE 21 final date sequence enums, IDs, and event copy.


enum Phase {
	IDLE = 0,
	INTRO = 1,
	EVENT_1 = 2,
	RIVAL_1_DANCE = 3,
	EVENT_2 = 4,
	MOVE_TO_FINAL_TABLE = 5,
	RIVAL_2_SLAP = 6,
	EVENT_3 = 7,
	EVENT_4 = 8,
	FINAL_ASSESSMENT = 9,
	SUCCESS = 10,
	FAILURE = 11,
}


enum FailureReason {
	NONE = 0,
	RIVAL_LOSS = 1,
	CONNECTION = 2,
}


enum EventOptionKind {
	MUSCLE = 0,
	APPEARANCE = 1,
	CAPITAL = 2,
	AURA = 3,
	NEUTRAL = 4,
}


const GIRL_ID: StringName = &"girl_final_target"
const RIVAL_CEREMONIAL_ID: StringName = &"rival_final_ceremonial"
const RIVAL_GRAVITY_ID: StringName = &"rival_final_gravity"
const APPEARANCE_PROFILE_ID: StringName = &"appearance_female_final_target"

const CHAR_LEVEL_REQUIRED: int = 2
const PASS_SCORE: int = 3
const VARIETY_DISTINCT_REQUIRED: int = 3

const MARKER_ATTEMPT_START: StringName = &"final_attempt_start"
const MARKER_TARGET_SIGNAL: StringName = &"final_target_signal_marker"
const MARKER_TARGET_ORBIT: StringName = &"final_target_orbit_marker"
const MARKER_TARGET_TABLE: StringName = &"final_target_table_marker"
const MARKER_RIVAL_CEREMONIAL: StringName = &"final_rival_ceremonial_marker"
const MARKER_RIVAL_GRAVITY: StringName = &"final_rival_gravity_marker"
const MARKER_EVENT_1: StringName = &"final_checkpoint_event_1"
const MARKER_RIVAL_1: StringName = &"final_checkpoint_rival_1"
const MARKER_EVENT_2: StringName = &"final_checkpoint_event_2"
const MARKER_RIVAL_2: StringName = &"final_checkpoint_rival_2"
const MARKER_EVENT_3: StringName = &"final_checkpoint_event_3"
const MARKER_EVENT_4: StringName = &"final_checkpoint_event_4"
const MARKER_WALK_A: StringName = &"final_walk_checkpoint_a"
const MARKER_WALK_B: StringName = &"final_walk_checkpoint_b"
const MARKER_WALK_C: StringName = &"final_walk_checkpoint_c"
const GATE_ZONE_B: StringName = &"final_gate_zone_b"
const GATE_ZONE_C: StringName = &"final_gate_zone_c"

const CHECKPOINT_EVENT_1: StringName = &"event_1"
const CHECKPOINT_RIVAL_1: StringName = &"rival_1"
const CHECKPOINT_EVENT_2: StringName = &"event_2"
const CHECKPOINT_MOVE_TABLE: StringName = &"move_table"
const CHECKPOINT_RIVAL_2: StringName = &"rival_2"
const CHECKPOINT_EVENT_3: StringName = &"event_3"
const CHECKPOINT_EVENT_4: StringName = &"event_4"


static func char_label(kind: EventOptionKind) -> String:
	match kind:
		EventOptionKind.MUSCLE:
			return "Мышца"
		EventOptionKind.APPEARANCE:
			return "Внешность"
		EventOptionKind.CAPITAL:
			return "Капитал"
		EventOptionKind.AURA:
			return "Аура"
		_:
			return "Нейтрально"


static func characteristic_for_kind(kind: EventOptionKind) -> GameTypes.PlayerCharacteristic:
	match kind:
		EventOptionKind.MUSCLE:
			return GameTypes.PlayerCharacteristic.MUSCLE
		EventOptionKind.APPEARANCE:
			return GameTypes.PlayerCharacteristic.APPEARANCE
		EventOptionKind.CAPITAL:
			return GameTypes.PlayerCharacteristic.CAPITAL
		EventOptionKind.AURA:
			return GameTypes.PlayerCharacteristic.AURA
		_:
			return GameTypes.PlayerCharacteristic.MUSCLE


static func event_prompt(event_index: int) -> String:
	match event_index:
		1:
			return "Последняя:\n«Зачем было покрывать целую планету, если ты хотел поговорить со мной?»"
		2:
			return "Последняя:\n«Как вы теперь определяете, кто из вас оригинал?»"
		3:
			return "Последняя:\n«Что Земля отправила с тобой как подтверждение серьёзности намерений?»"
		4:
			return "Последняя:\n«И что ты будешь делать, если после меня действительно никого не останется?»"
		_:
			return ""


static func event_option_text(event_index: int, kind: EventOptionKind) -> String:
	match event_index:
		1:
			match kind:
				EventOptionKind.MUSCLE:
					return "Одного тела оказалось физически недостаточно."
				EventOptionKind.APPEARANCE:
					return "Цель должна была выглядеть завершённой."
				EventOptionKind.CAPITAL:
					return "Локальная модель перестала масштабироваться."
				EventOptionKind.AURA:
					return "Земля закончилась раньше намерения."
				_:
					return "Долго объяснять."
		2:
			match kind:
				EventOptionKind.MUSCLE:
					return "Оригинал первым доказал, что одного тела мало."
				EventOptionKind.APPEARANCE:
					return "По тому, кто выглядит так, будто остальные — его копии."
				EventOptionKind.CAPITAL:
					return "По самой ранней записи в производственном учёте."
				EventOptionKind.AURA:
					return "Оригинал — тот, кому не нужно спрашивать."
				_:
					return "Сейчас уже в основном по привычке."
		3:
			match kind:
				EventOptionKind.MUSCLE:
					return "Официальное подтверждение, что тел теперь достаточно."
				EventOptionKind.APPEARANCE:
					return "Обложку, где я наполовину не поместился в кадр."
				EventOptionKind.CAPITAL:
					return "Смету международного расширения."
				EventOptionKind.AURA:
					return "Право первым ничего не говорить."
				_:
					return "Таможенную печать."
		4:
			match kind:
				EventOptionKind.MUSCLE:
					return "Наконец перестану увеличивать количество тела."
				EventOptionKind.APPEARANCE:
					return "Сделаю одну фотографию без следующего этапа."
				EventOptionKind.CAPITAL:
					return "Закрою проект без бюджета на расширение."
				EventOptionKind.AURA:
					return "Тогда впервые ничего не нужно будет доказывать."
				_:
					return "Проверю ещё раз список."
		_:
			return ""


static func event_result_text(event_index: int, kind: EventOptionKind) -> String:
	if event_index != 1:
		return ""
	match kind:
		EventOptionKind.MUSCLE:
			return "«Понятно. Ты решил проблему буквально.»"
		EventOptionKind.APPEARANCE:
			return "«У вас завершённость действительно очень заметная.»"
		EventOptionKind.CAPITAL:
			return "«Это самый деловой ответ на романтический вопрос, который я слышала.»"
		EventOptionKind.AURA:
			return "«Это уже звучит как причина.»"
		_:
			return "«Я вижу по инфраструктуре.»"
