class_name SaveService
extends Node
## JSON save/load in user://

const PATH := "user://save_slot_1.json"


func setup(_game: Node) -> void:
	pass


func has_save() -> bool:
	return FileAccess.file_exists(PATH)


func write_save(data: Dictionary) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f == null:
		EventBus.toast("Не удалось сохранить", &"warn")
		return
	f.store_string(JSON.stringify(data, "\t"))


func read_save() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
