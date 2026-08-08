class_name DatingOverloadTypes
extends RefCounted
## Shared Dating Overload enums / constants (MODULE 16).


enum DatingDemandSlot {
	EARLY_EVENING = 0,
	LATE_EVENING = 1,
}


enum DatingDemandStatus {
	WAITING = 0,
	OVERDUE = 1,
	FULFILLED = 2,
}


enum PersonalDateAvailability {
	AVAILABLE = 0,
	BODY_CAPACITY_USED = 1,
}


const AVAIL_BODY_CAPACITY_USED: StringName = &"BODY_CAPACITY_USED"

const PERSONAL_DATE_CAPACITY_PER_DAY: int = 1
const BASE_NEW_REQUESTS_PER_DAY: int = 2
const FIRST_WAVE_COUNT: int = 3
const BOOST_WAVE_COUNT: int = 3

const FEED_BOOST_ATTENTION: int = 5

const RECOGNITION_MIN_DAYS: int = 2
const RECOGNITION_MIN_GENERATED: int = 7
const RECOGNITION_MIN_BACKLOG: int = 4
const RECOGNITION_MIN_PERSONAL_DATES: int = 1

const BODY_CAPACITY_USED_MESSAGE: String = "Сегодня ты уже физически был на одном свидании."
const DATE_VENUE_CAPACITY_MESSAGE: String = "Сегодня больше физически не успеть."

const REALIZATION_LINE_1: String = "Проблема не в графике."
const REALIZATION_LINE_2: String = "Проблема в количестве меня."
const REALIZATION_LINE_3: String = "Нужен способ физически находиться в нескольких местах одновременно."


static func slot_display_time(slot: DatingDemandSlot) -> String:
	match slot:
		DatingDemandSlot.EARLY_EVENING:
			return "19:00"
		DatingDemandSlot.LATE_EVENING:
			return "20:00"
	return ""
