class_name TutorialPrompt
extends RefCounted
## Lightweight first-use tutorial prompts (MODULE 22). Runtime-only flags; no autoload.

enum PromptId {
	FIRST_MOVEMENT,
	FIRST_PHONE,
	FIRST_RIVAL,
	FIRST_DATE,
	FIRST_UPGRADE_POINT,
	FIRST_CLONE,
	FIRST_STAGE6,
}

const DISPLAY_SECONDS: float = 5.0
## Evidence-based prompts stay until player proof; never idle-timeout.
const EVIDENCE_BASED: Dictionary = {
	PromptId.FIRST_MOVEMENT: true,
}

const COPY := {
	PromptId.FIRST_MOVEMENT: "WASD — движение\nМышь — обзор\nE — взаимодействие",
	PromptId.FIRST_PHONE: "Телефон хранит сюжет, девушек и текущие системы.",
	PromptId.FIRST_RIVAL: "Самец выбирает или предлагает состязание.\nСравни характеристики до начала.",
	PromptId.FIRST_DATE: "Требования действий видны заранее.\nПосле выбора реакция всегда показывает +1 / 0 / -1.",
	PromptId.FIRST_UPGRADE_POINT: "Каждый прирост «Покоренных сердец» даёт 1 Балл прокачки.",
	PromptId.FIRST_CLONE: "Терминал лаборатории распределяет клонов между Работой и Свиданиями.",
	PromptId.FIRST_STAGE6: "Охват Земли растёт от новых автоматических свиданий.",
}

var _seen: Dictionary = {}
var _queue: Array[int] = []
var _active_id: int = -1


func reset_runtime() -> void:
	reset_seen()


## Clears seen flags and any pending/active prompt (settings "Reset Tutorials").
func reset_seen() -> void:
	_seen.clear()
	_queue.clear()
	_active_id = -1


## JSON-safe PromptId names for settings persistence.
func export_seen_ids() -> Array[String]:
	var out: Array[String] = []
	for key in _seen.keys():
		if not bool(_seen[key]):
			continue
		var id: int = int(key)
		var key_name: Variant = PromptId.find_key(id)
		if key_name == null:
			continue
		out.append(String(key_name))
	out.sort()
	return out


## Restores seen flags from settings. Accepts String names or int ordinals.
func restore_seen_ids(ids: Array) -> void:
	_seen.clear()
	for item in ids:
		var id: int = _parse_seen_id(item)
		if id < 0:
			continue
		_seen[id] = true


func request(prompt_id: PromptId) -> void:
	var id: int = int(prompt_id)
	if bool(_seen.get(id, false)):
		return
	if _active_id == id:
		return
	if _queue.has(id):
		return
	_queue.append(id)


func has_pending() -> bool:
	return not _queue.is_empty()


func is_showing() -> bool:
	return _active_id >= 0


func get_active_id() -> int:
	return _active_id


func is_evidence_based(prompt_id: PromptId) -> bool:
	return bool(EVIDENCE_BASED.get(int(prompt_id), false))


func peek_pending() -> int:
	if _queue.is_empty():
		return -1
	return int(_queue[0])


func begin_next() -> Dictionary:
	if _queue.is_empty():
		return {}
	var id: int = int(_queue.pop_front())
	_active_id = id
	var evidence: bool = bool(EVIDENCE_BASED.get(id, false))
	# Evidence-based prompts stay unseen until player proof completes.
	if not evidence:
		_seen[id] = true
	var seconds: float = 0.0 if evidence else DISPLAY_SECONDS
	return {
		"id": id,
		"text": String(COPY.get(id, "")),
		"seconds": seconds,
		"evidence_based": evidence,
	}


## Hide without completing; re-queue if still unseen (modal/title/pause).
func suspend_active() -> void:
	if _active_id < 0:
		return
	var id: int = _active_id
	_active_id = -1
	if bool(_seen.get(id, false)):
		return
	if _queue.has(id):
		return
	_queue.insert(0, id)


func dismiss_active() -> void:
	_active_id = -1


func complete_active() -> void:
	if _active_id < 0:
		return
	_seen[_active_id] = true
	_active_id = -1


func mark_seen(prompt_id: PromptId) -> void:
	_seen[int(prompt_id)] = true


func has_seen(prompt_id: PromptId) -> bool:
	return bool(_seen.get(int(prompt_id), false))


## Progressive controls copy based on missing player evidence.
func controls_card_text(moved: bool, looked: bool, interacted: bool) -> String:
	var lines: PackedStringArray = PackedStringArray()
	if not moved:
		lines.append("WASD — движение")
	if not looked:
		lines.append("Мышь — обзор")
	if not interacted:
		lines.append("E — взаимодействие")
	if lines.is_empty():
		return ""
	return "\n".join(lines)


func _parse_seen_id(item: Variant) -> int:
	if item is int:
		var as_int: int = int(item)
		if PromptId.find_key(as_int) == null:
			return -1
		return as_int
	if item is float:
		var as_float_int: int = int(item)
		if PromptId.find_key(as_float_int) == null:
			return -1
		return as_float_int
	var text: String = str(item).strip_edges()
	if text.is_empty():
		return -1
	if text.is_valid_int():
		var parsed: int = int(text)
		if PromptId.find_key(parsed) == null:
			return -1
		return parsed
	for i in range(PromptId.size()):
		if String(PromptId.find_key(i)) == text:
			return i
	return -1
