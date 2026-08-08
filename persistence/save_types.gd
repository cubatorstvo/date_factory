class_name SaveTypes
extends RefCounted
## Shared enums for SaveSystem (MODULE 24).


enum Slot {
	MANUAL_1 = 1,
	MANUAL_2 = 2,
	MANUAL_3 = 3,
	AUTOSAVE = 0,
}


enum ErrorCode {
	OK = 0,
	BUSY = 1,
	UNSAFE_STATE = 2,
	FILE_NOT_FOUND = 3,
	READ_FAILED = 4,
	WRITE_FAILED = 5,
	JSON_INVALID = 6,
	UNSUPPORTED_SCHEMA = 7,
	VALIDATION_FAILED = 8,
	RESTORE_FAILED = 9,
}


const SAVE_SCHEMA_VERSION: int = 1
const SAVES_DIR: String = "user://saves"
const SETTINGS_PATH: String = "user://settings.cfg"
const AUTOSAVE_DEBOUNCE_SEC: float = 0.75
const FINAL_TARGET_GIRL_ID: StringName = &"girl_final_target"


static func slot_file_name(slot: Slot) -> String:
	match slot:
		Slot.MANUAL_1:
			return "slot_1.json"
		Slot.MANUAL_2:
			return "slot_2.json"
		Slot.MANUAL_3:
			return "slot_3.json"
		Slot.AUTOSAVE:
			return "autosave.json"
	return ""


static func slot_path(slot: Slot) -> String:
	return "%s/%s" % [SAVES_DIR, slot_file_name(slot)]


static func backup_path(slot: Slot) -> String:
	match slot:
		Slot.MANUAL_1:
			return "%s/slot_1.bak.json" % SAVES_DIR
		Slot.MANUAL_2:
			return "%s/slot_2.bak.json" % SAVES_DIR
		Slot.MANUAL_3:
			return "%s/slot_3.bak.json" % SAVES_DIR
		Slot.AUTOSAVE:
			return "%s/autosave.bak.json" % SAVES_DIR
	return ""


static func is_manual_slot(slot: Slot) -> bool:
	return slot == Slot.MANUAL_1 or slot == Slot.MANUAL_2 or slot == Slot.MANUAL_3


static func all_slots() -> Array[Slot]:
	var out: Array[Slot] = [Slot.MANUAL_1, Slot.MANUAL_2, Slot.MANUAL_3, Slot.AUTOSAVE]
	return out
