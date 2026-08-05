class_name SaveService
extends Node
## JSON save/load in user://

const PATH := "user://save_slot_1.json"
## Dedicated QA full-access slot — never used by normal save_game / load_game.
const QA_FULL_ACCESS_PATH := "user://save_slot_qa_full_access.json"


func setup(_game: Node) -> void:
	pass


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func write_save(data: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		EventBus.toast("Не удалось сохранить", &"warn")
		return
	f.store_string(JSON.stringify(data, "\t"))


func read_save() -> Dictionary:
	if not has_save():
		return {}
	var f: FileAccess = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary


func has_qa_full_access_save() -> bool:
	return FileAccess.file_exists(QA_FULL_ACCESS_PATH)


func write_qa_full_access_save(data: Dictionary) -> void:
	var f: FileAccess = FileAccess.open(QA_FULL_ACCESS_PATH, FileAccess.WRITE)
	if f == null:
		EventBus.toast("QA: не удалось сохранить профиль", &"warn")
		return
	f.store_string(JSON.stringify(data, "\t"))


func read_qa_full_access_save() -> Dictionary:
	if not has_qa_full_access_save():
		return {}
	var f: FileAccess = FileAccess.open(QA_FULL_ACCESS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed as Dictionary
