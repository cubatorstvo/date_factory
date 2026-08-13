class_name DatingTypes
extends RefCounted
## Shared dating enums and error codes (MODULE 09).


enum Phase {
	ARRIVAL,
	GREETING,
	CENTRAL_EVENT,
	RESOLVING_ACTION,
	ENCORE_DECISION,
	FAREWELL,
	SECONDARY_EVALUATION,
	FINISHED,
}


enum ExecutionOutcome {
	SUCCESS,
	FAILURE,
}


const ERR_OK: StringName = &"OK"
const ERR_NO_GIRL: StringName = &"NO_GIRL"
const ERR_NO_CONTACT: StringName = &"NO_CONTACT"
const ERR_MISSING_GREETING: StringName = &"MISSING_GREETING"
const ERR_MISSING_FAREWELL: StringName = &"MISSING_FAREWELL"
const ERR_INSUFFICIENT_DATE_CONTENT: StringName = &"INSUFFICIENT_DATE_CONTENT"
const ERR_DATE_ALREADY_ACTIVE: StringName = &"DATE_ALREADY_ACTIVE"
const ERR_INVALID_PHASE: StringName = &"INVALID_PHASE"
const ERR_INVALID_CHOICE: StringName = &"INVALID_CHOICE"
const ERR_INVALID_ACTION_RESULT: StringName = &"INVALID_ACTION_RESULT"
const ERR_ACTION_UNAVAILABLE: StringName = &"ACTION_UNAVAILABLE"
const ERR_SESSION_FINISHED: StringName = &"SESSION_FINISHED"
const ERR_INVALID_HOUR: StringName = &"INVALID_HOUR"
const ERR_INVALID_LOCATION: StringName = &"INVALID_LOCATION"
const ERR_LOCATION_LOCKED: StringName = &"LOCATION_LOCKED"
const ERR_CANNOT_AFFORD: StringName = &"CANNOT_AFFORD"
const ERR_TRAVEL_FAILED: StringName = &"TRAVEL_FAILED"
const ERR_FINAL_TARGET: StringName = &"FINAL_TARGET"
const ERR_INVITE_PENDING: StringName = &"INVITE_PENDING"
const ERR_DATE_TOO_EARLY: StringName = &"DATE_TOO_EARLY"
const ERR_DATE_MISSED: StringName = &"DATE_MISSED"
const ERR_WRONG_VENUE: StringName = &"WRONG_VENUE"
const ERR_NO_PENDING: StringName = &"NO_PENDING"

const SILENCE_GREETING_ID: StringName = &"dating_greeting_silence"


static func user_message(code: StringName) -> String:
	match code:
		ERR_OK:
			return ""
		ERR_NO_GIRL:
			return "Не выбрана девушка."
		ERR_NO_CONTACT:
			return "Сначала получи номер."
		ERR_MISSING_GREETING:
			return "Нет приветствий для свидания."
		ERR_MISSING_FAREWELL:
			return "Нет прощания для свидания."
		ERR_INSUFFICIENT_DATE_CONTENT:
			return "Не хватает событий для этого места."
		ERR_DATE_ALREADY_ACTIVE:
			return "Свидание уже идёт."
		ERR_INVALID_HOUR:
			return "Недопустимое время."
		ERR_INVALID_LOCATION:
			return "Недопустимое место."
		ERR_LOCATION_LOCKED:
			return "Это место ещё закрыто."
		ERR_CANNOT_AFFORD:
			return "Не хватает денег."
		ERR_FINAL_TARGET:
			return "Эту девушку нельзя пригласить."
		ERR_INVITE_PENDING:
			return "Сначала приди на уже назначенное свидание."
		ERR_DATE_TOO_EARLY:
			return "Приходи позже."
		ERR_DATE_MISSED:
			return "Она уже ушла."
		ERR_WRONG_VENUE:
			return "Свидание в другом месте."
		ERR_NO_PENDING:
			return "Нет назначенного свидания."
		&"COOLDOWN":
			return "Свидание сейчас недоступно."
		&"NOT_ROMANCEABLE":
			return "С этой девушкой нельзя начать свидание."
		&"UNKNOWN_GIRL":
			return "Не выбрана девушка."
		_:
			return "Не удалось начать свидание."
