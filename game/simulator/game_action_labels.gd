class_name GameActionLabels
extends RefCounted

const LABEL_WAIT: String = "Подождать"
const LABEL_WORK: String = "Работать"
const LABEL_SPEND: String = "Потратить 50"


static func for_id(action_id: StringName) -> String:
	match action_id:
		GameActionCatalog.ID_TEST_WAIT:
			return LABEL_WAIT
		GameActionCatalog.ID_TEST_EARN_MONEY:
			return LABEL_WORK
		GameActionCatalog.ID_TEST_SPEND_MONEY:
			return LABEL_SPEND
		_:
			return String(action_id)
