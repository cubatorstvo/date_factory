class_name GameActionLabels
extends RefCounted

const LABEL_WAIT: String = "Подождать"
const LABEL_SKIP_TO_08_00: String = "Пропустить до 08:00"
const LABEL_WORK: String = "Работать"
const LABEL_WORK_ACTION: String = "РАБОТАТЬ"
const LABEL_SPEND: String = "Потратить 50"
const LABEL_BUY: String = "КУПИТЬ"
const LABEL_CAREER_ADVANCEMENT: String = "Добиться повышения"


static func for_id(action_id: StringName) -> String:
	match action_id:
		GameActionCatalog.ID_TEST_WAIT:
			return LABEL_WAIT
		GameActionCatalog.ID_SKIP_TO_08_00:
			return LABEL_SKIP_TO_08_00
		GameActionCatalog.ID_TEST_EARN_MONEY:
			return LABEL_WORK
		WorkService.ID_WORK_BASIC:
			return LABEL_WORK_ACTION
		WorkService.ID_CAREER_ADVANCEMENT:
			return LABEL_CAREER_ADVANCEMENT
		GameActionCatalog.ID_TEST_SPEND_MONEY:
			return LABEL_SPEND
		_:
			return String(action_id)
